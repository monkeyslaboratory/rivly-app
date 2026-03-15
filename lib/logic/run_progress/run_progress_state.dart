import 'package:equatable/equatable.dart';
import '../../data/models/run_model.dart';

class RunProgressState extends Equatable {
  final RunModel? run;
  final bool isConnected;
  final bool isLoading;
  final String? error;
  final double progress;
  final String? currentCompetitor;
  final String? currentStep;
  final int competitorsCompleted;
  final int competitorsTotal;
  final List<String> logs;
  final bool isCompleted;
  final bool isFailed;

  const RunProgressState({
    this.run,
    this.isConnected = false,
    this.isLoading = false,
    this.error,
    this.progress = 0.0,
    this.currentCompetitor,
    this.currentStep,
    this.competitorsCompleted = 0,
    this.competitorsTotal = 0,
    this.logs = const [],
    this.isCompleted = false,
    this.isFailed = false,
  });

  RunProgressState copyWith({
    RunModel? run,
    bool? isConnected,
    bool? isLoading,
    String? error,
    bool clearError = false,
    double? progress,
    String? currentCompetitor,
    String? currentStep,
    int? competitorsCompleted,
    int? competitorsTotal,
    List<String>? logs,
    bool? isCompleted,
    bool? isFailed,
  }) {
    return RunProgressState(
      run: run ?? this.run,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      progress: progress ?? this.progress,
      currentCompetitor: currentCompetitor ?? this.currentCompetitor,
      currentStep: currentStep ?? this.currentStep,
      competitorsCompleted:
          competitorsCompleted ?? this.competitorsCompleted,
      competitorsTotal: competitorsTotal ?? this.competitorsTotal,
      logs: logs ?? this.logs,
      isCompleted: isCompleted ?? this.isCompleted,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  @override
  List<Object?> get props => [
        run,
        isConnected,
        isLoading,
        error,
        progress,
        currentCompetitor,
        currentStep,
        competitorsCompleted,
        competitorsTotal,
        logs,
        isCompleted,
        isFailed,
      ];
}
