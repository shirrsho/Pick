import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/chord.dart';
import '../services/practice_reminder.dart';
import '../widgets/chord_diagram.dart';

class PlayScreen extends StatefulWidget {
  final List<Chord> chords;
  final int delaySeconds;

  /// Optional fixed session length. When null, practice runs until stopped.
  final Duration? sessionLimit;

  /// When non-null, chords play in order (looping) with one delay per chord —
  /// `stepDelays[i]` is the seconds to wait after `chords[i]` before the next.
  /// When null, chords appear randomly with [delaySeconds] between each.
  final List<int>? stepDelays;

  const PlayScreen({
    super.key,
    required this.chords,
    required this.delaySeconds,
    this.sessionLimit,
    this.stepDelays,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  late Chord _current;
  late Chord _next;
  late AnimationController _progress;
  bool _paused = false;

  // 3..2..1 countdown shown before practice starts (0 = practising).
  int _countdown = 3;
  Timer? _countdownTimer;

  // Current position in the sequence (loop mode only).
  int _index = 0;
  bool get _sequential => widget.stepDelays != null;

  // Total elapsed practice time (pauses while practice is paused).
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;

  // Completion (only for fixed-length sessions).
  bool _finished = false;
  bool _sessionRecorded = false; // guards against double-counting the total
  int _lifetimeSeconds = 0; // lifetime total, shown on the completion screen
  Duration _sessionElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Keep the screen on for the whole session, and hide system UI so the big
    // chord is the only thing on screen.
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (_sequential) {
      _index = 0;
      _current = widget.chords[0];
      _next = widget.chords[1 % widget.chords.length];
    } else {
      _current = _randomChord(exclude: null);
      _next = _randomChord(exclude: _current);
    }

    _progress = AnimationController(
      vsync: this,
      duration: Duration(
          seconds: _sequential ? widget.stepDelays![0] : widget.delaySeconds),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_paused) {
          _advance();
        }
      });

    _startCountdown();
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
    _watch.start();
    _progress.forward();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final limit = widget.sessionLimit;
      if (limit != null && _watch.elapsed >= limit) {
        _finish();
      } else {
        setState(() {}); // refresh the elapsed-time display
      }
    });
    // Starting a session clears the widget reminder.
    PracticeReminder.markPracticed();
  }

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
    _progress.reset();
    _watch
      ..stop()
      ..reset();
    setState(() {
      _finished = false;
      _sessionRecorded = false;
      _paused = false;
      if (_sequential) {
        _index = 0;
        _current = widget.chords[0];
        _next = widget.chords[1 % widget.chords.length];
        _progress.duration = Duration(seconds: widget.stepDelays![0]);
      } else {
        _current = _randomChord(exclude: null);
        _next = _randomChord(exclude: _current);
      }
    });
    _startCountdown();
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Chord _randomChord({Chord? exclude}) {
    if (widget.chords.length == 1) return widget.chords.first;
    Chord c;
    do {
      c = widget.chords[_rng.nextInt(widget.chords.length)];
    } while (exclude != null && c.name == exclude.name);
    return c;
  }

  void _advance() {
    setState(() {
      if (_sequential) {
        final n = widget.chords.length;
        _index = (_index + 1) % n;
        _current = widget.chords[_index];
        _next = widget.chords[(_index + 1) % n];
        _progress.duration = Duration(seconds: widget.stepDelays![_index]);
      } else {
        _current = _next;
        _next = _randomChord(exclude: _current);
      }
    });
    _progress
      ..reset()
      ..forward();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _progress.stop();
        _watch.stop();
      } else {
        _progress.forward();
        _watch.start();
      }
    });
  }

  void _skip() => _advance();

  @override
  void dispose() {
    // Record this session's length toward the lifetime total, unless a
    // fixed-length session already recorded it on completion.
    if (!_sessionRecorded) {
      PracticeReminder.addSession(_watch.elapsed);
    }
    _countdownTimer?.cancel();
    _ticker?.cancel();
    _progress.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String _formatLong(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
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
            // Timer progress bar across the top.
            AnimatedBuilder(
              animation: _progress,
              builder: (_, _) => LinearProgressIndicator(
                value: _progress.value,
                minHeight: 5,
                backgroundColor: Colors.white10,
                color: scheme.primary,
              ),
            ),

            // Top bar: playback controls.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  _controls(),
                  const Spacer(),
                  Text(
                    '${widget.chords.length} chords',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Current chord — name + big fretboard, fills the free space.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                child: Column(
                  children: [
                    // Name sits centered between the top and the diagram.
                    const Spacer(flex: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _current.name,
                        style: const TextStyle(
                          fontSize: 88,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: ChordDiagram(chord: _current),
                    ),
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),

            // Bottom bar: elapsed time on the left, next-chord preview on the right.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _elapsedTime(scheme),
                  const Spacer(),
                  _nextPreview(scheme),
                ],
              ),
            ),
          ],
            ),
          ),
          if (_countdown > 0) _countdownOverlay(scheme),
        ],
      ),
    );
  }

  // Full-screen 3..2..1 countdown that also previews the first chord.
  Widget _countdownOverlay(ColorScheme scheme) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFF0E1116),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get ready',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_countdown',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 96,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'FIRST CHORD',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _current.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: ChordDiagram(chord: _current),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Congratulatory screen shown after a fixed-length session completes.
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, const Color(0xFFE1322B)],
                  ),
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nice practice! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'You kept the loop going the whole time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
              ),
              const SizedBox(height: 28),
              _statRow(scheme, Icons.timer_outlined, 'This session',
                  _formatLong(_sessionElapsed)),
              const SizedBox(height: 12),
              _statRow(scheme, Icons.music_note, 'Chords practised',
                  '${widget.chords.length}'),
              const SizedBox(height: 12),
              _statRow(scheme, Icons.local_fire_department, 'Total practice (all-time)',
                  _formatLong(lifetime)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _restart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
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

  // Elapsed practice time (pauses with the session).
  Widget _elapsedTime(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 20, color: scheme.primary),
        const SizedBox(width: 6),
        Text(
          _formatElapsed(_watch.elapsed),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (widget.sessionLimit != null)
          Text(
            ' / ${_formatElapsed(widget.sessionLimit!)}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        if (_paused) ...[
          const SizedBox(width: 8),
          Text('paused', style: TextStyle(color: scheme.primary, fontSize: 13)),
        ],
      ],
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

  Widget _nextPreview(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _next.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: ChordDiagram(chord: _next, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
