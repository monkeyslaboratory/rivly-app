import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exception.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/repositories/run_repository.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  final JobRepository _jobRepository = JobRepository();
  final RunRepository _runRepository = RunRepository();

  InsightsCubit() : super(const InsightsState());

  Future<void> loadInsights() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final jobs = await _jobRepository.getJobs();
      final List<AggregatedInsight> allInsights = [];

      for (final job in jobs) {
        try {
          final runs = await _runRepository.getRuns(job.id);
          final completedRuns =
              runs.where((r) => r.isCompleted).toList();

          for (final run in completedRuns) {
            try {
              final rawRun = await _runRepository.getRawRun(run.id);
              final reports = rawRun['reports'] as List<dynamic>? ?? [];

              for (final report in reports) {
                if (report is! Map<String, dynamic>) continue;
                final competitorName =
                    report['competitor_name'] as String? ??
                        report['competitor'] as String? ??
                        'Unknown';
                final category =
                    report['category'] as String? ??
                        report['page_type'] as String? ??
                        report['area'] as String? ??
                        'General';
                final recommendations =
                    report['recommendations'] as List<dynamic>? ?? [];

                for (int i = 0; i < recommendations.length; i++) {
                  final rec = recommendations[i];
                  if (rec is! Map<String, dynamic>) continue;

                  allInsights.add(AggregatedInsight(
                    action: rec['action'] as String? ??
                        rec['title'] as String? ??
                        rec['recommendation'] as String? ??
                        '',
                    rationale: rec['rationale'] as String? ??
                        rec['description'] as String? ??
                        rec['reason'] as String? ??
                        '',
                    impact: _normalizeImpact(
                        rec['impact'] as String? ?? 'medium'),
                    effort: rec['effort'] as String? ?? 'medium',
                    priority: (rec['priority'] as num?)?.toInt() ?? (i + 1),
                    competitorName: competitorName,
                    category: category,
                    runId: run.id,
                  ));
                }
              }
            } catch (_) {
              // Skip runs where detail fetch fails
            }
          }
        } catch (_) {
          // Skip jobs where runs fail to load
        }
      }

      // Sort by priority (1 first)
      allInsights.sort((a, b) => a.priority.compareTo(b.priority));

      emit(state.copyWith(
        insights: allInsights,
        isLoading: false,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load insights',
      ));
    }
  }

  static String _normalizeImpact(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower == 'critical') return 'critical';
    if (lower == 'high') return 'high';
    if (lower == 'low') return 'low';
    return 'medium';
  }
}
