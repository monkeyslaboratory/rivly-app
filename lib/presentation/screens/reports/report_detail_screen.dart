import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../data/repositories/run_repository.dart';
import '../../widgets/charts/score_gauge.dart';
import '../../widgets/common/rivly_card.dart';

class ReportDetailScreen extends StatefulWidget {
  final String runId;
  const ReportDetailScreen({super.key, required this.runId});
  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final RunRepository _runRepository = RunRepository();
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _runRepository.getRawRun(widget.runId);
      setState(() { _data = response; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Report Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return const Center(child: Text('No data'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _safeSection('Status', () => _buildStatusHeader(data)),
          _safeSection('Scores', () => _buildScores(data)),
          _safeSection('Summary', () => _buildExecutiveSummary(data)),
          _safeSection('Screenshots', () => _buildScreenshots(data)),
          _safeSection('Reports', () => _buildDetailedReports(data)),
          _safeSection('Feature Matrix', () => _buildFeatureMatrix(data)),
          _safeSection('Recommendations', () => _buildRecommendations(data)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Wraps each section builder in try-catch so one crash doesn't kill the page.
  Widget _safeSection(String name, Widget Function() builder) {
    try {
      return builder();
    } catch (e) {
      return RivlyCard(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to render $name section',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ── 1. Status Header ────────────────────────────────────────────────

  Widget _buildStatusHeader(Map<String, dynamic> data) {
    final status = (data['status'] as String?) ?? 'unknown';
    final progress = (data['progress'] as num?)?.toInt() ?? 0;
    final phase = (data['current_phase'] as String?) ?? '';
    final cost = data['cost_api_usd']?.toString();

    final isComplete = status == 'completed';
    final isFailed = status == 'failed';
    final color = isComplete
        ? AppColors.success
        : isFailed
            ? AppColors.error
            : AppColors.accentPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : isFailed ? Icons.cancel : Icons.hourglass_top,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14),
                ),
                if (phase.isNotEmpty && !isComplete)
                  Text(phase, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
              ],
            ),
          ),
          if (!isComplete)
            Text('$progress%', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          if (cost != null) ...[
            const SizedBox(width: 12),
            Text('\$$cost', style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  // ── 2. Overall Scores ───────────────────────────────────────────────

  Widget _buildScores(Map<String, dynamic> data) {
    final overallScores = (data['overall_scores'] as List<dynamic>?) ?? [];
    if (overallScores.isEmpty) return const SizedBox.shrink();

    final first = (overallScores.first as Map<String, dynamic>?) ?? {};
    final overall = (first['overall_score'] as num?)?.toInt() ?? 0;
    final catScores = (first['category_scores'] as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Overall Scores'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ScoreGauge(score: overall, label: 'Overall', size: 100, strokeWidth: 8),
              ...catScores.entries.map((e) {
                final score = (e.value as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: ScoreGauge(
                    score: score,
                    label: _formatLabel(e.key),
                    size: 80,
                    strokeWidth: 6,
                  ),
                );
              }),
            ],
          ),
        ),
        // Top insights
        ..._buildTopInsights(first),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildTopInsights(Map<String, dynamic> scoreData) {
    final insights = (scoreData['top_insights'] as List<dynamic>?) ?? [];
    if (insights.isEmpty) return [];
    return [
      const SizedBox(height: 12),
      ...insights.take(5).map((insight) {
        final text = insight is String ? insight : insight.toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('  \u2022  ', style: TextStyle(fontSize: 13)),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
            ],
          ),
        );
      }),
    ];
  }

  // ── 3. Executive Summary ────────────────────────────────────────────

  Widget _buildExecutiveSummary(Map<String, dynamic> data) {
    final comparison = data['comparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();

    final summary = comparison['executive_summary'] as String?;
    final position = comparison['competitive_position'] as String?;
    if (summary == null && position == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Executive Summary'),
        if (summary != null)
          RivlyCard(
            child: Text(summary, style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
        if (position != null) ...[
          const SizedBox(height: 8),
          RivlyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Competitive Position',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.accentSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(position, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ── 4. Screenshots ─────────────────────────────────────────────────

  Widget _buildScreenshots(Map<String, dynamic> data) {
    final screenshots = (data['screenshots'] as List<dynamic>?) ?? [];
    if (screenshots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Screenshots'),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: screenshots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final shot = (screenshots[i] as Map<String, dynamic>?) ?? {};
              final shotId = shot['id']?.toString() ?? '';
              final pageName = (shot['page_name'] as String?) ?? '';
              final device = (shot['device_type'] as String?) ?? '';
              final url = 'http://localhost:8000/api/v1/runs/screenshots/$shotId/';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 200,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 200,
                        height: 130,
                        color: Theme.of(context).dividerColor,
                        child: const Icon(Icons.broken_image, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pageName ($device)',
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── 5. Detailed Reports ─────────────────────────────────────────────

  Widget _buildDetailedReports(Map<String, dynamic> data) {
    final reports = (data['reports'] as List<dynamic>?) ?? [];
    final scored = reports
        .whereType<Map<String, dynamic>>()
        .where((r) => ((r['score'] as num?)?.toInt() ?? 0) > 0)
        .toList();
    if (scored.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Detailed Reports'),
        ...scored.map(_buildReportCard),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final category = (report['category'] as String?) ?? 'Unknown';
    final score = (report['score'] as num?)?.toInt() ?? 0;
    final summary = (report['summary'] as String?) ?? '';
    final breakdown = (report['score_breakdown'] as Map<String, dynamic>?) ?? {};
    final recs = (report['recommendations'] as List<dynamic>?) ?? [];

    return RivlyCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatLabel(category),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentSecondary,
                  ),
                ),
              ),
              const Spacer(),
              ScoreGauge(score: score, size: 48, strokeWidth: 4),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(summary, style: const TextStyle(fontSize: 13, height: 1.4)),
          ],
          // Score breakdown chips
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: breakdown.entries.map((e) {
                final val = (e.value as num?)?.toInt() ?? 0;
                return Chip(
                  label: Text('${_formatLabel(e.key)}: $val'),
                  labelStyle: const TextStyle(fontSize: 11),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          // Top 3 recommendations
          if (recs.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...recs.take(3).map((rec) {
              final text = rec is String ? rec : (rec is Map ? (rec['text'] ?? rec['title'] ?? rec.toString()) : rec.toString());
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text.toString(),
                        style: const TextStyle(fontSize: 12, height: 1.3),
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
  }

  // ── 6. Feature Matrix ───────────────────────────────────────────────

  Widget _buildFeatureMatrix(Map<String, dynamic> data) {
    final comparison = data['comparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();
    final matrix = (comparison['feature_matrix'] as List<dynamic>?) ?? [];
    if (matrix.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Feature Matrix'),
        ...matrix.map((item) {
          final entry = (item as Map<String, dynamic>?) ?? {};
          final cat = (entry['category'] as String?) ?? 'Category';
          final features = (entry['features'] as List<dynamic>?) ?? [];

          return ExpansionTile(
            title: Text(_formatLabel(cat), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: features.map((f) {
              final feat = (f as Map<String, dynamic>?) ?? {};
              final name = (feat['name'] ?? feat['feature'] ?? '').toString();
              final value = (feat['value'] ?? feat['status'] ?? feat['supported'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
                    Text(value, style: TextStyle(fontSize: 13, color: AppColors.accentSecondary)),
                  ],
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── 7. Recommendations ──────────────────────────────────────────────

  Widget _buildRecommendations(Map<String, dynamic> data) {
    final comparison = data['comparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();
    final recs = (comparison['recommendations'] as List<dynamic>?) ?? [];
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Recommendations'),
        ...recs.map((rec) {
          final entry = (rec as Map<String, dynamic>?) ?? {};
          final title = (entry['title'] ?? entry['recommendation'] ?? '').toString();
          final description = (entry['description'] ?? entry['detail'] ?? '').toString();
          final priority = (entry['priority'] as String?) ?? '';

          final priorityColor = switch (priority.toLowerCase()) {
            'high' || 'critical' => AppColors.error,
            'medium' => AppColors.warning,
            _ => AppColors.success,
          };

          return RivlyCard(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(description, style: const TextStyle(fontSize: 13, height: 1.4)),
                      ],
                      if (priority.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          priority.toUpperCase(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: priorityColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
