import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  String? _url;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String url) async {
    _url = url;
    _reconnectAttempts = 0;
    await _doConnect(url);
  }

  Future<void> _doConnect(String url) async {
    try {
      disconnect(permanent: false);

      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _isConnected = true;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            _controller.add(decoded);
          } catch (e) {
            debugPrint('WsClient: Failed to decode message: $e');
          }
        },
        onError: (Object error) {
          debugPrint('WsClient: Error: $error');
          _isConnected = false;
          _attemptReconnect();
        },
        onDone: () {
          debugPrint('WsClient: Connection closed');
          _isConnected = false;
          _attemptReconnect();
        },
      );
    } catch (e) {
      debugPrint('WsClient: Connection failed: $e');
      _isConnected = false;
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_url == null || _reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    debugPrint(
        'WsClient: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_url != null) {
        _doConnect(_url!);
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void disconnect({bool permanent = true}) {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    if (permanent) {
      _url = null;
      _reconnectAttempts = _maxReconnectAttempts;
    }
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}
