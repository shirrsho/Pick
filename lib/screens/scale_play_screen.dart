import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/scale_library.dart';
import '../services/metronome.dart';
import '../services/practice_reminder.dart';
import '../widgets/fretboard_view.dart';

enum ScalePlayMode { drill, solo }

enum NoteOrder { ascending, descending, random }

class ScalePlayScreen extends StatefulWidget {
  final ScalePlayMode playMode;
  final ScaleType scale;
  final int rootPc;
  final int fromFret;
  final int fretCount;
  final NoteOrder order; // drill only

  final int delaySeconds;
  final Duration? sessionLimit;
  final bool tempoMode;
  final int bpm;
  final int beatsPerBar;
  final bool beatFlash;

  const ScalePlayScreen({
    super.key,
    required this.playMode,
    required this.scale,
    required this.rootPc,
    required this.fromFret,
    required this.fretCount,
    this.order = NoteOrder.ascending,
    required this.delaySeconds,
    this.sessionLimit,
    this.tempoMode = false,
    this.bpm = 90,
    this.beatsPerBar = 4,
    this.beatFlash = true,
  });

  @override
  State<ScalePlayScreen> createState() => _ScalePlayScreenState();
}

class _ScalePlayScreenState extends State<ScalePlayScreen>
    with TickerProviderStateMixin {
  final Random _rng = Random();
  late List<NotePos> _boxNotes; // all scale notes in the box (fretboard dots)
  late List<NotePos> _seq; // ordered sequence (asc/desc); empty for random/solo
  int _index = 0;
  late NotePos _current;
  NotePos? _next;

  late AnimationController _progress;
  bool _paused = false;

  int _countdown = 3;
  Timer? _countdownTimer;

  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;

  // Metronome (tempo).
  MetronomeEngine? _metro;
  bool _practiceStarted = false;
  late AnimationController _flash;
  Color _flashColor = Colors.white;
  double _flashWidth = 14;

  // Completion.
  bool _finished = false;
  bool _sessionRecorded = false;
  int _lifetimeSeconds = 0;
  Duration _sessionElapsed = Duration.zero;

  bool get _tempo => widget.tempoMode;
  bool get _solo => widget.playMode == ScalePlayMode.solo;
  bool get _random => widget.order == NoteOrder.random;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _boxNotes = ScaleLibrary.positionsFor(
        widget.rootPc, widget.scale, widget.fromFret, widget.fretCount);
    _seq = switch (widget.order) {
      NoteOrder.ascending => ScaleLibrary.ascending(
          widget.rootPc, widget.scale, widget.fromFret, widget.fretCount),
      NoteOrder.descending => ScaleLibrary.descending(
          widget.rootPc, widget.scale, widget.fromFret, widget.fretCount),
      NoteOrder.random => const [],
    };

    _current = _firstNote();
    _next = _solo ? null : _peekNext();

    _progress = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.delaySeconds),
    )..addStatusListener((s) {
        if (!_tempo && s == AnimationStatus.completed && !_paused) _advance();
      });
    _flash = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));

    if (_tempo) {
      _metro = MetronomeEngine(bpm: widget.bpm, beatsPerBar: widget.beatsPerBar)
        ..onBeat = _onBeat;
      _metro!.load();
    }
    _startCountdown();
  }

  NotePos _firstNote() {
    if (_random || _boxNotes.isEmpty && _seq.isEmpty) {
      return ScaleLibrary.randomNote(
          widget.rootPc, widget.scale, widget.fromFret, widget.fretCount, _rng);
    }
    if (_solo) {
      return ScaleLibrary.randomNote(
          widget.rootPc, widget.scale, widget.fromFret, widget.fretCount, _rng);
    }
    _index = 0;
    return _seq.isNotEmpty ? _seq.first : _boxNotes.first;
  }

  NotePos _peekNext() {
    if (_random) {
      return ScaleLibrary.randomNote(widget.rootPc, widget.scale, widget.fromFret,
          widget.fretCount, _rng,
          exclude: _current);
    }
    if (_seq.isEmpty) return _current;
    return _seq[(_index + 1) % _seq.length];
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _beginPractice();
      }
    });
  }

  void _beginPractice() {
    if (_tempo) {
      _metro!.start();
    } else {
      _startClock();
      _progress.forward();
    }
  }

  void _startClock() {
    _practiceStarted = true;
    _watch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final limit = widget.sessionLimit;
      if (limit != null && _watch.elapsed >= limit) {
        _finish();
      } else {
        setState(() {});
      }
    });
    PracticeReminder.markPracticed();
  }

  void _onBeat(int globalIndex, int beatInBar, bool isDown) {
    if (!mounted || _paused) return;
    _pulseFlash(isDown);
    final countIn = widget.beatsPerBar;
    if (globalIndex < countIn) {
      setState(() {});
      return;
    }
    if (globalIndex == countIn) {
      _startClock();
    }
    // Drill advances every beat; solo changes target every bar (downbeat).
    if (_solo) {
      if (isDown) _advance();
    } else {
      _advance();
    }
    setState(() {});
  }

  void _advance() {
    setState(() {
      if (_solo || _random) {
        _current = ScaleLibrary.randomNote(widget.rootPc, widget.scale,
            widget.fromFret, widget.fretCount, _rng,
            exclude: _current);
        _next = _solo ? null : _peekNext();
      } else {
        _index = (_index + 1) % (_seq.isEmpty ? 1 : _seq.length);
        _current = _seq.isNotEmpty ? _seq[_index] : _current;
        _next = _peekNext();
      }
    });
    if (!_tempo) _progress..reset()..forward();
  }

  void _pulseFlash(bool isDown) {
    if (!widget.beatFlash) return;
    _flashColor = isDown ? Theme.of(context).colorScheme.primary : Colors.white;
    _flashWidth = isDown ? 34 : 18;
    _flash.value = 1.0;
    _flash.animateTo(0, curve: Curves.easeOut);
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _metro?.pause();
        if (_practiceStarted) {
          _progress.stop();
          _watch.stop();
        }
      } else {
        _metro?.resume();
        if (_practiceStarted) {
          if (!_tempo) _progress.forward();
          _watch.start();
        }
      }
    });
  }

  void _skip() => _advance();

  Future<void> _finish() async {
    _ticker?.cancel();
    _progress.stop();
    _watch.stop();
    _sessionElapsed = _watch.elapsed;
    _sessionRecorded = true;
    final total = await PracticeReminder.addSession(_sessionElapsed);
    if (!mounted) return;
    setState(() {
      _lifetimeSeconds = total;
      _finished = true;
    });
  }

  void _restart() {
    _ticker?.cancel();
    _countdownTimer?.cancel();
    _metro?.stop();
    _progress.reset();
    _watch..stop()..reset();
    setState(() {
      _finished = false;
      _sessionRecorded = false;
      _paused = false;
      _practiceStarted = false;
      _current = _firstNote();
      _next = _solo ? null : _peekNext();
    });
    _startCountdown();
  }

  @override
  void dispose() {
    if (!_sessionRecorded) PracticeReminder.addSession(_watch.elapsed);
    _countdownTimer?.cancel();
    _ticker?.cancel();
    _metro?.dispose();
    _flash.dispose();
    _progress.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtLong(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return s > 0 ? '${m}m ${s}s' : '${m}m';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_finished) return _completionScreen(scheme);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (!_tempo)
                  AnimatedBuilder(
                    animation: _progress,
                    builder: (_, _) => LinearProgressIndicator(
                      value: _progress.value,
                      minHeight: 5,
                      backgroundColor: Colors.white10,
                      color: scheme.primary,
                    ),
                  )
                else
                  const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      _controls(),
                      const Spacer(),
                      Text(
                        '${ScaleLibrary.roots[widget.rootPc]} ${widget.scale.shortName}',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (_tempo && _metro != null) _beatDots(scheme),
                Expanded(child: _stage(scheme)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 20, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(_fmt(_watch.elapsed),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      if (widget.sessionLimit != null)
                        Text(' / ${_fmt(widget.sessionLimit!)}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14)),
                      if (_paused) ...[
                        const SizedBox(width: 8),
                        Text('paused',
                            style: TextStyle(color: scheme.primary, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_tempo && widget.beatFlash) _flashOverlay(),
          if (_countdown > 0) _countdownOverlay(scheme),
        ],
      ),
    );
  }

  Widget _stage(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_solo ? 'TARGET' : 'PLAY',
              style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_current.name}  ·  str ${6 - _current.string} / fr ${_current.fret}',
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          FretboardView(
            fromFret: widget.fromFret,
            fretCount: widget.fretCount,
            notes: _boxNotes,
            highlight: _current,
            upcoming: _solo ? null : _next,
            showLabels: false,
            accent: scheme.primary,
            height: 188,
          ),
        ],
      ),
    );
  }

  Widget _beatDots(ColorScheme scheme) {
    return ValueListenableBuilder<int>(
      valueListenable: _metro!.beatInBar,
      builder: (_, beat, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.beatsPerBar, (i) {
                  final active = beat == i + 1;
                  final isDown = i == 0;
                  final color = active
                      ? (isDown ? scheme.primary : Colors.white)
                      : Colors.white24;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      width: active ? 20 : 11,
                      height: active ? 20 : 11,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  );
                }),
              ),
              if (!_practiceStarted)
                Text('count-in • ${widget.bpm} BPM',
                    style: TextStyle(color: scheme.primary, fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Widget _controls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Stop',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _togglePause,
          icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
          tooltip: _paused ? 'Resume' : 'Pause',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _skip,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Skip',
        ),
      ],
    );
  }

  Widget _flashOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _flash,
          builder: (_, _) {
            final v = _flash.value;
            if (v <= 0.01) return const SizedBox.shrink();
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                    color: _flashColor.withValues(alpha: v * 0.9), width: _flashWidth * v),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _countdownOverlay(ColorScheme scheme) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0E1116),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Get ready',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$_countdown',
                    style: TextStyle(
                        color: scheme.primary,
                        fontSize: 96,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Text(_solo ? 'IMPROVISE IN' : 'FIRST NOTE',
                    style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const SizedBox(height: 6),
                Text(
                  '${ScaleLibrary.roots[widget.rootPc]} ${widget.scale.shortName}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                FretboardView(
                  fromFret: widget.fromFret,
                  fretCount: widget.fretCount,
                  notes: _boxNotes,
                  highlight: _solo ? null : _current,
                  accent: scheme.primary,
                  height: 168,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _completionScreen(ColorScheme scheme) {
    final lifetime = Duration(seconds: _lifetimeSeconds);
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, const Color(0xFFE1322B)],
                  ),
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('Nice practice! 🎸',
                  style: TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${ScaleLibrary.roots[widget.rootPc]} ${widget.scale.name}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 15)),
              const SizedBox(height: 28),
              _statRow(scheme, Icons.timer_outlined, 'This session',
                  _fmtLong(_sessionElapsed)),
              const SizedBox(height: 12),
              _statRow(scheme, Icons.local_fire_department,
                  'Total practice (all-time)', _fmtLong(lifetime)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _restart,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Practice again'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(ColorScheme scheme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
