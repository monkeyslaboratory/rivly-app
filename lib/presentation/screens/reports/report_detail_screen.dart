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
      return _buildLoadingState(context);
    }

    if (_error != null) {
      return _buildErrorState(context);
    }

    if (_report == null) {
      return _buildEmptyState(context);
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

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Score gauge placeholder
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkBgSubtle
                    : AppColors.lightBgSubtle,
              ),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Shimmer cards
          LoadingShimmer.list(count: 3, itemHeight: 100),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgElevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 28,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load report',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'An unexpected error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _loadReport,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accentSecondary.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.assessment_outlined,
                    size: 44,
                    color: AppColors.accentSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Report not found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This report may have been removed\nor is still processing',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Dashboard'),
              ),
            ),
          ],
        ),
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
