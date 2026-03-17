import 'dart:typed_data';
import 'package:equatable/equatable.dart';

enum BrowserSessionStatus { idle, connecting, connected, done, error }

class BrowserSessionState extends Equatable {
  final BrowserSessionStatus status;
  final Uint8List? currentFrame;
  final String currentUrl;
  final String? errorMessage;
  final int cookieCount;

  const BrowserSessionState({
    this.status = BrowserSessionStatus.idle,
    this.currentFrame,
    this.currentUrl = '',
    this.errorMessage,
    this.cookieCount = 0,
  });

  BrowserSessionState copyWith({
    BrowserSessionStatus? status,
    Uint8List? currentFrame,
    String? currentUrl,
    String? errorMessage,
    bool clearError = false,
    int? cookieCount,
  }) {
    return BrowserSessionState(
      status: status ?? this.status,
      currentFrame: currentFrame ?? this.currentFrame,
      currentUrl: currentUrl ?? this.currentUrl,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cookieCount: cookieCount ?? this.cookieCount,
    );
  }

  @override
  List<Object?> get props => [status, currentFrame, currentUrl, errorMessage, cookieCount];
}
