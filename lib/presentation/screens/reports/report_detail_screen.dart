import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.reportDetails),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l = AppLocalizations.of(context);

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
              ElevatedButton(onPressed: _load, child: Text(l.retry)),
            ],
          ),
        ),
      );
    }
    final data = _data;
    if (data == null) {
      return Center(child: Text(l.noData));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _safeSection(l.statusLabel, () => _buildStatusHeader(data)),
          _safeSection(l.scoresLabel, () => _buildScores(data)),
          _safeSection(l.summaryLabel, () => _buildExecutiveSummary(data)),
          _safeSection(l.pageReports, () => _buildPageReportCards(data)),
          _safeSection(l.featureMatrixLabel, () => _buildFeatureMatrix(data)),
          _safeSection(l.recommendationsLabel, () => _buildRecommendations(data)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Wraps each section builder in try-catch so one crash doesn't kill the page.
  Widget _safeSection(String name, Widget Function() builder) {
    final l = AppLocalizations.of(context);
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
                l.failedToRenderSection(name),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
  }

  // -- 1. Status Header --

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

  // -- 2. Overall Scores --

  Widget _buildScores(Map<String, dynamic> data) {
    final l = AppLocalizations.of(context);
    final overallScores = (data['overall_scores'] as List<dynamic>?) ?? [];
    if (overallScores.isEmpty) return const SizedBox.shrink();

    final first = (overallScores.first as Map<String, dynamic>?) ?? {};
    final overall = (first['overall_score'] as num?)?.toInt() ?? 0;
    final catScores = (first['category_scores'] as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.overallScores),
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

  // -- 3. Executive Summary --

  Widget _buildExecutiveSummary(Map<String, dynamic> data) {
    final l = AppLocalizations.of(context);
    final comparison = data['comparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();

    final summary = comparison['executive_summary'] as String?;
    final position = comparison['competitive_position'] as String?;
    if (summary == null && position == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.executiveSummary),
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
                  l.competitivePosition,
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

  // -- 4. Page Report Cards (screenshot + analysis side by side) --

  Widget _buildPageReportCards(Map<String, dynamic> data) {
    final l = AppLocalizations.of(context);
    final reports = (data['reports'] as List<dynamic>?) ?? [];
    final screenshots = (data['screenshots'] as List<dynamic>?) ?? [];

    final scored = reports
        .whereType<Map<String, dynamic>>()
        .where((r) => ((r['score'] as num?)?.toInt() ?? 0) > 0)
        .toList();
    if (scored.isEmpty) return const SizedBox.shrink();

    // Build a lookup: page_name -> screenshot
    final screenshotMap = <String, Map<String, dynamic>>{};
    for (final s in screenshots.whereType<Map<String, dynamic>>()) {
      final pageName = (s['page_name'] as String?) ?? '';
      if (pageName.isNotEmpty) {
        screenshotMap[pageName] = s;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.detailedReports),
        ...scored.map((report) => _buildPageCard(report, screenshotMap)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPageCard(
    Map<String, dynamic> report,
    Map<String, Map<String, dynamic>> screenshotMap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final category = (report['category'] as String?) ?? l.unknown;
    final score = (report['score'] as num?)?.toInt() ?? 0;
    final summary = (report['summary'] as String?) ?? '';
    final breakdown = (report['score_breakdown'] as Map<String, dynamic>?) ?? {};
    final recs = (report['recommendations'] as List<dynamic>?) ?? [];
    final findings = (report['key_findings'] as List<dynamic>?) ?? [];

    // Find matching screenshot
    final screenshot = screenshotMap[category];
    final screenshotId = screenshot?['id']?.toString();
    final screenshotUrl = screenshotId != null
        ? 'http://localhost:8000/api/v1/runs/screenshots/$screenshotId/'
        : null;

    final scoreColor = _scoreColor(score);

    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bgColor = isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Card header: page name + score --
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined, size: 18, color: textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatLabel(category),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$score/100',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -- Main content: screenshot + analysis --
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;

                final screenshotWidget = screenshotUrl != null
                    ? _buildScreenshotPane(screenshotUrl, borderColor)
                    : null;

                final analysisWidget = _buildAnalysisPane(
                  summary: summary,
                  findings: findings,
                  breakdown: breakdown,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  scoreColor: scoreColor,
                );

                if (isWide && screenshotWidget != null) {
                  // Side by side: 40% screenshot, 60% analysis
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * 0.38,
                        child: screenshotWidget,
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: analysisWidget),
                    ],
                  );
                } else {
                  // Stacked: screenshot on top, analysis below
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (screenshotWidget != null) ...[
                        screenshotWidget,
                        const SizedBox(height: 16),
                      ],
                      analysisWidget,
                    ],
                  );
                }
              },
            ),
          ),

          // -- Recommendations footer --
          if (recs.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBgSubtle.withValues(alpha: 0.5)
                    : AppColors.lightBgSubtle,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.recommendations,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...recs.asMap().entries.take(5).map((entry) {
                    final idx = entry.key + 1;
                    final rec = entry.value;
                    String text;
                    String? impact;
                    String? effort;

                    if (rec is Map) {
                      text = (rec['text'] ?? rec['title'] ?? rec['recommendation'] ?? rec.toString()).toString();
                      impact = (rec['impact'] as String?) ?? (rec['priority'] as String?);
                      effort = rec['effort'] as String?;
                    } else {
                      text = rec.toString();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '$idx.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  text,
                                  style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                                ),
                                if (impact != null) ...[
                                  const SizedBox(width: 6),
                                  _buildChip(
                                    l.impactLabel(_capitalize(impact)),
                                    _impactColor(impact),
                                  ),
                                ],
                                if (effort != null) ...[
                                  const SizedBox(width: 4),
                                  _buildChip(
                                    l.effortLabel(_capitalize(effort)),
                                    textMuted,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenshotPane(String url, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Theme.of(context).dividerColor,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 32, color: Theme.of(context).disabledColor),
                const SizedBox(height: 4),
                Text(
                  'Screenshot unavailable',
                  style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).disabledColor),
                ),
              ],
            ),
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisPane({
    required String summary,
    required List<dynamic> findings,
    required Map<String, dynamic> breakdown,
    required Color textSecondary,
    required Color textMuted,
    required Color scoreColor,
  }) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        if (summary.isNotEmpty) ...[
          Text(
            l.summarySection,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: GoogleFonts.inter(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
        ],

        // Key Findings
        if (findings.isNotEmpty) ...[
          Text(
            l.keyFindings,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ...findings.take(5).map((f) {
            final text = f is String ? f : (f is Map ? (f['text'] ?? f['finding'] ?? f.toString()) : f.toString());
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('\u2022 ', style: GoogleFonts.inter(fontSize: 13, color: textMuted)),
                  Expanded(
                    child: Text(
                      text.toString(),
                      style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // Score Breakdown
        if (breakdown.isNotEmpty) ...[
          Text(
            l.scoreBreakdown,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ...breakdown.entries.map((e) {
            final val = (e.value as num?)?.toInt() ?? 0;
            final barColor = _scoreColor(val);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      _formatLabel(e.key),
                      style: GoogleFonts.inter(fontSize: 12, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              height: 6,
                              width: constraints.maxWidth * (val / 100.0).clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$val',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: barColor,
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
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  // -- 6. Feature Matrix --

  Widget _buildFeatureMatrix(Map<String, dynamic> data) {
    final l = AppLocalizations.of(context);
    final comparison = data['comparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();
    final matrix = (comparison['feature_matrix'] as List<dynamic>?) ?? [];
    if (matrix.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.featureMatrix),
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

  // -- 7. Recommendations --

  Widget _buildRecommendations(Map<String, dynamic> data) {
    final l = AppLocalizations.of(context);
    final comparison = data['comparison'] as Map<String, dynamic>?;
    if (comparison == null) return const SizedBox.shrink();
    final recs = (comparison['recommendations'] as List<dynamic>?) ?? [];
    if (recs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l.recommendations),
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

  // -- Helpers --

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
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

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.accentPrimary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Color _impactColor(String impact) {
    return switch (impact.toLowerCase()) {
      'high' || 'critical' => AppColors.error,
      'medium' => AppColors.warning,
      'low' => AppColors.success,
      _ => AppColors.accentSecondary,
    };
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
  }
}
