class RunModel {
  final String id;
  final String jobId;
  final String status; // queued, preflight, screenshots, analyzing, scoring, completed, partial, failed
  final int progress; // 0-100
  final String currentPhase;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final String errorLog;
  final DateTime createdAt;

  const RunModel({
    required this.id,
    required this.jobId,
    this.status = 'queued',
    this.progress = 0,
    this.currentPhase = '',
    this.startedAt,
    this.completedAt,
    this.durationSeconds,
    this.errorLog = '',
    required this.createdAt,
  });

  // Computed
  String get phaseLabel => _phaseLabels[currentPhase] ?? currentPhase;
  bool get isRunning =>
      !['completed', 'partial', 'failed', 'cancelled'].contains(status);
  bool get isCompleted => status == 'completed' || status == 'partial';
  bool get isFailed => status == 'failed' || status == 'cancelled';

  static const _phaseLabels = {
    'preflight': 'Checking accessibility...',
    'screenshots': 'Capturing screenshots...',
    'analyzing': 'AI is analyzing...',
    'scoring': 'Calculating scores...',
    'comparing': 'Generating competitive analysis...',
    'completed': 'Analysis complete!',
    'failed': 'Analysis failed',
    '': 'Preparing...',
  };

  factory RunModel.fromJson(Map<String, dynamic> json) {
    return RunModel(
      id: json['id'] as String,
      jobId: (json['job'] ?? json['job_id'] ?? '') as String,
      status: json['status'] as String? ?? 'queued',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      currentPhase: json['current_phase'] as String? ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      errorLog: json['error_log'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job': jobId,
      'status': status,
      'progress': progress,
      'current_phase': currentPhase,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'error_log': errorLog,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RunModel copyWith({
    String? id,
    String? jobId,
    String? status,
    int? progress,
    String? currentPhase,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    String? errorLog,
    DateTime? createdAt,
  }) {
    return RunModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentPhase: currentPhase ?? this.currentPhase,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      errorLog: errorLog ?? this.errorLog,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
