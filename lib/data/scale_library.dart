import 'dart:math';

/// A scale type defined by its semitone intervals from the root.
class ScaleType {
  final String name; // full name
  final String shortName; // chip label
  final List<int> intervals; // semitones from root, e.g. major = 0 2 4 5 7 9 11

  const ScaleType(this.name, this.shortName, this.intervals);
}

/// A single playable note position on the fretboard.
class NotePos {
  final int string; // 0 = low E (6th) .. 5 = high e (1st)
  final int fret;
  final String name; // note name, e.g. "A"
  final bool isRoot;

  const NotePos(this.string, this.fret, this.name, this.isRoot);
}

/// Scale formulas, standard-tuning fretboard mapping, and helpers for building
/// the reference / drill / solo note sets. Mirrors the static-data style of
/// [ChordLibrary].
class ScaleLibrary {
  ScaleLibrary._();

  /// Pitch classes 0 = C .. 11 = B.
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// The 12 selectable roots.
  static const List<String> roots = noteNames;

  /// Open-string pitch classes, low E -> high e.
  static const List<int> _openPc = [4, 9, 2, 7, 11, 4];

  /// Open-string MIDI numbers, low E -> high e (for absolute pitch ordering).
  static const List<int> _openMidi = [40, 45, 50, 55, 59, 64];

  static const List<ScaleType> scales = [
    ScaleType('Major', 'Major', [0, 2, 4, 5, 7, 9, 11]),
    ScaleType('Natural minor', 'Minor', [0, 2, 3, 5, 7, 8, 10]),
    ScaleType('Minor pentatonic', 'Min Pent', [0, 3, 5, 7, 10]),
    ScaleType('Major pentatonic', 'Maj Pent', [0, 2, 4, 7, 9]),
    ScaleType('Blues', 'Blues', [0, 3, 5, 6, 7, 10]),
  ];

  static int pitchAt(int string, int fret) => (_openPc[string] + fret) % 12;
  static String noteAt(int string, int fret) => noteNames[pitchAt(string, fret)];
  static int midiAt(int string, int fret) => _openMidi[string] + fret;

  static bool _inScale(int pitch, int rootPc, ScaleType scale) {
    final degree = (pitch - rootPc + 144) % 12;
    return scale.intervals.contains(degree);
  }

  /// All scale notes within the window [fromFret, fromFret + fretCount - 1].
  static List<NotePos> positionsFor(
    int rootPc,
    ScaleType scale,
    int fromFret,
    int fretCount,
  ) {
    final out = <NotePos>[];
    for (int s = 0; s < 6; s++) {
      for (int f = fromFret; f < fromFret + fretCount; f++) {
        if (f < 0) continue;
        final pc = pitchAt(s, f);
        if (_inScale(pc, rootPc, scale)) {
          out.add(NotePos(s, f, noteNames[pc], pc == rootPc));
        }
      }
    }
    return out;
  }

  /// Box notes ordered low -> high pitch (ascending run).
  static List<NotePos> ascending(
    int rootPc,
    ScaleType scale,
    int fromFret,
    int fretCount,
  ) {
    final list = positionsFor(rootPc, scale, fromFret, fretCount);
    list.sort((a, b) => midiAt(a.string, a.fret).compareTo(midiAt(b.string, b.fret)));
    return list;
  }

  static List<NotePos> descending(
    int rootPc,
    ScaleType scale,
    int fromFret,
    int fretCount,
  ) =>
      ascending(rootPc, scale, fromFret, fretCount).reversed.toList();

  /// A sensible default 5-fret box: the root's position on the low-E string.
  static int defaultBox(int rootPc) => (rootPc - _openPc[0] + 12) % 12;

  /// Pick a random in-box scale note, avoiding [exclude] when possible.
  static NotePos randomNote(
    int rootPc,
    ScaleType scale,
    int fromFret,
    int fretCount,
    Random rng, {
    NotePos? exclude,
  }) {
    final list = positionsFor(rootPc, scale, fromFret, fretCount);
    if (list.isEmpty) return const NotePos(0, 0, 'E', false);
    if (list.length == 1) return list.first;
    NotePos n;
    do {
      n = list[rng.nextInt(list.length)];
    } while (exclude != null && n.string == exclude.string && n.fret == exclude.fret);
    return n;
  }
}
