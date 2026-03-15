import 'package:equatable/equatable.dart';
import '../../data/models/job_model.dart';
import '../../data/models/run_model.dart';

class DashboardState extends Equatable {
  final List<JobModel> jobs;
  final List<RunModel> recentRuns;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.jobs = const [],
    this.recentRuns = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    List<JobModel>? jobs,
    List<RunModel>? recentRuns,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DashboardState(
      jobs: jobs ?? this.jobs,
      recentRuns: recentRuns ?? this.recentRuns,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [jobs, recentRuns, isLoading, error];
}
