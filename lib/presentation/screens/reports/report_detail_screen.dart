import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/run_repository.dart';
import '../../widgets/charts/score_gauge.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/rivly_card.dart';

class ReportDetailScreen extends StatefulWidget {
  final String runId;

  const ReportDetailScreen({super.key, required this.runId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final RunRepository _runRepository = RunRepository();
  ReportModel? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await _runRepository.getReport(widget.runId);
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load report';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Report'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return LoadingShimmer.list(count: 5, itemHeight: 100);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadReport,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final report = _report!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall score
          Center(
            child: ScoreGauge(
              score: report.score,
              size: 160,
              strokeWidth: 14,
              label: 'Overall Score',
            ),
          ),
          const SizedBox(height: 24),

          // Summary
          Text(
            'Summary',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          RivlyCard(
            child: Text(
              report.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),

          // Competitor scores
          if (report.competitorScores.isNotEmpty) ...[
            Text(
              'Competitor Scores',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...report.competitorScores.entries.map((entry) {
              final competitor = entry.value;
              return RivlyCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            competitor.name,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ScoreGauge(
                          score: competitor.overallScore,
                          size: 48,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                    if (competitor.areaScores.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...competitor.areaScores.entries.map((area) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  area.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: area.value / 100.0,
                                    backgroundColor:
                                        Theme.of(context).dividerColor,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      _scoreColor(area.value),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${area.value}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Recommendations
          if (report.recommendations.isNotEmpty) ...[
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...report.recommendations.map((rec) {
              return RivlyCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PriorityBadge(priority: rec.priority),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec.title,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rec.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(rec.area,
                          style: const TextStyle(fontSize: 11)),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.accentPrimary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'high':
        color = AppColors.error;
        break;
      case 'medium':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
