import 'dart:math';

/// Standard dartboard ring radii in mm from the board centre. Shared by the
/// throw-log target geometry and the heatmap so both agree on where sectors
/// and rings sit.
class BoardGeometry {
  BoardGeometry._();

  static const double innerBullR = 6.35;
  static const double outerBullR = 15.9;
  static const double trebleInnerR = 99.0;
  static const double trebleOuterR = 107.0;
  static const double doubleInnerR = 162.0;
  static const double doubleOuterR = 170.0;

  /// Mid-radius of the treble ring band (centre of a treble target).
  static const double trebleMidR = (trebleInnerR + trebleOuterR) / 2;

  /// Mid-radius of the double ring band (centre of a double target).
  static const double doubleMidR = (doubleInnerR + doubleOuterR) / 2;

  /// Mid-radius of the large (outer) single band — between the treble ring and
  /// the double ring.
  static const double outerSingleMidR = (trebleOuterR + doubleInnerR) / 2;

  /// Mid-radius of the small (inner) single band — between the outer bull and
  /// the treble ring.
  static const double innerSingleMidR = (outerBullR + trebleInnerR) / 2;

  /// Board numbers in clockwise order starting at 20 (top).
  static const List<int> numbersClockwise = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17, //
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5
  ];

  /// Angle (radians, standard math convention: 0 = +x / 3 o'clock, CCW+) of a
  /// wedge [number]'s centre, with 20 at the top. Returns 0 for the bull.
  static double sectorAngle(int number) {
    final idx = numbersClockwise.indexOf(number);
    if (idx < 0) return 0;
    // 20 at top (+90°), each subsequent number 18° clockwise (negative).
    return (pi / 2) - idx * (2 * pi / 20);
  }
}

/// Which ring an intended target lies in.
enum TargetRing { single, innerSingle, double_, triple, innerBull, outerBull }

/// An intended aim point for a dart: the geometric centre of the sector/ring
/// the player was trying to hit. Null target = the player chose freely (e.g.
/// x01 scoring), in which case no accuracy is computed for that dart.
class DartTarget {
  /// Wedge number 1..20, or 25 for the bull. Ignored for bull rings.
  final int segment;

  /// The ring aimed at.
  final TargetRing ring;

  const DartTarget(this.segment, this.ring);

  /// Convenience constructors for the common cases.
  const DartTarget.triple(int segment) : this(segment, TargetRing.triple);
  const DartTarget.double_(int segment) : this(segment, TargetRing.double_);
  const DartTarget.outerSingle(int segment)
      : this(segment, TargetRing.single);
  const DartTarget.innerSingle(int segment)
      : this(segment, TargetRing.innerSingle);
  const DartTarget.bull() : this(25, TargetRing.innerBull);

  /// The target's centre point in mm from the board centre (x right, y up).
  Point<double> get center {
    switch (ring) {
      case TargetRing.innerBull:
        return const Point(0, 0);
      case TargetRing.outerBull:
        return const Point(0, 0);
      case TargetRing.triple:
        return _pointAt(BoardGeometry.trebleMidR, segment);
      case TargetRing.double_:
        return _pointAt(BoardGeometry.doubleMidR, segment);
      case TargetRing.single:
        return _pointAt(BoardGeometry.outerSingleMidR, segment);
      case TargetRing.innerSingle:
        return _pointAt(BoardGeometry.innerSingleMidR, segment);
    }
  }

  static Point<double> _pointAt(double radiusMm, int segment) {
    final a = BoardGeometry.sectorAngle(segment);
    return Point(radiusMm * cos(a), radiusMm * sin(a));
  }

  /// Approximate angular separation (in whole sectors, 0 = same wedge) between
  /// this target's wedge and [segment]. Bull targets return 0 (handled by
  /// distance instead). Used by the "≥2 sectors away ⇒ intentional" rule.
  int sectorsAwayFrom(int segment) {
    if (ring == TargetRing.innerBull || ring == TargetRing.outerBull) return 0;
    final a = BoardGeometry.numbersClockwise.indexOf(this.segment);
    final b = BoardGeometry.numbersClockwise.indexOf(segment);
    if (a < 0 || b < 0) return 99; // unknown ⇒ treat as far
    final diff = (a - b).abs();
    return min(diff, 20 - diff); // wrap-around distance on the 20-wedge ring
  }

  String get ringName {
    switch (ring) {
      case TargetRing.single:
        return 'single';
      case TargetRing.innerSingle:
        return 'innerSingle';
      case TargetRing.double_:
        return 'double';
      case TargetRing.triple:
        return 'triple';
      case TargetRing.innerBull:
        return 'innerBull';
      case TargetRing.outerBull:
        return 'outerBull';
    }
  }

  Map<String, dynamic> toJson() => {'s': segment, 'r': ringName};

  static DartTarget? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final seg = (json['s'] as num?)?.toInt();
    final r = json['r'] as String?;
    if (seg == null || r == null) return null;
    final ring = switch (r) {
      'single' => TargetRing.single,
      'innerSingle' => TargetRing.innerSingle,
      'double' => TargetRing.double_,
      'triple' => TargetRing.triple,
      'innerBull' => TargetRing.innerBull,
      'outerBull' => TargetRing.outerBull,
      _ => null,
    };
    if (ring == null) return null;
    return DartTarget(seg, ring);
  }

  /// The unambiguous double-finish aim point for a checkout [remaining], or
  /// null when the finish is not a direct double (so the player's intended
  /// double can't be inferred and no target is assigned).
  ///
  /// Even scores 2..40 → the matching double (`D(remaining/2)`); 50 → the bull.
  static DartTarget? doubleTargetForRemaining(int remaining) {
    if (remaining == 50) return const DartTarget.bull();
    if (remaining >= 2 && remaining <= 40 && remaining.isEven) {
      return DartTarget.double_(remaining ~/ 2);
    }
    return null;
  }
}
