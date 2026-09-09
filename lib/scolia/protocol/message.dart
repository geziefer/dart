/// Scolia External API v1.4 WebSocket message envelope and typed messages.
///
/// Envelope (§4.1): `{ "type": "UPPER_SNAKE", "id": "uuid-v4", "payload": {...} }`.
///
/// We parse the incoming messages we care about into typed classes, and build
/// the single outgoing message we send: CONFIGURE_SBC (disable forwarding).
library;

import 'dart:convert';
import 'dart:math';

import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';

/// Base type for all parsed incoming messages.
sealed class ScoliaMessage {
  final String? id;
  const ScoliaMessage(this.id);

  /// Parse a raw JSON frame into a typed message.
  /// Unknown/unhandled types become [UnknownMessage] (never throws).
  static ScoliaMessage parse(String raw) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return const UnknownMessage(null, '<unparseable>');
    }
    final type = json['type'] as String?;
    final id = json['id'] as String?;
    final payload = (json['payload'] as Map<String, dynamic>?) ?? const {};

    switch (type) {
      case 'HELLO_CLIENT':
        return HelloClientMessage(
          id,
          status: BoardStatus.fromString(payload['boardStatus'] as String?),
          phase: BoardPhase.fromString(payload['boardPhase'] as String?),
          errorType: payload['errorType'] as String?,
        );
      case 'SBC_STATUS':
      case 'SBC_STATUS_CHANGED':
        return SbcStatusMessage(
          id,
          status: BoardStatus.fromString(payload['boardStatus'] as String?),
          phase: BoardPhase.fromString(payload['boardPhase'] as String?),
          errorType: payload['errorType'] as String?,
        );
      case 'THROW_DETECTED':
        return ThrowDetectedMessage(
          id,
          detectedThrow: _parseThrow(payload),
          sector: payload['sector'] as String?,
          sectorSuggestions:
              (payload['sectorSuggestions'] as List?)?.cast<String>() ??
                  const [],
        );
      case 'TAKEOUT_STARTED':
        return TakeoutStartedMessage(id);
      case 'TAKEOUT_FINISHED':
        return TakeoutFinishedMessage(
          id,
          falseTakeout: (payload['falseTakeout'] as bool?) ?? false,
        );
      case 'ACKNOWLEDGED':
        return AcknowledgedMessage(id, replyTo: payload['replyTo'] as String?);
      case 'REFUSED':
        return RefusedMessage(
          id,
          replyTo: payload['replyTo'] as String?,
          error: payload['error'] as String?,
          errorMessage: payload['errorMessage'] as String?,
        );
      case 'SBC_BOARD_AVAILABILITY_CHANGED':
        return BoardAvailabilityMessage(
          id,
          available: payload['availabilityState'] == 'available',
        );
      default:
        return UnknownMessage(id, type ?? '<null>');
    }
  }

  static DetectedThrow _parseThrow(Map<String, dynamic> payload) {
    final coords = (payload['coordinates'] as List?)?.cast<num>();
    final angle = payload['angle'] as Map<String, dynamic>?;
    return SectorParser.parse(
      payload['sector'] as String?,
      bounceout: (payload['bounceout'] as bool?) ?? false,
      x: coords != null && coords.length >= 2 ? coords[0].toDouble() : null,
      y: coords != null && coords.length >= 2 ? coords[1].toDouble() : null,
      angle: angle?['vertical'] is num
          ? (angle!['vertical'] as num).toDouble()
          : null,
    );
  }
}

class HelloClientMessage extends ScoliaMessage {
  final BoardStatus status;
  final BoardPhase? phase;
  final String? errorType;
  const HelloClientMessage(super.id,
      {required this.status, this.phase, this.errorType});
}

class SbcStatusMessage extends ScoliaMessage {
  final BoardStatus status;
  final BoardPhase? phase;
  final String? errorType;
  const SbcStatusMessage(super.id,
      {required this.status, this.phase, this.errorType});
}

class ThrowDetectedMessage extends ScoliaMessage {
  final DetectedThrow detectedThrow;
  final String? sector;
  final List<String> sectorSuggestions;
  const ThrowDetectedMessage(super.id,
      {required this.detectedThrow,
      this.sector,
      this.sectorSuggestions = const []});
}

class TakeoutStartedMessage extends ScoliaMessage {
  const TakeoutStartedMessage(super.id);
}

class TakeoutFinishedMessage extends ScoliaMessage {
  final bool falseTakeout;
  const TakeoutFinishedMessage(super.id, {required this.falseTakeout});
}

class AcknowledgedMessage extends ScoliaMessage {
  final String? replyTo;
  const AcknowledgedMessage(super.id, {this.replyTo});
}

class RefusedMessage extends ScoliaMessage {
  final String? replyTo;
  final String? error;
  final String? errorMessage;
  const RefusedMessage(super.id, {this.replyTo, this.error, this.errorMessage});
}

class BoardAvailabilityMessage extends ScoliaMessage {
  final bool available;
  const BoardAvailabilityMessage(super.id, {required this.available});
}

class UnknownMessage extends ScoliaMessage {
  final String type;
  const UnknownMessage(super.id, this.type);
}

/// Builders for outgoing messages. We only send CONFIGURE_SBC.
class ScoliaOutgoing {
  ScoliaOutgoing._();

  /// Build a CONFIGURE_SBC frame (§4.2.7) to enable/disable message forwarding
  /// to the Scolia app/cloud. We always send `enable: false` on connect so our
  /// throws never create phantom games in the Scolia account.
  static String configureSbc({required bool enableMessageForwardToScolia}) {
    return jsonEncode({
      'type': 'CONFIGURE_SBC',
      'id': generateUuidV4(),
      'payload': {
        'enableMessageForwardToScolia': enableMessageForwardToScolia,
      },
    });
  }

  /// Build a GET_SBC_STATUS frame (§4.2.1).
  static String getSbcStatus() {
    return jsonEncode({'type': 'GET_SBC_STATUS', 'id': generateUuidV4()});
  }
}

final Random _rng = Random();

/// Generate a RFC 4122 version-4 UUID without an external dependency.
String generateUuidV4() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).toList();
  return '${h[0]}${h[1]}${h[2]}${h[3]}-${h[4]}${h[5]}-${h[6]}${h[7]}-'
      '${h[8]}${h[9]}-${h[10]}${h[11]}${h[12]}${h[13]}${h[14]}${h[15]}';
}
