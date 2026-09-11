/// Real Scolia External API v1.4 WebSocket client.
///
/// Validated against Scolia Home 2 hardware. Connects to
/// `wss://game.scoliadarts.com/api/v1/external` with the board serial number
/// and access token as query parameters (§2.2, §4.1), parses incoming frames
/// via [ScoliaMessage.parse], and on connect sends CONFIGURE_SBC to disable
/// message forwarding to the Scolia app (so throws never create phantom games).
library;

import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:dart/scolia/protocol/board_state.dart';
import 'package:dart/scolia/protocol/message.dart';
import 'package:dart/scolia/scolia_event_source.dart';

/// Signature for creating a [WebSocketChannel] from a URL. Injectable so tests
/// can supply a fake channel instead of opening a real socket.
typedef ChannelFactory = WebSocketChannel Function(Uri url);

WebSocketChannel _defaultChannelFactory(Uri url) =>
    WebSocketChannel.connect(url);

class ScoliaConnection implements ScoliaEventSource {
  ScoliaConnection({
    required this.serialNumber,
    required this.accessToken,
    this.baseUrl = 'wss://game.scoliadarts.com/api/v1/external',
    this.forceConnect = false,
    this.disableForwarding = true,
    ChannelFactory channelFactory = _defaultChannelFactory,
  }) : _channelFactory = channelFactory;

  final String serialNumber;
  final String accessToken;
  final String baseUrl;
  final bool forceConnect;

  /// When true (default), send CONFIGURE_SBC { enableMessageForwardToScolia:
  /// false } right after the connection opens.
  final bool disableForwarding;

  final ChannelFactory _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  final _messageController = StreamController<ScoliaMessage>.broadcast();
  final _statusController = StreamController<BoardStatus>.broadcast();
  final _connController = StreamController<ScoliaConnectionState>.broadcast();

  BoardStatus _currentStatus = BoardStatus.offline;

  @override
  Stream<ScoliaMessage> get messages => _messageController.stream;
  @override
  Stream<BoardStatus> get status => _statusController.stream;
  @override
  Stream<ScoliaConnectionState> get connectionState => _connController.stream;
  @override
  BoardStatus get currentStatus => _currentStatus;

  /// Last connection error message, exposed for diagnostics in the Monitor.
  String? lastError;

  /// The full connection URL with auth query parameters.
  Uri get connectUri => Uri.parse(baseUrl).replace(queryParameters: {
        'serialNumber': serialNumber,
        'accessToken': accessToken,
        if (forceConnect) 'forceConnect': 'true',
      });

  @override
  Future<void> connect() async {
    _connController.add(ScoliaConnectionState.connecting);
    lastError = null;
    try {
      final channel = _channelFactory(connectUri);
      _channel = channel;

      // Await ready so auth errors (close codes 4100/4102) surface immediately.
      await channel.ready;

      _sub = channel.stream.listen(
        _onFrame,
        onError: (Object e) {
          lastError = e.toString();
          _connController.add(ScoliaConnectionState.error);
        },
        onDone: () {
          final code = channel.closeCode;
          final reason = channel.closeReason;
          if (code != null && code >= 4000) {
            lastError = 'Closed: code=$code reason=$reason';
            _connController.add(ScoliaConnectionState.error);
          } else {
            _connController.add(ScoliaConnectionState.disconnected);
          }
        },
      );
      _connController.add(ScoliaConnectionState.connected);
      if (disableForwarding) {
        send(ScoliaOutgoing.configureSbc(enableMessageForwardToScolia: false));
      }
    } catch (e) {
      lastError = e.toString();
      _connController.add(ScoliaConnectionState.error);
    }
  }

  /// Send a raw frame string to the board and log it.
  void send(String frame) {
    _channel?.sink.add(frame);
    // Echo outgoing messages as a synthetic "sent" message through the stream
    // so the Monitor can log them.
    _messageController.add(SentMessage(frame));
  }

  void _onFrame(dynamic data) {
    if (data is! String) return;
    final msg = ScoliaMessage.parse(data);
    if (msg is HelloClientMessage) {
      _updateStatus(msg.status);
    } else if (msg is SbcStatusMessage) {
      _updateStatus(msg.status);
    }
    _messageController.add(msg);
  }

  void _updateStatus(BoardStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _connController.add(ScoliaConnectionState.disconnected);
  }

  void dispose() {
    _messageController.close();
    _statusController.close();
    _connController.close();
  }
}
