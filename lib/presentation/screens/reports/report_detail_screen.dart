import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/run_repository.dart';
import '../../widgets/charts/score_gauge.dart';
import '../../widgets/common/rivly_button.dart';

class ReportDetailScreen extends StatefulWidget {
  final String runId;

  const ReportDetailScreen({super.key, required this.runId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final RunRepository _runRepository = RunRepository();
  Map<String, dynamic>? _runData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _runRepository.getRawRun(widget.runId);
      setState(() { _runData = response; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Analysis Report'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(isDark)
              : _runData != null
                  ? _buildReport(isDark)
                  : _buildEmpty(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load report', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error ?? '', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            RivlyButton(label: 'Retry', onPressed: _loadReport),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          const SizedBox(height: 16),
          Text('No report data', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          RivlyButton(label: 'Back to Dashboard', onPressed: () => context.go('/dashboard'), variant: RivlyButtonVariant.outline),
        ],
      ),
    );
  }

  Widget _buildReport(bool isDark) {
    final data = _runData!;
    final status = data['status'] as String? ?? '';
    final duration = data['duration_seconds'] as int?;
    final reports = (data['reports'] as List<dynamic>?) ?? [];
    final overallScores = (data['overall_scores'] as List<dynamic>?) ?? [];
    final screenshots = (data['screenshots'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: status == 'completed'
                  ? AppColors.success.withValues(alpha: 0.08)
                  : status == 'failed'
                      ? AppColors.error.withValues(alpha: 0.08)
                      : (isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary),
              border: Border.all(
                color: status == 'completed'
                    ? AppColors.success.withValues(alpha: 0.2)
                    : status == 'failed'
                        ? AppColors.error.withValues(alpha: 0.2)
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'completed' ? Icons.check_circle : status == 'failed' ? Icons.error : Icons.hourglass_top,
                  color: status == 'completed' ? AppColors.success : status == 'failed' ? AppColors.error : AppColors.accentPrimary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'completed' ? 'Analysis Complete' : status == 'failed' ? 'Analysis Failed' : 'In Progress',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      if (duration != null)
                        Text('Completed in ${_formatDuration(duration)}',
                            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Overall scores
          if (overallScores.isNotEmpty) ...[
            Text('Competitor Scores', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...overallScores.map((os) => _buildOverallScoreCard(os as Map<String, dynamic>, isDark)),
            const SizedBox(height: 24),
          ],

          // Screenshots
          if (screenshots.isNotEmpty) ...[
            Text('Screenshots', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: screenshots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final shot = screenshots[index] as Map<String, dynamic>;
                  final shotId = shot['id'] as String;
                  final pageName = shot['page_name'] as String? ?? '';
                  final deviceType = shot['device_type'] as String? ?? '';
                  final shotStatus = shot['status'] as String? ?? '';
                  final imageUrl = 'http://localhost:8000/api/v1/runs/screenshots/$shotId/';

                  return Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                      color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: shotStatus == 'success'
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(Icons.broken_image, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error_outline, color: AppColors.error, size: 24),
                                        const SizedBox(height: 4),
                                        Text(shotStatus, style: TextStyle(fontSize: 11, color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Icon(
                                deviceType == 'mobile' ? Icons.phone_iphone : Icons.desktop_windows_outlined,
                                size: 14,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pageName.replaceAll('_', ' '),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Individual reports
          if (reports.isNotEmpty) ...[
            Text('Detailed Analysis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...reports.where((r) => (r as Map<String, dynamic>)['score'] > 0).map(
                (r) => _buildReportCard(r as Map<String, dynamic>, isDark)),
          ],

          if (reports.isEmpty && overallScores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No analysis data available yet.',
                    style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard(Map<String, dynamic> os, bool isDark) {
    final score = os['overall_score'] as int? ?? 0;
    final delta = os['score_delta'] as int?;
    final insights = (os['top_insights'] as List<dynamic>?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          ScoreGauge(score: score, size: 72, strokeWidth: 6,
              color: score >= 80 ? AppColors.success : score >= 60 ? AppColors.accentPrimary : AppColors.error),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('UX Score: $score',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    if (delta != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (delta >= 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${delta >= 0 ? "▲" : "▼"} ${delta.abs()}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: delta >= 0 ? AppColors.success : AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                if (insights.isNotEmpty)
                  Text(insights.first.toString(),
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    final category = report['category'] as String? ?? '';
    final score = report['score'] as int? ?? 0;
    final summary = report['summary'] as String? ?? '';
    final recommendations = (report['recommendations'] as List<dynamic>?) ?? [];
    final scoreBreakdown = report['score_breakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(category.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentSecondary)),
              ),
              const Spacer(),
              Text('$score/100',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: score >= 80 ? AppColors.success : score >= 60 ? AppColors.accentPrimary : AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),

          // Summary
          Text(summary, style: TextStyle(fontSize: 13, height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),

          // Score breakdown
          if (scoreBreakdown.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: scoreBreakdown.entries.map((e) {
                final val = e.value as int? ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
                  ),
                  child: Text('${e.key.replaceAll('_', ' ')}: $val',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                );
              }).toList(),
            ),
          ],

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...recommendations.take(3).map((r) {
              final rec = r as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accentPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(rec['action'] as String? ?? '',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
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

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }
}
