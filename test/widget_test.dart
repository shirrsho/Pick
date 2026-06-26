import 'package:flutter_test/flutter_test.dart';

import 'package:pick/main.dart';
import 'package:pick/data/chord_library.dart';
import 'package:pick/data/scale_library.dart';

void main() {
  testWidgets('Landing screen offers Chords and Leads', (tester) async {
    await tester.pumpWidget(const PickApp());
    expect(find.text('Pick'), findsOneWidget);
    expect(find.text('Chords'), findsOneWidget);
    expect(find.text('Leads'), findsOneWidget);
  });

  test('Every scale chord resolves to a known shape', () {
    for (final scale in ChordLibrary.scaleNames) {
      final chords = ChordLibrary.chordsForScale(scale);
      expect(chords.length, ChordLibrary.scaleChordNames[scale]!.length,
          reason: 'Unresolved chord in $scale');
      for (final c in chords) {
        expect(c.frets.length, 6, reason: '${c.name} must have 6 string entries');
      }
    }
  });

  test('Scale library maps the fretboard correctly', () {
    // A minor pentatonic = A C D E G.
    final aMinPent = ScaleLibrary.scales[2];
    expect(aMinPent.shortName, 'Min Pent');
    final notes = ScaleLibrary.positionsFor(9 /* A */, aMinPent, 5, 5)
        .map((n) => n.name)
        .toSet();
    expect(notes, {'A', 'C', 'D', 'E', 'G'});

    // Open low-E string is an E; fret 5 on low E is an A (the box root).
    expect(ScaleLibrary.noteAt(0, 0), 'E');
    expect(ScaleLibrary.noteAt(0, 5), 'A');

    // Ascending run starts on the lowest pitch and is sorted low -> high.
    final asc = ScaleLibrary.ascending(9, aMinPent, 5, 5);
    expect(asc.isNotEmpty, true);
    for (var i = 1; i < asc.length; i++) {
      final prev = ScaleLibrary.midiAt(asc[i - 1].string, asc[i - 1].fret);
      final cur = ScaleLibrary.midiAt(asc[i].string, asc[i].fret);
      expect(cur >= prev, true);
    }
  });
}
