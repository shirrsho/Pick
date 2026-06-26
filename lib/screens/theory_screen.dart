import 'package:flutter/material.dart';
import '../data/scale_library.dart';
import '../widgets/fretboard_view.dart';

/// A static, read-only primer on music theory: notes, steps, scales, keys,
/// pentatonic and blues — written for beginners.
class TheoryScreen extends StatelessWidget {
  const TheoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0E1116),
      appBar: AppBar(title: const Text('Music theory basics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _lead(
            'A short, plain-English guide — from the 12 notes all the way to the '
            'scales you can solo with. No prior theory needed.',
          ),

          _h('1 · The 12 notes', scheme),
          _p('Music uses just seven letter names that repeat: A B C D E F G, then '
              'back to A. Between most of them sits one extra note — a sharp (♯, '
              'one step up) or flat (♭, one step down). C♯ and D♭ are the same '
              'note, just named two ways.'),
          _p('There is NO extra note between B–C and E–F. Add it all up and you '
              'get 12 notes that cycle forever:'),
          _noteRow(scheme),
          _p('After the 12th note you are back where you started, one octave '
              'higher — the same note, higher in pitch.'),

          _h('2 · Half steps & whole steps', scheme),
          _p('Distance between notes is measured in steps:'),
          _fact(scheme, 'Half step (semitone)', 'the smallest move — on guitar, '
              '1 fret up or down.'),
          _fact(scheme, 'Whole step (tone)', 'two half steps — on guitar, 2 frets.'),
          _p('Every scale is just a recipe of half and whole steps. Learn the '
              'recipe once and you can build it from any note.'),

          _h('3 · What is a scale?', scheme),
          _p('A scale is a chosen handful of the 12 notes, picked in a fixed '
              'pattern of steps. The note you start on is the root (or "tonic") — '
              'it is "home", and it names the scale. "A minor" means a minor '
              'scale starting on A.'),
          _p('Play a scale\'s notes in order and your ear hears a mood. Different '
              'step-patterns give different moods.'),

          _h('4 · The major scale', scheme),
          _p('The most important scale. Its recipe of steps is:'),
          _fact(scheme, 'Major recipe', 'W  W  H  W  W  W  H'),
          _p('Start on C and follow it and you only land on the natural notes:'),
          _fact(scheme, 'C major', 'C  D  E  F  G  A  B'),
          _p('Bright and happy sounding. The numbers 1–7 of a scale are its '
              '"degrees": 1 is the root, 3 the third, 5 the fifth, and so on. '
              'Chords are built by stacking these degrees.'),

          _h('5 · The minor scale', scheme),
          _p('The natural minor scale has a darker, more serious sound. Its '
              'recipe is:'),
          _fact(scheme, 'Minor recipe', 'W  H  W  W  H  W  W'),
          _fact(scheme, 'A minor', 'A  B  C  D  E  F  G'),
          _p('Notice A minor uses the exact same notes as C major — just starting '
              'from a different home note. That pairing is called "relative" major '
              'and minor. Every major scale has a relative minor.'),

          _h('6 · Keys', scheme),
          _p('A "key" is simply the scale a song lives in — its home note and the '
              'family of notes (and chords) that sound right together. A song "in '
              'the key of G" mostly uses notes and chords from the G major scale. '
              'The Chords tab\'s "Scale" picker shows the chords of a key.'),

          _h('7 · Pentatonic scales (your soloing friends)', scheme),
          _p('"Penta" = five. Pentatonic scales drop the two most tense notes, '
              'leaving five that sound good over almost anything in the key — '
              'which is why most guitar solos and riffs live here.'),
          _fact(scheme, 'Minor pentatonic', '1  ♭3  4  5  ♭7   (A C D E G)'),
          _fact(scheme, 'Major pentatonic', '1  2  3  5  6   (A B C♯ E F♯)'),
          _p('On the guitar a scale is a shape you can slide anywhere. Here is the '
              'most-used one — the A minor pentatonic "box" at the 5th fret '
              '(orange dots are the root, A):'),
          _illustration(scheme),
          _p('Move that same shape up two frets and it becomes B minor '
              'pentatonic. The shape never changes — only where you start.'),

          _h('8 · The blues scale', scheme),
          _p('Take the minor pentatonic and add one extra "blue note" (the ♭5) '
              'for that gritty, bluesy tension:'),
          _fact(scheme, 'Blues', '1  ♭3  4  ♭5  5  ♭7'),

          _h('9 · Putting it to work', scheme),
          _p('That is the whole journey: 12 notes → steps → scales → keys → '
              'pentatonic & blues. You do not need to memorise it — just play.'),
          _p('Open the Leads tab, pick a key and scale, and:'),
          _bullet('Reference — see the shape on the neck.'),
          _bullet('Drill — play the notes in time to build muscle memory.'),
          _bullet('Solo — improvise over the metronome using the scale.'),
          const SizedBox(height: 8),
          _p('Start with A minor pentatonic — it is the classic first solo scale. '
              'Have fun. 🎸'),
        ],
      ),
    );
  }

  Widget _lead(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, height: 1.5, color: Colors.white70)),
      );

  Widget _h(String text, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(top: 26, bottom: 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: scheme.primary)),
      );

  Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15.5, height: 1.55, color: Colors.white70)),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ',
                style: TextStyle(fontSize: 15.5, color: Colors.white70)),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15.5, height: 1.5, color: Colors.white70)),
            ),
          ],
        ),
      );

  Widget _fact(ColorScheme scheme, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: scheme.primary, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ],
        ),
      );

  Widget _noteRow(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final n in ScaleLibrary.noteNames)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: n.contains('#')
                    ? Colors.white.withValues(alpha: 0.06)
                    : scheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(n,
                  style: TextStyle(
                      color: n.contains('#') ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _illustration(ColorScheme scheme) {
    final notes = ScaleLibrary.positionsFor(9, ScaleLibrary.scales[2], 5, 5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: FretboardView(
        fromFret: 5,
        fretCount: 5,
        notes: notes,
        showLabels: true,
        accent: scheme.primary,
        height: 180,
      ),
    );
  }
}
