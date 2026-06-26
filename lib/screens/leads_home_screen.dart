import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/scale_library.dart';
import '../widgets/fretboard_view.dart';
import 'scale_play_screen.dart';
import 'theory_screen.dart';

enum LeadStyle { reference, drill, solo }

class LeadsHomeScreen extends StatefulWidget {
  const LeadsHomeScreen({super.key});

  @override
  State<LeadsHomeScreen> createState() => _LeadsHomeScreenState();
}

class _LeadsHomeScreenState extends State<LeadsHomeScreen> {
  static const int _boxFrets = 5;

  LeadStyle _style = LeadStyle.drill;
  ScaleType _scale = ScaleLibrary.scales[2]; // Minor pentatonic
  int _rootPc = 9; // A
  int _fromFret = 5; // A minor pentatonic box 1
  NoteOrder _order = NoteOrder.ascending;

  // Timing (shared style with the chords screen).
  int _delay = 2;
  int _sessionMinutes = 0;
  bool _tempoMode = false;
  bool _beatFlash = true;
  int _bpm = 90;
  int _beatsPerBar = 4;

  Duration? get _sessionLimit =>
      _sessionMinutes == 0 ? null : Duration(minutes: _sessionMinutes);

  void _setRoot(int pc) {
    setState(() {
      _rootPc = pc;
      _fromFret = ScaleLibrary.defaultBox(pc); // jump to that key's box
    });
  }

