import 'package:equatable/equatable.dart';
import '../../data/models/competitor_model.dart';

class StepperState extends Equatable {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final String? error;

  // Step 1: Product URL
  final String productUrl;
  final String? productName;
  final String? productDescription;
  final String? productCategory;
  final bool productAnalyzed;

  // Step 2: Competitors
  final List<CompetitorModel> discoveredCompetitors;
  final List<CompetitorModel> selectedCompetitors;

  // Step 3: Analysis areas
  final List<String> suggestedAreas;
  final List<String> selectedAreas;

  // Step 4: Access check
  final Map<String, bool> accessResults;

  // Step 5: Schedule
  final String schedule;

  // Step 6: Name
  final String jobName;

  const StepperState({
    this.currentStep = 0,
    this.totalSteps = 7,
    this.isLoading = false,
    this.error,
    this.productUrl = '',
    this.productName,
    this.productDescription,
    this.productCategory,
    this.productAnalyzed = false,
    this.discoveredCompetitors = const [],
    this.selectedCompetitors = const [],
    this.suggestedAreas = const [],
    this.selectedAreas = const [],
    this.accessResults = const {},
    this.schedule = 'manual',
    this.jobName = '',
  });

  StepperState copyWith({
    int? currentStep,
    int? totalSteps,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? productUrl,
    String? productName,
    String? productDescription,
    String? productCategory,
    bool? productAnalyzed,
    List<CompetitorModel>? discoveredCompetitors,
    List<CompetitorModel>? selectedCompetitors,
    List<String>? suggestedAreas,
    List<String>? selectedAreas,
    Map<String, bool>? accessResults,
    String? schedule,
    String? jobName,
  }) {
    return StepperState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      productUrl: productUrl ?? this.productUrl,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productCategory: productCategory ?? this.productCategory,
      productAnalyzed: productAnalyzed ?? this.productAnalyzed,
      discoveredCompetitors:
          discoveredCompetitors ?? this.discoveredCompetitors,
      selectedCompetitors: selectedCompetitors ?? this.selectedCompetitors,
      suggestedAreas: suggestedAreas ?? this.suggestedAreas,
      selectedAreas: selectedAreas ?? this.selectedAreas,
      accessResults: accessResults ?? this.accessResults,
      schedule: schedule ?? this.schedule,
      jobName: jobName ?? this.jobName,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return productAnalyzed;
      case 1:
        return selectedCompetitors.isNotEmpty;
      case 2:
        return selectedAreas.isNotEmpty;
      case 3:
        return accessResults.isNotEmpty;
      case 4:
        return schedule.isNotEmpty;
      case 5:
        return jobName.trim().isNotEmpty;
      case 6:
        return true;
      default:
        return false;
    }
  }

  @override
  List<Object?> get props => [
        currentStep,
        totalSteps,
        isLoading,
        error,
        productUrl,
        productName,
        productDescription,
        productCategory,
        productAnalyzed,
        discoveredCompetitors,
        selectedCompetitors,
        suggestedAreas,
        selectedAreas,
        accessResults,
        schedule,
        jobName,
      ];
}
