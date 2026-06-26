import 'package:flutter/material.dart';
import '../data/scale_library.dart';

/// A horizontal guitar fretboard that plots scale notes within a fret window.
/// Low E (6th string) is drawn at the bottom; frets increase left -> right.
class FretboardView extends StatelessWidget {
  final int fromFret;
  final int fretCount;
  final List<NotePos> notes; // all scale notes (dots)
  final NotePos? highlight; // current target (bright + label)
  final NotePos? upcoming; // next target (faint ring)
  final bool showLabels; // note names inside every dot
  final Color accent;
  final double height;

  const FretboardView({
    super.key,
    required this.fromFret,
    required this.fretCount,
    required this.notes,
    this.highlight,
    this.upcoming,
    this.showLabels = false,
    required this.accent,
    this.height = 168,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _FretboardPainter(
          fromFret: fromFret,
          fretCount: fretCount,
          notes: notes,
          highlight: highlight,
          upcoming: upcoming,
          showLabels: showLabels,
          accent: accent,
        ),
      ),
    );
  }
}

class _FretboardPainter extends CustomPainter {
  final int fromFret;
  final int fretCount;
  final List<NotePos> notes;
  final NotePos? highlight;
  final NotePos? upcoming;
  final bool showLabels;
  final Color accent;

  _FretboardPainter({
    required this.fromFret,
    required this.fretCount,
    required this.notes,
    required this.highlight,
    required this.upcoming,
    required this.showLabels,
    required this.accent,
  });

  static const _inlayFrets = {3, 5, 7, 9, 15, 17, 19, 21};

  @override
  void paint(Canvas canvas, Size size) {
    final left = size.width * 0.06 + (fromFret == 0 ? 0 : 14);
    final right = size.width * 0.03;
    final top = size.height * 0.08;
    final bottom = size.height * 0.16; // room for fret numbers

    final gridW = size.width - left - right;
    final gridH = size.height - top - bottom;
    final colW = gridW / fretCount;
    final rowGap = gridH / 5; // 6 strings

    double stringY(int s) => top + (5 - s) * rowGap; // low E (0) at bottom
    double lineX(int i) => left + i * colW;
    double noteX(int f) => left + (f - fromFret + 0.5) * colW;

    final wood = Paint()..color = Colors.white.withValues(alpha: 0.03);
    canvas.drawRect(
        Rect.fromLTRB(lineX(0), top, lineX(fretCount), stringY(0)), wood);

    final fretPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.4;
    final stringPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.2;

    // Inlay markers.
    final inlayPaint = Paint()..color = Colors.white12;
    final midY = (stringY(0) + stringY(5)) / 2;
    for (int j = 0; j < fretCount; j++) {
      final f = fromFret + j;
      final cx = noteX(f);
      if (f == 12 || f == 24) {
        canvas.drawCircle(Offset(cx, midY - rowGap * 0.9), rowGap * 0.16, inlayPaint);
        canvas.drawCircle(Offset(cx, midY + rowGap * 0.9), rowGap * 0.16, inlayPaint);
      } else if (_inlayFrets.contains(f)) {
        canvas.drawCircle(Offset(cx, midY), rowGap * 0.18, inlayPaint);
      }
    }

    // Frets (vertical). The left edge is the nut when starting at fret 0.
    for (int i = 0; i <= fretCount; i++) {
      final isNut = fromFret == 0 && i == 0;
      canvas.drawLine(
        Offset(lineX(i), stringY(5)),
        Offset(lineX(i), stringY(0)),
        isNut
            ? (Paint()
              ..color = Colors.white
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round)
            : fretPaint,
      );
    }

    // Strings (horizontal).
    for (int s = 0; s < 6; s++) {
      canvas.drawLine(
          Offset(lineX(0), stringY(s)), Offset(lineX(fretCount), stringY(s)), stringPaint);
    }

    // Fret-number labels.
    for (int j = 0; j < fretCount; j++) {
      final f = fromFret + j;
      _text(canvas, '$f', Offset(noteX(f), stringY(0) + bottom * 0.5),
          Colors.white38, rowGap * 0.34);
    }

    // Scale-note dots.
    final r = rowGap * 0.36;
    for (final n in notes) {
      if (n.fret < fromFret || n.fret >= fromFret + fretCount) continue;
      final c = Offset(noteX(n.fret), stringY(n.string));
      final paint = Paint()
        ..color = n.isRoot ? accent : Colors.white.withValues(alpha: 0.16);
      canvas.drawCircle(c, r, paint);
      if (showLabels) {
        _text(canvas, n.name, c, n.isRoot ? Colors.black : Colors.white70, r * 0.95);
      }
    }

    // Upcoming (next) note — faint ring.
    final up = upcoming;
    if (up != null && up.fret >= fromFret && up.fret < fromFret + fretCount) {
      final c = Offset(noteX(up.fret), stringY(up.string));
      canvas.drawCircle(
        c,
        r * 1.15,
        Paint()
          ..color = Colors.white54
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Highlighted (current) note — bright + glow + label.
    final hl = highlight;
    if (hl != null && hl.fret >= fromFret && hl.fret < fromFret + fretCount) {
      final c = Offset(noteX(hl.fret), stringY(hl.string));
      canvas.drawCircle(c, r * 1.7,
          Paint()..color = accent.withValues(alpha: 0.35)..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 8));
      canvas.drawCircle(c, r * 1.35, Paint()..color = accent);
      _text(canvas, hl.name, c, Colors.black, r * 1.25, bold: true);
    }

    // Starting-fret label when not at the nut.
    if (fromFret > 0) {
      _text(canvas, '$fromFret', Offset(left - 9, midY), Colors.white54, rowGap * 0.4);
    }
  }

  void _text(Canvas canvas, String s, Offset center, Color color, double size,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter old) =>
      old.fromFret != fromFret ||
      old.fretCount != fretCount ||
      old.notes != notes ||
      old.highlight != highlight ||
      old.upcoming != upcoming ||
      old.showLabels != showLabels ||
      old.accent != accent;
}
