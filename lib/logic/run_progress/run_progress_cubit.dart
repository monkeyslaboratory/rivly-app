import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/run_repository.dart';
import 'run_progress_state.dart';

class RunProgressCubit extends Cubit<RunProgressState> {
  final RunRepository _runRepository = RunRepository();
  Timer? _pollTimer;

  RunProgressCubit() : super(const RunProgressState());

  Future<void> startTracking(String runId) async {
    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      trackingStartedAt: DateTime.now(),
    ));

    try {
      final run = await _runRepository.getRun(runId);
      emit(state.copyWith(run: run, isLoading: false));

      if (run.isRunning && !run.needsApproval) {
        _startPolling(runId);
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load run details',
      ));
    }
  }

  void _startPolling(String runId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _poll(runId);
    });
  }

  Future<void> _poll(String runId) async {
    try {
      final run = await _runRepository.getRun(runId);
      if (isClosed) return;
      emit(state.copyWith(run: run));

      if (!run.isRunning || run.needsApproval) {
        _stopPolling();
      }
    } catch (_) {
      // Silently ignore poll errors; will retry on next tick
    }
  }

  Future<void> cancelRun() async {
    final run = state.run;
    if (run == null) return;

    try {
      await _runRepository.cancelRun(run.id);
      _stopPolling();
      // Re-fetch to get updated state
      final updated = await _runRepository.getRun(run.id);
      emit(state.copyWith(run: updated));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to cancel run'));
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
