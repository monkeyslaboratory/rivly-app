class WsEvent {
  final String event;
  final Map<String, dynamic> data;

  const WsEvent({
    required this.event,
    required this.data,
  });

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      event: json['event'] as String? ?? 'unknown',
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'data': data,
    };
  }

  bool get isProgress => event == 'progress';
  bool get isLog => event == 'log';
  bool get isCompleted => event == 'completed';
  bool get isError => event == 'error';
  bool get isCompetitorStarted => event == 'competitor_started';
  bool get isCompetitorCompleted => event == 'competitor_completed';
  bool get isStepChanged => event == 'step_changed';

  double get progress => (data['progress'] as num?)?.toDouble() ?? 0.0;
  String get logMessage => data['message'] as String? ?? '';
  String get competitorName => data['competitor'] as String? ?? '';
  String get stepName => data['step'] as String? ?? '';
  String get errorMessage => data['error'] as String? ?? '';
}
