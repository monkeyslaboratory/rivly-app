import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/ws_client.dart';
import '../../core/storage/secure_storage.dart';
import '../../data/models/ws_event_model.dart';
import '../../data/repositories/run_repository.dart';
import 'run_progress_state.dart';

class RunProgressCubit extends Cubit<RunProgressState> {
  final RunRepository _runRepository = RunRepository();
  final SecureStorageService _storage = SecureStorageService();
  final WsClient _wsClient = WsClient();
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  RunProgressCubit() : super(const RunProgressState());

  Future<void> startTracking(String runId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final run = await _runRepository.getRun(runId);
      emit(state.copyWith(
        run: run,
        isLoading: false,
        progress: run.progress,
        competitorsTotal: run.competitorsTotal,
        competitorsCompleted: run.competitorsCompleted,
        currentCompetitor: run.currentCompetitor,
        currentStep: run.currentStep,
        logs: run.logs,
        isCompleted: run.status == 'completed',
        isFailed: run.status == 'failed',
      ));

      if (run.status == 'completed' || run.status == 'failed') return;

      await _connectWebSocket(runId);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load run details',
      ));
    }
  }

  Future<void> _connectWebSocket(String runId) async {
    final token = await _storage.getAccessToken();
    if (token == null) return;

    final url = ApiConstants.wsRun(runId, token);
    await _wsClient.connect(url);

    emit(state.copyWith(isConnected: true));

    _wsSubscription = _wsClient.stream.listen((data) {
      final event = WsEvent.fromJson(data);
      _handleEvent(event);
    });
  }

  void _handleEvent(WsEvent event) {
    if (event.isProgress) {
      emit(state.copyWith(progress: event.progress));
    } else if (event.isLog) {
      final updatedLogs = [...state.logs, event.logMessage];
      emit(state.copyWith(logs: updatedLogs));
    } else if (event.isCompetitorStarted) {
      emit(state.copyWith(currentCompetitor: event.competitorName));
    } else if (event.isCompetitorCompleted) {
      emit(state.copyWith(
        competitorsCompleted: state.competitorsCompleted + 1,
      ));
    } else if (event.isStepChanged) {
      emit(state.copyWith(currentStep: event.stepName));
    } else if (event.isCompleted) {
      emit(state.copyWith(
        isCompleted: true,
        progress: 1.0,
        isConnected: false,
      ));
      _disconnect();
    } else if (event.isError) {
      emit(state.copyWith(
        isFailed: true,
        error: event.errorMessage,
        isConnected: false,
      ));
      _disconnect();
    }
  }

  Future<void> cancelRun() async {
    final run = state.run;
    if (run == null) return;

    try {
      await _runRepository.cancelRun(run.id);
      _disconnect();
      emit(state.copyWith(
        isFailed: true,
        error: 'Run cancelled',
        isConnected: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to cancel run'));
    }
  }

  void _disconnect() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsClient.disconnect();
  }

  @override
  Future<void> close() {
    _disconnect();
    _wsClient.dispose();
    return super.close();
  }
}
