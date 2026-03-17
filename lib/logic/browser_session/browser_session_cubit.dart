import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/api_constants.dart';
import 'browser_session_state.dart';

class BrowserSessionCubit extends Cubit<BrowserSessionState> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  BrowserSessionCubit() : super(const BrowserSessionState());

  void connect(String runId, {String? loginUrl}) {
    emit(state.copyWith(status: BrowserSessionStatus.connecting, clearError: true));

    try {
      final uri = Uri.parse(ApiConstants.wsBrowser(runId));
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (error) {
          emit(state.copyWith(
            status: BrowserSessionStatus.error,
            errorMessage: error.toString(),
          ));
        },
        onDone: () {
          if (state.status != BrowserSessionStatus.done &&
              state.status != BrowserSessionStatus.error) {
            emit(state.copyWith(status: BrowserSessionStatus.done));
          }
        },
      );

      emit(state.copyWith(status: BrowserSessionStatus.connected));
    } catch (e) {
      emit(state.copyWith(
        status: BrowserSessionStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'frame':
          final base64Data = data['data'] as String;
          final bytes = base64Decode(base64Data);
          final url = data['url'] as String? ?? state.currentUrl;
          emit(state.copyWith(
            currentFrame: Uint8List.fromList(bytes),
            currentUrl: url,
          ));
        case 'session_complete':
          final cookieCount = (data['cookie_count'] as num?)?.toInt() ?? 0;
          emit(state.copyWith(
            status: BrowserSessionStatus.done,
            cookieCount: cookieCount,
          ));
        case 'error':
          final msg = data['message'] as String? ?? 'Unknown error';
          emit(state.copyWith(
            status: BrowserSessionStatus.error,
            errorMessage: msg,
          ));
        default:
          break;
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  void sendClick(double x, double y) {
    _send({
      'type': 'click',
      'x': x.round(),
      'y': y.round(),
    });
  }

  void sendType(String text) {
    _send({
      'type': 'type',
      'text': text,
    });
  }

  void sendKey(String key) {
    _send({
      'type': 'keydown',
      'key': key,
    });
  }

  void sendScroll(double deltaY) {
    _send({
      'type': 'scroll',
      'deltaY': deltaY.round(),
    });
  }

  void finishSession() {
    _send({'type': 'done'});
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  @override
  Future<void> close() {
    disconnect();
    return super.close();
  }
}
