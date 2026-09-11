/// Internal domain models for a detected dart throw.
///
/// These model plain darts physics (which segment/ring was hit and the
/// resulting score). Game controllers depend on these — NOT on the Scolia
/// protocol DTOs — so Scolia wire details never leak into game logic.
library;

/// The ring of the dartboard that was hit.
enum DartRing {
  single,
  double,
  triple,
  outerBull, // 25
  innerBull, // 50
  miss, // no detection / bounceout
}

/// A single detected dart.
///
/// [segment] is the number wedge 1..20, or 25 for the bull, or 0 for a miss.
/// [value] is the resolved score for this dart (already accounts for the ring).
/// [x], [y] (mm from centre, ±250) and [angle] are optional Scolia extras,
/// carried through when available but not required by the game pipeline.
class DetectedThrow {
  final int segment;
  final DartRing ring;
  final int value;
  final double? x;
  final double? y;
  final double? angle;

  const DetectedThrow({
    required this.segment,
    required this.ring,
    required this.value,
    this.x,
    this.y,
    this.angle,
  });

  /// Derive [value] from [segment] and [ring].
  factory DetectedThrow.fromSegment(
    int segment,
    DartRing ring, {
    double? x,
    double? y,
    double? angle,
  }) {
    return DetectedThrow(
      segment: segment,
      ring: ring,
      value: _valueFor(segment, ring),
      x: x,
      y: y,
      angle: angle,
    );
  }

  /// A missed dart (bounce-out or "None" detection): value 0.
  factory DetectedThrow.miss() =>
      const DetectedThrow(segment: 0, ring: DartRing.miss, value: 0);

  static int _valueFor(int segment, DartRing ring) {
    switch (ring) {
      case DartRing.single:
        return segment;
      case DartRing.double:
        return segment * 2;
      case DartRing.triple:
        return segment * 3;
      case DartRing.outerBull:
        return 25;
      case DartRing.innerBull:
        return 50;
      case DartRing.miss:
        return 0;
    }
  }

  /// True if this dart hit the bull (inner or outer).
  bool get isBull => ring == DartRing.innerBull || ring == DartRing.outerBull;

  /// Human-readable sector label for display, e.g. "T20", "D16", "S10",
  /// "SB" (outer bull), "DB" (inner bull), "–" (miss).
  String get sectorLabel {
    switch (ring) {
      case DartRing.miss:
        return '–';
      case DartRing.outerBull:
        return 'SB';
      case DartRing.innerBull:
        return 'DB';
      case DartRing.single:
        return 'S$segment';
      case DartRing.double:
        return 'D$segment';
      case DartRing.triple:
        return 'T$segment';
    }
  }

  /// True if this dart is the double of [targetSegment].
  ///
  /// For the bull ([targetSegment] == 25), the inner bull (50) counts as the
  /// "double" — matching doubles-game rules such as Bob's 27.
  bool isDoubleOf(int targetSegment) {
    if (targetSegment == 25) {
      return ring == DartRing.innerBull;
    }
    return ring == DartRing.double && segment == targetSegment;
  }

  /// True if this dart hit [targetSegment] in any scoring ring, or the bull
  /// when [targetSegment] == 25.
  bool hits(int targetSegment) {
    if (targetSegment == 25) {
      return isBull;
    }
    return segment == targetSegment && ring != DartRing.miss;
  }

  @override
  String toString() =>
      'DetectedThrow(segment: $segment, ring: ${ring.name}, value: $value)';

  @override
  bool operator ==(Object other) =>
      other is DetectedThrow &&
      other.segment == segment &&
      other.ring == ring &&
      other.value == value;

  @override
  int get hashCode => Object.hash(segment, ring, value);
}

/// The result of one completed turn (up to three darts).
///
/// Exposes both the raw [darts] (for per-dart / interpreted-count games) and
/// the summed [total] (for score-value games like x01).
class TurnResult {
  final List<DetectedThrow> darts;

  const TurnResult(this.darts);

  /// Sum of all dart values in the turn.
  int get total => darts.fold(0, (sum, d) => sum + d.value);

  /// Number of darts thrown (0..3).
  int get dartCount => darts.length;

  @override
  String toString() => 'TurnResult(darts: $darts, total: $total)';
}
