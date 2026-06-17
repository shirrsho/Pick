import 'package:flutter/material.dart';
import '../data/chord_library.dart';
import '../models/chord.dart';
import '../widgets/chord_diagram.dart';
import 'play_screen.dart';

/// Shows a chord's fretboard diagram in a popup (used on long-press).
void showChordDiagramPopup(BuildContext context, Chord chord) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chord.name,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: ChordDiagram(chord: chord, color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

enum SelectionMode { all, scale, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SelectionMode _mode = SelectionMode.all;
  String _scale = ChordLibrary.scaleNames.first;
  final Set<String> _scaleDeselected = {}; // chords excluded from current scale
  final Set<String> _customSelected = {};
  int _delay = 2;

  // The custom picker is built once and kept alive (via Offstage), so toggling
  // chips only rebuilds the picker itself — not this whole screen.
  late final Widget _customPicker = _CustomChordPicker(
    selection: _customSelected,
    onChanged: () => setState(() {}), // refresh the play-bar count only
  );

  /// The chords that will actually be practiced for the current mode.
  List<Chord> get _activeChords {
    switch (_mode) {
      case SelectionMode.all:
        return ChordLibrary.all;
      case SelectionMode.scale:
        return ChordLibrary.chordsForScale(_scale)
            .where((c) => !_scaleDeselected.contains(c.name))
            .toList();
      case SelectionMode.custom:
        return _customSelected
            .map((n) => ChordLibrary.byName(n))
            .whereType<Chord>()
            .toList();
    }
  }

  void _startPractice() {
    final chords = _activeChords;
    if (chords.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 chords to practice.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayScreen(chords: chords, delaySeconds: _delay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _activeChords.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoopChords'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _sectionTitle('1. Choose your chords'),
          const SizedBox(height: 8),
          _modeSelector(),
          const SizedBox(height: 16),
          // All three bodies stay in the tree; only the active one is laid out.
          // Cached widget instances let the framework skip rebuilding them.
          Offstage(offstage: _mode != SelectionMode.all, child: _allBody),
          Offstage(
            offstage: _mode != SelectionMode.scale,
            child: _ScalePicker(
              scale: _scale,
              deselected: _scaleDeselected,
              onScaleChanged: (s) => setState(() {
                _scale = s;
                _scaleDeselected.clear(); // new key starts fully selected
              }),
              onToggle: (name, selected) => setState(() {
                if (selected) {
                  _scaleDeselected.remove(name);
                } else {
                  _scaleDeselected.add(name);
                }
              }),
            ),
          ),
          Offstage(offstage: _mode != SelectionMode.custom, child: _customPicker),
          const SizedBox(height: 24),
          _sectionTitle('2. Delay between chords'),
          const SizedBox(height: 8),
          _delaySelector(),
        ],
      ),
      bottomNavigationBar: _playBar(count),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      );

  Widget _modeSelector() {
    return SegmentedButton<SelectionMode>(
      segments: const [
        ButtonSegment(value: SelectionMode.all, label: Text('All'), icon: Icon(Icons.grid_view)),
        ButtonSegment(value: SelectionMode.scale, label: Text('Scale'), icon: Icon(Icons.piano)),
        ButtonSegment(value: SelectionMode.custom, label: Text('Custom'), icon: Icon(Icons.tune)),
      ],
      selected: {_mode},
      onSelectionChanged: (s) => setState(() => _mode = s.first),
    );
  }

  // Static informational card for "All" mode — built once and reused.
  late final Widget _allBody = Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('All chords',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'Practice the full set of ${ChordLibrary.all.length} chords — majors, '
            'minors, and common 7th chords, shuffled randomly.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );

  Widget _delaySelector() {
    return Wrap(
      spacing: 10,
      children: [1, 2, 3, 4, 5].map((d) {
        return ChoiceChip(
          label: Text('${d}s'),
          selected: _delay == d,
          onSelected: (_) => setState(() => _delay = d),
        );
      }).toList(),
    );
  }

  Widget _playBar(int count) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: count >= 2 ? _startPractice : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.play_arrow),
          label: Text('Play  ($count chords • ${_delay}s)'),
        ),
      ),
    );
  }
}

/// Scale picker: a key dropdown plus selectable chips for that scale's chords,
/// so individual chords can be deselected before practising.
class _ScalePicker extends StatelessWidget {
  final String scale;
  final Set<String> deselected;
  final ValueChanged<String> onScaleChanged;
  final void Function(String name, bool selected) onToggle;

  const _ScalePicker({
    required this.scale,
    required this.deselected,
    required this.onScaleChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final chords = ChordLibrary.chordsForScale(scale);
    final selectedCount = chords.where((c) => !deselected.contains(c.name)).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: scale,
              decoration: const InputDecoration(
                labelText: 'Key / Scale',
                border: OutlineInputBorder(),
              ),
              items: ChordLibrary.scaleNames
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => onScaleChanged(v ?? scale),
            ),
            const SizedBox(height: 12),
            Text('$selectedCount of ${chords.length} selected',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chords.map((c) {
                return GestureDetector(
                  onLongPress: () => showChordDiagramPopup(context, c),
                  child: FilterChip(
                    label: Text(c.name),
                    selected: !deselected.contains(c.name),
                    onSelected: (v) => onToggle(c.name, v),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom chord picker. Owns its own rebuilds so toggling a chip does not
/// rebuild the whole home screen. Mutates the shared [selection] set in place
/// and notifies the parent (for the play-bar count) via [onChanged].
class _CustomChordPicker extends StatefulWidget {
  final Set<String> selection;
  final VoidCallback onChanged;

  const _CustomChordPicker({required this.selection, required this.onChanged});

  @override
  State<_CustomChordPicker> createState() => _CustomChordPickerState();
}

class _CustomChordPickerState extends State<_CustomChordPicker> {
  void _toggle(String name, bool selected) {
    setState(() {
      if (selected) {
        widget.selection.add(name);
      } else {
        widget.selection.remove(name);
      }
    });
    widget.onChanged();
  }

  void _clear() {
    setState(widget.selection.clear);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${widget.selection.length} selected',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            const Spacer(),
            TextButton(
              onPressed: widget.selection.isEmpty ? null : _clear,
              child: const Text('Clear'),
            ),
          ],
        ),
        ...ChordLibrary.grouped.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((c) {
                    return GestureDetector(
                      onLongPress: () => showChordDiagramPopup(context, c),
                      child: FilterChip(
                        label: Text(c.name),
                        selected: widget.selection.contains(c.name),
                        onSelected: (v) => _toggle(c.name, v),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
