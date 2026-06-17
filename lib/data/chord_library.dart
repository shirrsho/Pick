import '../models/chord.dart';

/// Central catalogue of chords plus the diatonic chord sets for common scales.
class ChordLibrary {
  ChordLibrary._();

  // Chromatic note order, used for naming/generating chords.
  static const List<String> _chromatic = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  // ---- Major triads -------------------------------------------------------
  static const Map<String, List<int>> _majors = {
    'C': [-1, 3, 2, 0, 1, 0],
    'C#': [-1, 4, 6, 6, 6, 4],
    'D': [-1, -1, 0, 2, 3, 2],
    'D#': [-1, 6, 8, 8, 8, 6],
    'E': [0, 2, 2, 1, 0, 0],
    'F': [1, 3, 3, 2, 1, 1],
    'F#': [2, 4, 4, 3, 2, 2],
    'G': [3, 2, 0, 0, 0, 3],
    'G#': [4, 6, 6, 5, 4, 4],
    'A': [-1, 0, 2, 2, 2, 0],
    'A#': [-1, 1, 3, 3, 3, 1],
    'B': [-1, 2, 4, 4, 4, 2],
  };

  // ---- Minor triads -------------------------------------------------------
  static const Map<String, List<int>> _minors = {
    'Cm': [-1, 3, 5, 5, 4, 3],
    'C#m': [-1, 4, 6, 6, 5, 4],
    'Dm': [-1, -1, 0, 2, 3, 1],
    'D#m': [-1, 6, 8, 8, 7, 6],
    'Em': [0, 2, 2, 0, 0, 0],
    'Fm': [1, 3, 3, 1, 1, 1],
    'F#m': [2, 4, 4, 2, 2, 2],
    'Gm': [3, 5, 5, 3, 3, 3],
    'G#m': [4, 6, 6, 4, 4, 4],
    'Am': [-1, 0, 2, 2, 1, 0],
    'A#m': [-1, 1, 3, 3, 2, 1],
    'Bm': [-1, 2, 4, 4, 3, 2],
  };

  // ---- Dominant 7th chords ------------------------------------------------
  static const Map<String, List<int>> _dom7 = {
    'C7': [-1, 3, 2, 3, 1, 0],
    'D7': [-1, -1, 0, 2, 1, 2],
    'E7': [0, 2, 0, 1, 0, 0],
    'F7': [1, 3, 1, 2, 1, 1],
    'G7': [3, 2, 0, 0, 0, 1],
    'A7': [-1, 0, 2, 0, 2, 0],
    'B7': [-1, 2, 1, 2, 0, 2],
  };

  // ---- Major 7th chords ---------------------------------------------------
  static const Map<String, List<int>> _maj7 = {
    'Cmaj7': [-1, 3, 2, 0, 0, 0],
    'Dmaj7': [-1, -1, 0, 2, 2, 2],
    'Emaj7': [0, 2, 1, 1, 0, 0],
    'Fmaj7': [-1, -1, 3, 2, 1, 0],
    'Gmaj7': [3, 2, 0, 0, 0, 2],
    'Amaj7': [-1, 0, 2, 1, 2, 0],
  };

  // ---- Minor 7th chords ---------------------------------------------------
  static const Map<String, List<int>> _min7 = {
    'Am7': [-1, 0, 2, 0, 1, 0],
    'Bm7': [-1, 2, 0, 2, 0, 2],
    'Dm7': [-1, -1, 0, 2, 1, 1],
    'Em7': [0, 2, 0, 0, 0, 0],
    'Fm7': [1, 3, 1, 1, 1, 1],
  };

  /// Fret position on the A (5th) string for each chromatic note, used to
  /// build movable diminished triad shapes.
  static const Map<String, int> _aStringFret = {
    'A': 0, 'A#': 1, 'B': 2, 'C': 3, 'C#': 4, 'D': 5, 'D#': 6,
    'E': 7, 'F': 8, 'F#': 9, 'G': 10, 'G#': 11,
  };

  // Lazily built master catalogue keyed by chord name.
  static final Map<String, Chord> _catalogue = _buildCatalogue();

  static Map<String, Chord> _buildCatalogue() {
    final map = <String, Chord>{};

    void add(Map<String, List<int>> src, String quality) {
      src.forEach((name, frets) => map[name] = Chord(name, frets, quality));
    }

    add(_majors, 'major');
    add(_minors, 'minor');
    add(_dom7, 'dom7');
    add(_maj7, 'maj7');
    add(_min7, 'min7');

    // Diminished triads for all 12 roots via a movable A-string shape:
    // x R(b3)(b5)(b3)x  ->  [-1, n, n+1, n+2, n+1, -1]
    for (final note in _chromatic) {
      final n = _aStringFret[note]!;
      final name = '${note}dim';
      map[name] = Chord(name, [-1, n, n + 1, n + 2, n + 1, -1], 'dim');
    }

    // Flat-name aliases pointing at the same shapes (used by flat-key scales).
    const aliases = {
      'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#', 'Bb': 'A#',
      'Dbm': 'C#m', 'Ebm': 'D#m', 'Gbm': 'F#m', 'Abm': 'G#m', 'Bbm': 'A#m',
    };
    aliases.forEach((alias, real) {
      final base = map[real];
      if (base != null) map[alias] = Chord(alias, base.frets, base.quality);
    });

    return map;
  }

  /// Look up a chord by name (returns null if unknown).
  static Chord? byName(String name) => _catalogue[name];

  /// All practiceable chords grouped by category, for the custom picker.
  static final Map<String, List<Chord>> grouped = {
    'Major': _majors.keys.map((n) => _catalogue[n]!).toList(),
    'Minor': _minors.keys.map((n) => _catalogue[n]!).toList(),
    'Dominant 7th': _dom7.keys.map((n) => _catalogue[n]!).toList(),
    'Major 7th': _maj7.keys.map((n) => _catalogue[n]!).toList(),
    'Minor 7th': _min7.keys.map((n) => _catalogue[n]!).toList(),
    'Diminished': _chromatic.map((n) => _catalogue['${n}dim']!).toList(),
  };

  /// The full "all chords" practice set (majors + minors + the common 7ths).
  /// Built once and cached so repeated reads during rebuilds are free.
  static final List<Chord> all = [
    ..._majors.keys,
    ..._minors.keys,
    ..._dom7.keys,
    ..._maj7.keys,
    ..._min7.keys,
  ].map((n) => _catalogue[n]!).toList();

  /// Diatonic chord names for each supported scale/key.
  static const Map<String, List<String>> scaleChordNames = {
    'C Major': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
    'G Major': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
    'D Major': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
    'A Major': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
    'E Major': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
    'F Major': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
    'Bb Major': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
    'A Minor': ['Am', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'],
    'E Minor': ['Em', 'F#dim', 'G', 'Am', 'Bm', 'C', 'D'],
    'D Minor': ['Dm', 'Edim', 'F', 'Gm', 'Am', 'Bb', 'C'],
    'B Minor': ['Bm', 'C#dim', 'D', 'Em', 'F#m', 'G', 'A'],
  };

  /// Resolve a scale name to its list of [Chord]s.
  static List<Chord> chordsForScale(String scale) =>
      (scaleChordNames[scale] ?? [])
          .map((n) => _catalogue[n])
          .whereType<Chord>()
          .toList();

  static final List<String> scaleNames = scaleChordNames.keys.toList();
}
