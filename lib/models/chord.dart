/// A guitar chord and its fretboard fingering.
///
/// [frets] holds exactly 6 entries ordered from the low E (6th) string to the
/// high E (1st) string. The values mean:
///   * `-1` -> string is muted (shown as an "x")
///   *  `0` -> open string (shown as an "o")
///   * `>0` -> press this fret number
class Chord {
  final String name;
  final List<int> frets;
  final String quality; // major, minor, dom7, maj7, min7, dim

  const Chord(this.name, this.frets, this.quality);

  @override
  bool operator ==(Object other) => other is Chord && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
