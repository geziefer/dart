import 'package:dart/scolia/models/detected_throw.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/protocol/sector_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardStatus.fromString', () {
    test('parses all spec values', () {
      expect(BoardStatus.fromString('Offline'), BoardStatus.offline);
      expect(BoardStatus.fromString('Updating'), BoardStatus.updating);
      expect(BoardStatus.fromString('Initializing'), BoardStatus.initializing);
      expect(BoardStatus.fromString('Calibrating'), BoardStatus.calibrating);
      expect(BoardStatus.fromString('Ready'), BoardStatus.ready);
      expect(BoardStatus.fromString('Error'), BoardStatus.error);
    });

    test('unknown/null defaults to offline', () {
      expect(BoardStatus.fromString(null), BoardStatus.offline);
      expect(BoardStatus.fromString('Bogus'), BoardStatus.offline);
    });

    test('only ready can detect throws', () {
      expect(BoardStatus.ready.canDetectThrows, isTrue);
      expect(BoardStatus.calibrating.canDetectThrows, isFalse);
      expect(BoardStatus.offline.canDetectThrows, isFalse);
    });
  });

  group('BoardPhase.fromString', () {
    test('parses Throw and Takeout', () {
      expect(BoardPhase.fromString('Throw'), BoardPhase.throwing);
      expect(BoardPhase.fromString('Takeout'), BoardPhase.takeout);
    });
    test('null/unknown -> null', () {
      expect(BoardPhase.fromString(null), isNull);
      expect(BoardPhase.fromString('Whatever'), isNull);
    });
  });

  group('SectorParser', () {
    test('outer single S = segment x1', () {
      final t = SectorParser.parse('S20');
      expect(t.segment, 20);
      expect(t.ring, DartRing.single);
      expect(t.value, 20);
    });

    test('inner single s also = segment x1', () {
      final t = SectorParser.parse('s7');
      expect(t.segment, 7);
      expect(t.ring, DartRing.single);
      expect(t.value, 7);
    });

    test('double', () {
      final t = SectorParser.parse('D16');
      expect(t.ring, DartRing.double);
      expect(t.value, 32);
    });

    test('triple', () {
      final t = SectorParser.parse('T20');
      expect(t.ring, DartRing.triple);
      expect(t.value, 60);
    });

    test('outer bull 25', () {
      final t = SectorParser.parse('25');
      expect(t.segment, 25);
      expect(t.ring, DartRing.outerBull);
      expect(t.value, 25);
      expect(t.isBull, isTrue);
    });

    test('inner bull Bull = 50', () {
      final t = SectorParser.parse('Bull');
      expect(t.segment, 25);
      expect(t.ring, DartRing.innerBull);
      expect(t.value, 50);
      expect(t.isBull, isTrue);
    });

    test('None -> miss', () {
      final t = SectorParser.parse('None');
      expect(t.ring, DartRing.miss);
      expect(t.value, 0);
    });

    test('bounceout forces miss regardless of sector', () {
      final t = SectorParser.parse('T20', bounceout: true);
      expect(t.ring, DartRing.miss);
      expect(t.value, 0);
    });

    test('null and malformed -> miss (never throws)', () {
      expect(SectorParser.parse(null).ring, DartRing.miss);
      expect(SectorParser.parse('garbage').ring, DartRing.miss);
      expect(SectorParser.parse('T21').ring, DartRing.miss); // out of range
      expect(SectorParser.parse('X5').ring, DartRing.miss);
    });

    test('single-digit segments 1-9 parse', () {
      expect(SectorParser.parse('S1').value, 1);
      expect(SectorParser.parse('T9').value, 27);
    });

    test('carries coordinates and angle through', () {
      final t = SectorParser.parse('S1', x: 40, y: 138, angle: 82.1);
      expect(t.x, 40);
      expect(t.y, 138);
      expect(t.angle, 82.1);
    });
  });

  group('DetectedThrow helpers', () {
    test('isDoubleOf for a number', () {
      expect(SectorParser.parse('D16').isDoubleOf(16), isTrue);
      expect(SectorParser.parse('S16').isDoubleOf(16), isFalse);
      expect(SectorParser.parse('D16').isDoubleOf(17), isFalse);
    });

    test('isDoubleOf for bull uses inner bull', () {
      expect(SectorParser.parse('Bull').isDoubleOf(25), isTrue);
      expect(SectorParser.parse('25').isDoubleOf(25), isFalse);
    });

    test('hits any ring / bull', () {
      expect(SectorParser.parse('T20').hits(20), isTrue);
      expect(SectorParser.parse('S20').hits(20), isTrue);
      expect(SectorParser.parse('T19').hits(20), isFalse);
      expect(SectorParser.parse('25').hits(25), isTrue);
      expect(SectorParser.parse('Bull').hits(25), isTrue);
    });
  });

  group('TurnResult', () {
    test('total sums dart values', () {
      final turn = TurnResult([
        SectorParser.parse('T20'),
        SectorParser.parse('T20'),
        SectorParser.parse('T20'),
      ]);
      expect(turn.total, 180);
      expect(turn.dartCount, 3);
    });
  });

  group('ScoliaMessage.parse', () {
    test('HELLO_CLIENT', () {
      final m = ScoliaMessage.parse(
          '{"type":"HELLO_CLIENT","id":"a","payload":{"boardStatus":"Ready","boardPhase":"Throw","errorType":null}}');
      expect(m, isA<HelloClientMessage>());
      m as HelloClientMessage;
      expect(m.status, BoardStatus.ready);
      expect(m.phase, BoardPhase.throwing);
    });

    test('THROW_DETECTED parses sector + suggestions', () {
      final m = ScoliaMessage.parse(
          '{"type":"THROW_DETECTED","id":"b","payload":{"sector":"T20","coordinates":[40,138],"angle":{"vertical":82.1,"horizontal":89.0},"bounceout":false,"sectorSuggestions":["S20","T20","T1"]}}');
      expect(m, isA<ThrowDetectedMessage>());
      m as ThrowDetectedMessage;
      expect(m.detectedThrow.value, 60);
      expect(m.detectedThrow.x, 40);
      expect(m.sectorSuggestions, ['S20', 'T20', 'T1']);
    });

    test('THROW_DETECTED with bounceout -> miss', () {
      final m = ScoliaMessage.parse(
              '{"type":"THROW_DETECTED","id":"c","payload":{"sector":"T20","bounceout":true}}')
          as ThrowDetectedMessage;
      expect(m.detectedThrow.value, 0);
      expect(m.detectedThrow.ring, DartRing.miss);
    });

    test('TAKEOUT_FINISHED falseTakeout flag', () {
      final m = ScoliaMessage.parse(
              '{"type":"TAKEOUT_FINISHED","id":"d","payload":{"falseTakeout":true}}')
          as TakeoutFinishedMessage;
      expect(m.falseTakeout, isTrue);
    });

    test('TAKEOUT_STARTED', () {
      expect(ScoliaMessage.parse('{"type":"TAKEOUT_STARTED","id":"e"}'),
          isA<TakeoutStartedMessage>());
    });

    test('SBC_STATUS_CHANGED', () {
      final m = ScoliaMessage.parse(
          '{"type":"SBC_STATUS_CHANGED","id":"f","payload":{"boardStatus":"Calibrating","boardPhase":null,"errorType":null}}');
      expect((m as SbcStatusMessage).status, BoardStatus.calibrating);
      expect(m.phase, isNull);
    });

    test('REFUSED carries error info', () {
      final m = ScoliaMessage.parse(
              '{"type":"REFUSED","id":"g","payload":{"replyTo":"x","error":"E","errorMessage":"msg"}}')
          as RefusedMessage;
      expect(m.replyTo, 'x');
      expect(m.error, 'E');
    });

    test('unknown type -> UnknownMessage', () {
      final m = ScoliaMessage.parse('{"type":"WEIRD","id":"h"}');
      expect(m, isA<UnknownMessage>());
      expect((m as UnknownMessage).type, 'WEIRD');
    });

    test('unparseable -> UnknownMessage (no throw)', () {
      expect(ScoliaMessage.parse('not json'), isA<UnknownMessage>());
    });
  });

  group('ScoliaOutgoing', () {
    test('configureSbc builds valid frame with uuid', () {
      final frame = ScoliaOutgoing.configureSbc(
          enableMessageForwardToScolia: false);
      expect(frame, contains('"type":"CONFIGURE_SBC"'));
      expect(frame, contains('"enableMessageForwardToScolia":false'));
    });

    test('generateUuidV4 has correct v4 shape', () {
      final u = generateUuidV4();
      expect(
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
              .hasMatch(u),
          isTrue);
    });
  });
}
