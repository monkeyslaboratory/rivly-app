import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/run_repository.dart';
import '../../data/models/run_model.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final JobRepository _jobRepository = JobRepository();
  final RunRepository _runRepository = RunRepository();

  DashboardCubit() : super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final jobs = await _jobRepository.getJobs();

      final List<RunModel> allRuns = [];
      for (final job in jobs) {
        try {
          final runs = await _runRepository.getRuns(job.id);
          allRuns.addAll(runs);
        } catch (_) {
          // Skip jobs where runs fail to load
        }
      }

      allRuns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentRuns = allRuns.take(10).toList();

      emit(state.copyWith(
        jobs: jobs,
        recentRuns: recentRuns,
        isLoading: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard',
      ));
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _jobRepository.deleteJob(jobId);
      final updatedJobs =
          state.jobs.where((j) => j.id != jobId).toList();
      emit(state.copyWith(jobs: updatedJobs));
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete job'));
    }
  }

  Future<void> triggerRun(String jobId) async {
    try {
      await _jobRepository.triggerRun(jobId);
      await loadDashboard();
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to trigger run'));
    }
  }
}
