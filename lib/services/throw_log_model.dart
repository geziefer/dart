import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/services/dart_target.dart';

/// Persisted record of a single dart within a logged session.
///
/// Mirrors the useful fields of [DetectedThrow] in a compact, storage-friendly
/// shape. Spatial fields ([x], [y], [angle]) are only present for Scolia-driven
/// throws (the camera board reports landing coordinates); numpad throws carry
/// scoring data only. [target] is the intended aim point when the game defines
/// one for this dart (null when the player chose freely).
///
/// JSON uses short keys to keep the on-disk/in-`localStorage` size small
/// (see the A0 sizing notes in the training-enhancements plan).
class LoggedDart {
  /// Number wedge 1..20, 25 for the bull, or 0 for a miss.
  final int segment;

  /// Ring hit, stored as [DartRing.name] (e.g. 'single', 'triple').
  final String ring;

  /// Resolved score for this dart (already accounts for the ring).
  final int value;

  /// Landing coordinates in mm from board centre (±250) and angle in degrees,
  /// when provided by Scolia. Null for numpad throws or when unavailable.
  final double? x;
  final double? y;
  final double? angle;

  /// For singles: true = outer/big single, false = inner/small single.
  final bool isOuterSingle;

  /// Intended aim point for this dart, or null when the game sets no target
  /// (free-choice phases such as x01 scoring).
  final DartTarget? target;

  const LoggedDart({
    required this.segment,
    required this.ring,
    required this.value,
    this.x,
    this.y,
    this.angle,
    this.isOuterSingle = true,
    this.target,
  });

  /// Build from a live [DetectedThrow], optionally with an intended [target].
  factory LoggedDart.fromDetected(DetectedThrow t, {DartTarget? target}) =>
      LoggedDart(
        segment: t.segment,
        ring: t.ring.name,
        value: t.value,
        x: t.x,
        y: t.y,
        angle: t.angle,
        isOuterSingle: t.isOuterSingle,
        target: target,
      );

  /// Whether this dart carries board landing coordinates (Scolia only).
  bool get hasCoordinates => x != null && y != null;

  /// The [DartRing] this record represents (falls back to miss on bad data).
  DartRing get ringEnum => DartRing.values.firstWhere(
        (r) => r.name == ring,
        orElse: () => DartRing.miss,
      );

  Map<String, dynamic> toJson() => {
        's': segment,
        'r': ring,
        'v': value,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (angle != null) 'a': angle,
        // Only store the single-size flag when it is meaningful (singles) and
        // non-default, to keep records compact.
        if (ring == 'single' && !isOuterSingle) 'o': false,
        if (target != null) 'tg': target!.toJson(),
      };

  factory LoggedDart.fromJson(Map<String, dynamic> json) => LoggedDart(
        segment: (json['s'] as num?)?.toInt() ?? 0,
        ring: json['r'] as String? ?? 'miss',
        value: (json['v'] as num?)?.toInt() ?? 0,
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
        angle: (json['a'] as num?)?.toDouble(),
        isOuterSingle: json['o'] as bool? ?? true,
        target: DartTarget.fromJson(
            (json['tg'] as Map?)?.cast<String, dynamic>()),
      );
}

/// A logged training session: all darts thrown in one game, with metadata.
///
/// One session is the unit of persistence — it is written once when the game
/// ends, never per dart.
class ThrowSession {
  /// Storage container id of the game played (the MenuItem id, e.g. 'CR').
  final String gameId;

  /// When the session was played (session start/end; day-resolution is enough
  /// for analytics but we keep full precision).
  final DateTime date;

  /// Whether the darts were captured from the Scolia board (true) or the
  /// numpad (false). Scolia sessions carry spatial coordinates.
  final bool fromScolia;

  /// All darts thrown in the session, in order.
  final List<LoggedDart> darts;

  const ThrowSession({
    required this.gameId,
    required this.date,
    required this.fromScolia,
    required this.darts,
  });

  /// True when at least one dart carries landing coordinates.
  bool get hasCoordinates => darts.any((d) => d.hasCoordinates);

  Map<String, dynamic> toJson() => {
        'g': gameId,
        'd': date.toIso8601String(),
        if (fromScolia) 'sc': true,
        't': darts.map((d) => d.toJson()).toList(),
      };

  factory ThrowSession.fromJson(Map<String, dynamic> json) => ThrowSession(
        gameId: json['g'] as String? ?? '',
        date: DateTime.tryParse(json['d'] as String? ?? '') ?? DateTime.now(),
        fromScolia: json['sc'] as bool? ?? false,
        darts: (json['t'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => LoggedDart.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
