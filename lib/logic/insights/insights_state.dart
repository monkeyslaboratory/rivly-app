import 'package:equatable/equatable.dart';

class InsightsState extends Equatable {
  final List<AggregatedInsight> insights;
  final bool isLoading;
  final String? error;

  const InsightsState({
    this.insights = const [],
    this.isLoading = false,
    this.error,
  });

  InsightsState copyWith({
    List<AggregatedInsight>? insights,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return InsightsState(
      insights: insights ?? this.insights,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [insights, isLoading, error];
}

class AggregatedInsight extends Equatable {
  final String action;
  final String rationale;
  final String impact; // high, medium, low, critical
  final String effort;
  final int priority;
  final String competitorName;
  final String category; // page/area analyzed
  final String runId;

  const AggregatedInsight({
    required this.action,
    required this.rationale,
    required this.impact,
    required this.effort,
    required this.priority,
    required this.competitorName,
    required this.category,
    required this.runId,
  });

  @override
  List<Object?> get props => [
        action,
        rationale,
        impact,
        effort,
        priority,
        competitorName,
        category,
        runId,
      ];
}
