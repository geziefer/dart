import 'dart:async';

import 'package:dart/scolia/mock_scolia_source.dart';
import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A fake WebSocketChannel backed by in-memory controllers, so we can drive the
/// client with real-format JSON frames and observe what it sends. Only the
/// members [ScoliaConnection] actually uses (stream, sink) are implemented;
/// the rest fall through [noSuchMethod] (never exercised by the client).
class FakeWebSocketChannel implements WebSocketChannel {
  final _incoming = StreamController<dynamic>.broadcast();
  final _outgoing = <dynamic>[];

  void serverSend(String frame) => _incoming.add(frame);
  List<dynamic> get sent => _outgoing;

  @override
  Stream get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _FakeSink(_outgoing, _incoming);

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._outgoing, this._incoming);
  final List<dynamic> _outgoing;
  final StreamController<dynamic> _incoming;

  @override
  void add(dynamic data) => _outgoing.add(data);
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_incoming.isClosed) await _incoming.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('MockScoliaSource', () {
    late MockScoliaSource mock;
    setUp(() => mock = MockScoliaSource());
    tearDown(() => mock.dispose());

    test('connect emits HELLO_CLIENT with Ready status', () async {
      final messages = <ScoliaMessage>[];
      mock.messages.listen(messages.add);
      await mock.connect();
      await Future.delayed(Duration.zero);
      expect(messages.whereType<HelloClientMessage>(), hasLength(1));
      expect(mock.currentStatus, BoardStatus.ready);
    });

    test('throwSector emits parsed THROW_DETECTED', () async {
      final throws = <ThrowDetectedMessage>[];
      mock.messages
          .where((m) => m is ThrowDetectedMessage)
          .cast<ThrowDetectedMessage>()
          .listen(throws.add);
      mock.throwSector('T20');
      await Future.delayed(Duration.zero);
      expect(throws, hasLength(1));
      expect(throws.first.detectedThrow.value, 60);
    });

    test('playRound emits three throws + takeout', () async {
      final msgs = <ScoliaMessage>[];
      mock.messages.listen(msgs.add);
      mock.playRound(['T20', 'T20', 'T20']);
      await Future.delayed(Duration.zero);
      expect(msgs.whereType<ThrowDetectedMessage>(), hasLength(3));
      expect(msgs.whereType<TakeoutFinishedMessage>(), hasLength(1));
    });
  });

  group('ScoliaConnection', () {
    test('builds correct connect URI with auth params', () {
      final conn = ScoliaConnection(
        serialNumber: 'SN123',
        accessToken: 'TOK',
        channelFactory: (_) => FakeWebSocketChannel(),
      );
      final uri = conn.connectUri;
      expect(uri.queryParameters['serialNumber'], 'SN123');
      expect(uri.queryParameters['accessToken'], 'TOK');
      expect(uri.queryParameters.containsKey('forceConnect'), isFalse);
      conn.dispose();
    });

    test('sends CONFIGURE_SBC disable-forward on connect', () async {
      final fake = FakeWebSocketChannel();
      final conn = ScoliaConnection(
        serialNumber: 'SN',
        accessToken: 'T',
        channelFactory: (_) => fake,
      );
      await conn.connect();
      expect(fake.sent, hasLength(1));
      expect(fake.sent.first, contains('"type":"CONFIGURE_SBC"'));
      expect(fake.sent.first, contains('"enableMessageForwardToScolia":false'));
      conn.dispose();
    });

    test('parses incoming real-format frames into typed messages', () async {
      final fake = FakeWebSocketChannel();
      final conn = ScoliaConnection(
        serialNumber: 'SN',
        accessToken: 'T',
        channelFactory: (_) => fake,
      );
      final received = <ScoliaMessage>[];
      conn.messages.listen(received.add);
      await conn.connect();

      fake.serverSend(
          '{"type":"HELLO_CLIENT","id":"1","payload":{"boardStatus":"Ready","boardPhase":"Throw","errorType":null}}');
      fake.serverSend(
          '{"type":"THROW_DETECTED","id":"2","payload":{"sector":"T20","bounceout":false}}');
      fake.serverSend(
          '{"type":"TAKEOUT_FINISHED","id":"3","payload":{"falseTakeout":false}}');
      await Future.delayed(Duration.zero);

      expect(received.whereType<HelloClientMessage>(), hasLength(1));
      expect(received.whereType<ThrowDetectedMessage>(), hasLength(1));
      expect(received.whereType<TakeoutFinishedMessage>(), hasLength(1));
      expect(conn.currentStatus, BoardStatus.ready);
      conn.dispose();
    });

    test('forceConnect adds query param', () {
      final conn = ScoliaConnection(
        serialNumber: 'SN',
        accessToken: 'T',
        forceConnect: true,
        channelFactory: (_) => FakeWebSocketChannel(),
      );
      expect(conn.connectUri.queryParameters['forceConnect'], 'true');
      conn.dispose();
    });
  });
}