  void _play() {
    if (_style == LeadStyle.reference) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ReferenceScreen(scale: _scale, rootPc: _rootPc),
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScalePlayScreen(
        playMode: _style == LeadStyle.solo ? ScalePlayMode.solo : ScalePlayMode.drill,
        scale: _scale,
        rootPc: _rootPc,
        fromFret: _fromFret,
        fretCount: _boxFrets,
        order: _order,
        delaySeconds: _delay,
        sessionLimit: _sessionLimit,
        tempoMode: _tempoMode,
        bpm: _bpm,
        beatsPerBar: _beatsPerBar,
        beatFlash: _beatFlash,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reference = _style == LeadStyle.reference;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'Music theory',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TheoryScreen()),
            ),
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Settings',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _settingsDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _title('Practice style'),
          const SizedBox(height: 8),
          SegmentedButton<LeadStyle>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: LeadStyle.reference, label: Text('Reference')),
              ButtonSegment(value: LeadStyle.drill, label: Text('Drill')),
              ButtonSegment(value: LeadStyle.solo, label: Text('Solo')),
            ],
            selected: {_style},
            onSelectionChanged: (s) => setState(() => _style = s.first),
          ),
          const SizedBox(height: 20),
          _title('Scale'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ScaleLibrary.scales.map((s) {
              return ChoiceChip(
                showCheckmark: false,
                label: Text(s.shortName),
                selected: _scale == s,
                onSelected: (_) => setState(() => _scale = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _rootPc,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (int i = 0; i < ScaleLibrary.roots.length; i++)
                      DropdownMenuItem(value: i, child: Text(ScaleLibrary.roots[i])),
                  ],
                  onChanged: (v) => _setRoot(v ?? _rootPc),
                ),
              ),
              if (!reference) ...[
                const SizedBox(width: 12),
                _positionStepper(scheme),
              ],
            ],
          ),
          if (!reference && _style == LeadStyle.drill) ...[
            const SizedBox(height: 16),
            _title('Note order'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                (NoteOrder.ascending, 'Ascending'),
                (NoteOrder.descending, 'Descending'),
                (NoteOrder.random, 'Random'),
              ].map((e) {
                return ChoiceChip(
                  showCheckmark: false,
                  label: Text(e.$2),
                  selected: _order == e.$1,
                  onSelected: (_) => setState(() => _order = e.$1),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          _title(reference ? 'Scale shape' : 'Preview'),
          const SizedBox(height: 8),
          _preview(scheme, reference),
          const SizedBox(height: 24),
          // Delay only for the timed drill/solo in timer mode.
          if (!reference && !_tempoMode) ...[
            _title('Delay between notes'),
            const SizedBox(height: 8),
            _delaySelector(),
            const SizedBox(height: 24),
          ],
          if (!reference) ...[
            _title('Session length'),
            const SizedBox(height: 8),
            _sessionSelector(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _play,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            icon: Icon(reference ? Icons.visibility : Icons.play_arrow),
            label: Text(reference ? 'View full neck' : 'Play'),
          ),
        ),
      ),
    );
  }

  Widget _title(String t) =>
      Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700));

  Widget _positionStepper(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _fromFret > 0 ? () => setState(() => _fromFret--) : null,
            icon: const Icon(Icons.remove),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('fret', style: TextStyle(fontSize: 10, color: Colors.white54)),
              Text('$_fromFret–${_fromFret + _boxFrets - 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: _fromFret < 15 ? () => setState(() => _fromFret++) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _preview(ColorScheme scheme, bool reference) {
    if (reference) {
      // Whole neck (0–15), horizontally scrollable.
      const frets = 16;
      final notes = ScaleLibrary.positionsFor(_rootPc, _scale, 0, frets);
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: frets * 46,
              child: FretboardView(
                fromFret: 0,
                fretCount: frets,
                notes: notes,
                showLabels: true,
                accent: scheme.primary,
                height: 188,
              ),
            ),
          ),
        ),
      );
    }
    final notes = ScaleLibrary.positionsFor(_rootPc, _scale, _fromFret, _boxFrets);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: FretboardView(
          fromFret: _fromFret,
          fretCount: _boxFrets,
          notes: notes,
          showLabels: true,
          accent: scheme.primary,
          height: 188,
        ),
      ),
    );
  }

  Widget _delaySelector() {
    return Wrap(
      spacing: 10,
      children: [1, 2, 3, 4, 5].map((d) {
        return ChoiceChip(
          showCheckmark: false,
          label: Text('${d}s'),
          selected: _delay == d,
          onSelected: (_) => setState(() => _delay = d),
        );
      }).toList(),
    );
  }

  Widget _sessionSelector() {
    const options = {0: 'Endless', 1: '1 min', 3: '3 min', 5: '5 min', 10: '10 min'};
    return Wrap(
      spacing: 10,
      children: options.entries.map((e) {
        return ChoiceChip(
          showCheckmark: false,
          label: Text(e.value),
          selected: _sessionMinutes == e.key,
          onSelected: (_) => setState(() => _sessionMinutes = e.key),
        );
      }).toList(),
    );
  }

  Widget _settingsDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Text('Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            _title('Metronome'),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tempo mode',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              value: _tempoMode,
              onChanged: (v) => setState(() => _tempoMode = v),
            ),
            if (_tempoMode) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Beat flash',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                value: _beatFlash,
                onChanged: (v) => setState(() => _beatFlash = v),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Tempo', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('$_bpm BPM',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _bpm > 40 ? () => setState(() => _bpm--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Slider(
                      min: 40,
                      max: 208,
                      value: _bpm.toDouble(),
                      onChanged: (v) => setState(() => _bpm = v.round()),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _bpm < 208 ? () => setState(() => _bpm++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Beats per bar', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [2, 3, 4, 6].map((b) {
                  return ChoiceChip(
                    showCheckmark: false,
                    label: Text('$b'),
                    selected: _beatsPerBar == b,
                    onSelected: (_) => setState(() => _beatsPerBar = b),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-neck scale reference (study, keep-awake, no timing).
class _ReferenceScreen extends StatefulWidget {
  final ScaleType scale;
  final int rootPc;
  const _ReferenceScreen({required this.scale, required this.rootPc});

  @override
  State<_ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<_ReferenceScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const frets = 16;
    final notes = ScaleLibrary.positionsFor(widget.rootPc, widget.scale, 0, frets);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(
        title: Text('${ScaleLibrary.roots[widget.rootPc]} ${widget.scale.name}'),
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: frets * 58,
            child: FretboardView(
              fromFret: 0,
              fretCount: frets,
              notes: notes,
              showLabels: true,
              accent: scheme.primary,
              height: 280,
            ),
          ),
        ),
      ),
    );
  }
}
