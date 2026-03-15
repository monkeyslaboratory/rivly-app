import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/competitor_model.dart';
import '../../data/repositories/job_repository.dart';
import 'stepper_state.dart';

class StepperCubit extends Cubit<StepperState> {
  final JobRepository _jobRepository = JobRepository();

  StepperCubit() : super(const StepperState());

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1 && state.canProceed) {
      emit(state.copyWith(
        currentStep: state.currentStep + 1,
        clearError: true,
      ));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(
        currentStep: state.currentStep - 1,
        clearError: true,
      ));
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      emit(state.copyWith(currentStep: step, clearError: true));
    }
  }

  void setProductUrl(String url) {
    emit(state.copyWith(productUrl: url, productAnalyzed: false));
  }

  Future<void> analyzeProduct() async {
    if (state.productUrl.isEmpty) return;

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _jobRepository.analyzeProduct(state.productUrl);
      emit(state.copyWith(
        isLoading: false,
        productName: result['name'] as String?,
        productDescription: result['description'] as String?,
        productCategory: result['category'] as String?,
        productAnalyzed: true,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to analyze product',
      ));
    }
  }

  Future<void> discoverCompetitors() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final competitors = await _jobRepository.discoverCompetitors(
        productUrl: state.productUrl,
        productDescription: state.productDescription,
        productCategory: state.productCategory,
      );
      emit(state.copyWith(
        isLoading: false,
        discoveredCompetitors: competitors,
        selectedCompetitors: competitors,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to discover competitors',
      ));
    }
  }

  void toggleCompetitor(CompetitorModel competitor) {
    final selected = List<CompetitorModel>.from(state.selectedCompetitors);
    final index = selected.indexWhere((c) => c.id == competitor.id);
    if (index >= 0) {
      selected.removeAt(index);
    } else {
      selected.add(competitor);
    }
    emit(state.copyWith(selectedCompetitors: selected));
  }

  void addManualCompetitor(CompetitorModel competitor) {
    final discovered =
        List<CompetitorModel>.from(state.discoveredCompetitors)..add(competitor);
    final selected = List<CompetitorModel>.from(state.selectedCompetitors)
      ..add(competitor);
    emit(state.copyWith(
      discoveredCompetitors: discovered,
      selectedCompetitors: selected,
    ));
  }

  Future<void> fetchSuggestedAreas() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final areas = await _jobRepository.suggestAreas(
        productUrl: state.productUrl,
        productCategory: state.productCategory,
      );
      emit(state.copyWith(
        isLoading: false,
        suggestedAreas: areas,
        selectedAreas: areas,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to suggest analysis areas',
      ));
    }
  }

  void toggleArea(String area) {
    final selected = List<String>.from(state.selectedAreas);
    if (selected.contains(area)) {
      selected.remove(area);
    } else {
      selected.add(area);
    }
    emit(state.copyWith(selectedAreas: selected));
  }

  Future<void> checkAccess() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final results = <String, bool>{};
      for (final competitor in state.selectedCompetitors) {
        final result = await _jobRepository.checkAccess(competitor.url);
        results[competitor.id] = result['accessible'] as bool? ?? false;
      }
      emit(state.copyWith(isLoading: false, accessResults: results));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to check access',
      ));
    }
  }

  void setSchedule(String schedule) {
    emit(state.copyWith(schedule: schedule));
  }

  void setJobName(String name) {
    emit(state.copyWith(jobName: name));
  }

  Future<String?> createJob() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final job = await _jobRepository.createJob(
        name: state.jobName,
        productUrl: state.productUrl,
        productDescription: state.productDescription,
        productCategory: state.productCategory,
        schedule: state.schedule,
        competitors:
            state.selectedCompetitors.map((c) => c.toJson()).toList(),
        analysisAreas: state.selectedAreas,
      );
      emit(state.copyWith(isLoading: false));
      return job.id;
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
      return null;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to create job',
      ));
      return null;
    }
  }

  void reset() {
    emit(const StepperState());
  }
}
