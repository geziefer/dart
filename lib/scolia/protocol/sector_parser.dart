/// Parser for the Scolia `THROW_DETECTED.payload.sector` string
/// (External API v1.4, §4.3.4).
///
/// Grammar (regex from the spec):
///   /(([SsDT])(20|1[0-9]|[1-9]))|25|Bull|None/
///
/// - `S` / `s` : single. Both map to segment × 1. `s` = inner single (between
///   the trebles ring and the 25/Bull area), `S` = outer single (between the
///   doubles ring and the trebles ring). The score is identical; the distinction
///   is only positional, so both become [DartRing.single].
/// - `D` : double (segment × 2)
/// - `T` : triple (segment × 3)
/// - `25` : outer bull (25)
/// - `Bull` : inner bull (50)
/// - `None` : no interpretable detection → miss (value 0)
library;

import 'package:dart/scolia/models/detected_throw.dart';

class SectorParser {
  SectorParser._();

  static final RegExp _pattern =
      RegExp(r'^(?:([SsDT])(20|1[0-9]|[1-9])|25|Bull|None)$');

  /// Parse a sector string into a [DetectedThrow].
  ///
  /// [bounceout] (from the same payload) forces a miss regardless of sector.
  /// Optional [x], [y], [angle] are carried through onto the throw.
  ///
  /// Returns a [DetectedThrow.miss] for `"None"`, a bounceout, or any string
  /// that does not match the grammar (defensive: never throws on bad input).
  static DetectedThrow parse(
    String? sector, {
    bool bounceout = false,
    double? x,
    double? y,
    double? angle,
  }) {
    if (bounceout) return DetectedThrow.miss();
    if (sector == null) return DetectedThrow.miss();

    final match = _pattern.firstMatch(sector);
    if (match == null) return DetectedThrow.miss();

    // Bull / 25 / None have no capture groups.
    if (sector == 'None') return DetectedThrow.miss();
    if (sector == '25') {
      return DetectedThrow.fromSegment(25, DartRing.outerBull,
          x: x, y: y, angle: angle);
    }
    if (sector == 'Bull') {
      return DetectedThrow.fromSegment(25, DartRing.innerBull,
          x: x, y: y, angle: angle);
    }

    final ringChar = match.group(1)!;
    final segment = int.parse(match.group(2)!);
    final ring = _ringFor(ringChar);
    return DetectedThrow.fromSegment(segment, ring,
        x: x, y: y, angle: angle,
        isOuterSingle: ringChar != 's'); // 's' = inner/small, 'S' = outer/big
  }

  static DartRing _ringFor(String ringChar) {
    switch (ringChar) {
      case 'S':
      case 's':
        return DartRing.single;
      case 'D':
        return DartRing.double;
      case 'T':
        return DartRing.triple;
      default:
        // Unreachable given the regex, but keep total.
        return DartRing.miss;
    }
  }
}
