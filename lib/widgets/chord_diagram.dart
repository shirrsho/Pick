import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chord.dart';

/// Draws a standard vertical guitar chord diagram (fretboard) for a [Chord].
class ChordDiagram extends StatelessWidget {
  final Chord chord;
  final Color color;

  const ChordDiagram({super.key, required this.chord, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: CustomPaint(
        painter: _ChordPainter(chord, color),
      ),
    );
  }
}

class _ChordPainter extends CustomPainter {
  final Chord chord;
  final Color color;

  _ChordPainter(this.chord, this.color);

  static const int strings = 6;
  static const int displayFrets = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final fretted = chord.frets.where((f) => f > 0).toList();
    final maxF = fretted.isEmpty ? 0 : fretted.reduce(max);
    final minF = fretted.isEmpty ? 0 : fretted.reduce(min);

    // Decide the visible fret window.
    final startFret = (maxF <= displayFrets) ? 1 : minF;
    final showNut = startFret == 1;

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Layout margins.
    final left = size.width * (showNut ? 0.12 : 0.18);
    final right = size.width * 0.10;
    final top = size.height * 0.16;
    final bottom = size.height * 0.06;

    final gridW = size.width - left - right;
    final gridH = size.height - top - bottom;
    final colGap = gridW / (strings - 1);
    final rowGap = gridH / displayFrets;

    double sx(int s) => left + s * colGap; // string index 0..5 (low E -> high E)
    double fy(int f) => top + f * rowGap; // fret line 0..displayFrets

    // Nut (thick) or top fret line.
    final nutPaint = Paint()
      ..color = color
      ..strokeWidth = showNut ? 6 : 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(sx(0), fy(0)), Offset(sx(strings - 1), fy(0)), nutPaint);

    // Remaining fret lines.
    for (int f = 1; f <= displayFrets; f++) {
      canvas.drawLine(Offset(sx(0), fy(f)), Offset(sx(strings - 1), fy(f)), linePaint);
    }

    // Strings (vertical).
    for (int s = 0; s < strings; s++) {
      canvas.drawLine(Offset(sx(s), fy(0)), Offset(sx(s), fy(displayFrets)), linePaint);
    }

    // Starting-fret label when not at the nut.
    if (!showNut) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$startFret',
          style: TextStyle(
            color: color,
            fontSize: rowGap * 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - tp.width - colGap * 0.35, fy(0) + rowGap * 0.25));
    }

    final markerR = colGap * 0.30;
    final markerStyle = TextStyle(
      color: color,
      fontSize: colGap * 0.55,
      fontWeight: FontWeight.w600,
    );

    // Detect a barre: the lowest fretted fret pressed on 2+ strings with no
    // open/muted string in between (so one finger could bar across them).
    int? barreFret;
    int barreLeft = 0;
    int barreRight = 0;
    if (fretted.isNotEmpty) {
      final onMin = <int>[];
      for (int s = 0; s < strings; s++) {
        if (chord.frets[s] == minF) onMin.add(s);
      }
      if (onMin.length >= 2) {
        final l = onMin.first;
        final r = onMin.last;
        var valid = true;
        for (int s = l; s <= r; s++) {
          if (chord.frets[s] < minF) {
            valid = false; // an open/muted string interrupts the bar
            break;
          }
        }
        if (valid) {
          barreFret = minF;
          barreLeft = l;
          barreRight = r;
        }
      }
    }

    // Draw the barre bar (if any) underneath the finger dots.
    if (barreFret != null) {
      final rel = barreFret - startFret + 1;
      final cy = fy(rel) - rowGap / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          sx(barreLeft) - markerR,
          cy - markerR,
          sx(barreRight) + markerR,
          cy + markerR,
        ),
        Radius.circular(markerR),
      );
      canvas.drawRRect(rect, dotPaint);
    }

    for (int s = 0; s < strings; s++) {
      final f = chord.frets[s];
      final cx = sx(s);

      if (f == -1) {
        _drawMarker(canvas, 'x', cx, top * 0.5, markerStyle);
      } else if (f == 0) {
        _drawMarker(canvas, 'o', cx, top * 0.5, markerStyle);
      } else {
        // Skip dots already covered by the barre bar.
        final coveredByBarre =
            barreFret != null && f == barreFret && s >= barreLeft && s <= barreRight;
        if (coveredByBarre) continue;
        final rel = f - startFret + 1; // row within the window
        final cy = fy(rel) - rowGap / 2;
        canvas.drawCircle(Offset(cx, cy), markerR, dotPaint);
      }
    }
  }

  void _drawMarker(Canvas canvas, String text, double cx, double cy, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ChordPainter old) =>
      old.chord != chord || old.color != color;
}
