/// Scolia SBC status and phase, matching External API v1.4 (§3.1).
///
/// The SBC is characterized by a [BoardStatus] (operational state) and, only
/// when [BoardStatus.ready], a [BoardPhase] (throw vs. takeout). The phase is
/// `null` in any non-Ready status.
library;

/// Operational state of the Single Board Computer (SBC).
enum BoardStatus {
  offline,
  updating,
  initializing,
  calibrating,
  ready,
  error;

  /// Parse the spec's capitalized status string (e.g. "Ready", "Calibrating").
  /// Returns [BoardStatus.offline] for unknown/absent values (safe default:
  /// treat anything we don't understand as not usable for input).
  static BoardStatus fromString(String? value) {
    switch (value) {
      case 'Offline':
        return BoardStatus.offline;
      case 'Updating':
        return BoardStatus.updating;
      case 'Initializing':
        return BoardStatus.initializing;
      case 'Calibrating':
        return BoardStatus.calibrating;
      case 'Ready':
        return BoardStatus.ready;
      case 'Error':
        return BoardStatus.error;
      default:
        return BoardStatus.offline;
    }
  }

  /// True when the board can detect and forward throws.
  bool get canDetectThrows => this == BoardStatus.ready;
}

/// Condition affecting detectable game events. Only meaningful when the status
/// is [BoardStatus.ready]; otherwise `null`.
enum BoardPhase {
  /// Detecting throws and forwarding them.
  throwing,

  /// A takeout (dart removal) is in progress; no throws detected meanwhile.
  takeout;

  /// Parse the spec's status string ("Throw" / "Takeout"). Returns `null` for
  /// null/unknown values (matching the spec: phase is null outside Ready).
  static BoardPhase? fromString(String? value) {
    switch (value) {
      case 'Throw':
        return BoardPhase.throwing;
      case 'Takeout':
        return BoardPhase.takeout;
      default:
        return null;
    }
  }
}
