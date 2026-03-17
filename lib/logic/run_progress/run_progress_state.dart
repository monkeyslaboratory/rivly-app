import 'package:equatable/equatable.dart';
import '../../data/models/run_model.dart';

class RunProgressState extends Equatable {
  final RunModel? run;
  final bool isLoading;
  final String? error;
  final DateTime? trackingStartedAt;
  final Map<String, dynamic>? rawData;

  const RunProgressState({
    this.run,
    this.isLoading = false,
    this.error,
    this.trackingStartedAt,
    this.rawData,
  });

  // Derived
  int get progress => run?.progress ?? 0;
  String get phaseLabel => run?.phaseLabel ?? 'Preparing...';
  bool get isRunning => run?.isRunning ?? false;
  bool get needsApproval => run?.needsApproval ?? false;
  bool get isCompleted => run?.isCompleted ?? false;
  bool get isFailed => run?.isFailed ?? false;
  String get status => run?.status ?? 'queued';

  // ETA calculation
  String get etaLabel {
    if (run == null || !isRunning || progress <= 0) return 'Estimating...';
    if (run!.startedAt == null) return 'Starting...';

    final elapsed = DateTime.now().difference(run!.startedAt!).inSeconds;
    if (elapsed <= 0 || progress <= 0) return 'Estimating...';

    final totalEstimate = (elapsed * 100 / progress).round();
    final remaining = totalEstimate - elapsed;

    if (remaining <= 0) return 'Almost done...';
    if (remaining < 60) return '~${remaining}s remaining';
    final mins = (remaining / 60).ceil();
    return '~${mins}min remaining';
  }

  RunProgressState copyWith({
    RunModel? run,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? trackingStartedAt,
    Map<String, dynamic>? rawData,
  }) {
    return RunProgressState(
      run: run ?? this.run,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      trackingStartedAt: trackingStartedAt ?? this.trackingStartedAt,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  List<Object?> get props => [run, isLoading, error, trackingStartedAt, rawData];
}
