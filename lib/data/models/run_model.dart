class RunModel {
  final String id;
  final String jobId;
  final String status;
  final double progress;
  final int competitorsTotal;
  final int competitorsCompleted;
  final String? currentCompetitor;
  final String? currentStep;
  final List<String> logs;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const RunModel({
    required this.id,
    required this.jobId,
    this.status = 'pending',
    this.progress = 0.0,
    this.competitorsTotal = 0,
    this.competitorsCompleted = 0,
    this.currentCompetitor,
    this.currentStep,
    this.logs = const [],
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  factory RunModel.fromJson(Map<String, dynamic> json) {
    return RunModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      status: json['status'] as String? ?? 'pending',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      competitorsTotal: json['competitors_total'] as int? ?? 0,
      competitorsCompleted: json['competitors_completed'] as int? ?? 0,
      currentCompetitor: json['current_competitor'] as String?,
      currentStep: json['current_step'] as String?,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'status': status,
      'progress': progress,
      'competitors_total': competitorsTotal,
      'competitors_completed': competitorsCompleted,
      'current_competitor': currentCompetitor,
      'current_step': currentStep,
      'logs': logs,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  RunModel copyWith({
    String? id,
    String? jobId,
    String? status,
    double? progress,
    int? competitorsTotal,
    int? competitorsCompleted,
    String? currentCompetitor,
    String? currentStep,
    List<String>? logs,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return RunModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      competitorsTotal: competitorsTotal ?? this.competitorsTotal,
      competitorsCompleted: competitorsCompleted ?? this.competitorsCompleted,
      currentCompetitor: currentCompetitor ?? this.currentCompetitor,
      currentStep: currentStep ?? this.currentStep,
      logs: logs ?? this.logs,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
