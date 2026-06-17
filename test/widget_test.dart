import 'package:flutter_test/flutter_test.dart';

import 'package:loop_chords/main.dart';
import 'package:loop_chords/data/chord_library.dart';

void main() {
  testWidgets('Home screen shows the play button', (tester) async {
    await tester.pumpWidget(const PracticeChordsApp());
    expect(find.text('LoopChords'), findsOneWidget);
    expect(find.textContaining('Play'), findsOneWidget);
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
}
