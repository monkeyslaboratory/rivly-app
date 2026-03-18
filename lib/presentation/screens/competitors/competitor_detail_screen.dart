import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../core/theme/tokens/typography.dart';
import '../../../data/models/competitor_model.dart';
import '../../../data/repositories/run_repository.dart';
import '../../../logic/dashboard/dashboard_cubit.dart';
import '../../widgets/common/loading_shimmer.dart';

/// Competitor Detail page -- shows score, breakdown, screenshots, and
/// recommendations for a single competitor.
class CompetitorDetailScreen extends StatefulWidget {
  final String competitorId;

  const CompetitorDetailScreen({super.key, required this.competitorId});

  @override
  State<CompetitorDetailScreen> createState() =>
      _CompetitorDetailScreenState();
}

class _CompetitorDetailScreenState extends State<CompetitorDetailScreen> {
  final RunRepository _runRepository = RunRepository();
  bool _isLoading = true;
  String? _error;

  CompetitorModel? _competitor;
  int _overallScore = 0;
  int? _scoreDelta;
  Map<String, int> _scoreBreakdown = {};
  String _summary = '';
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _screenshots = [];

  @override
  void initState() {
    super.initState();
    _loadCompetitorDetail();
  }

  Future<void> _loadCompetitorDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashState = context.read<DashboardCubit>().state;

      // Find the competitor across all jobs
      CompetitorModel? foundCompetitor;
      for (final job in dashState.jobs) {
        for (final comp in job.competitors) {
          if (comp.id == widget.competitorId) {
            foundCompetitor = comp;
            break;
          }
        }
        if (foundCompetitor != null) break;
      }

      if (foundCompetitor == null) {
        setState(() {
          _error = 'Competitor not found';
          _isLoading = false;
        });
        return;
      }

      _competitor = foundCompetitor;

      // Search through completed runs for reports on this competitor
      int bestScore = 0;
      Map<String, int> bestBreakdown = {};
      String bestSummary = '';
      List<Map<String, dynamic>> bestRecs = [];
      List<Map<String, dynamic>> allScreenshots = [];

      for (final job in dashState.jobs) {
        final hasCompetitor =
            job.competitors.any((c) => c.id == widget.competitorId);
        if (!hasCompetitor) continue;

        try {
          final runs = await _runRepository.getRuns(job.id);
          final completedRuns = runs.where((r) => r.isCompleted).toList();

          for (final run in completedRuns) {
            try {
              final rawRun = await _runRepository.getRawRun(run.id);

              // Extract screenshots for this competitor
              final screenshots =
                  (rawRun['screenshots'] as List<dynamic>?) ?? [];
              for (final s in screenshots) {
                if (s is! Map<String, dynamic>) continue;
                final competitorName =
                    (s['competitor'] ?? s['competitor_name'] ?? '')
                        .toString()
                        .toLowerCase();
                final compUrl =
                    foundCompetitor.url.toLowerCase();
                final compName =
                    foundCompetitor.name.toLowerCase();
                if (competitorName.contains(compName) ||
                    competitorName.contains(compUrl) ||
                    compUrl.contains(competitorName)) {
                  allScreenshots.add(s);
                }
              }

              // Extract reports for this competitor
              final reports =
                  (rawRun['reports'] as List<dynamic>?) ?? [];
              for (final report in reports) {
                if (report is! Map<String, dynamic>) continue;
                final reportCompetitor =
                    (report['competitor_name'] ??
                            report['competitor'] ??
                            '')
                        .toString()
                        .toLowerCase();
                final compUrl =
                    foundCompetitor.url.toLowerCase();
                final compName =
                    foundCompetitor.name.toLowerCase();

                if (reportCompetitor.contains(compName) ||
                    reportCompetitor.contains(compUrl) ||
                    compUrl.contains(reportCompetitor) ||
                    compName.contains(reportCompetitor)) {
                  final score =
                      (report['score'] as num?)?.toInt() ?? 0;
                  if (score > bestScore) {
                    bestScore = score;
                    bestSummary =
                        (report['summary'] as String?) ?? '';
                    final breakdown = (report['score_breakdown']
                            as Map<String, dynamic>?) ??
                        {};
                    bestBreakdown = breakdown.map(
                      (k, v) => MapEntry(k, (v as num).toInt()),
                    );
                  }

                  final recs = (report['recommendations']
                          as List<dynamic>?) ??
                      [];
                  for (final rec in recs) {
                    if (rec is Map<String, dynamic>) {
                      bestRecs.add(rec);
                    }
                  }
                }
              }

              // Also check overall_scores for competitor
              final overallScores =
                  (rawRun['overall_scores'] as List<dynamic>?) ?? [];
              for (final os in overallScores) {
                if (os is! Map<String, dynamic>) continue;
                final osName =
                    (os['competitor'] ?? os['name'] ?? '')
                        .toString()
                        .toLowerCase();
                final compUrl =
                    foundCompetitor.url.toLowerCase();
                final compName =
                    foundCompetitor.name.toLowerCase();
                if (osName.contains(compName) ||
                    osName.contains(compUrl)) {
                  final score =
                      (os['overall_score'] as num?)?.toInt() ?? 0;
                  if (score > bestScore) bestScore = score;
                  final catScores = (os['category_scores']
                          as Map<String, dynamic>?) ??
                      {};
                  if (catScores.isNotEmpty) {
                    bestBreakdown = catScores.map(
                      (k, v) => MapEntry(k, (v as num).toInt()),
                    );
                  }
                }
              }
            } catch (_) {
              // Skip failed runs
            }
          }
        } catch (_) {
          // Skip failed job
        }
      }

      setState(() {
        _overallScore = bestScore;
        _scoreBreakdown = bestBreakdown;
        _summary = bestSummary;
        _recommendations = bestRecs;
        _screenshots = allScreenshots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.surface0,
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError(c, l)
              : _buildContent(c, l),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(PulseSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(width: 200, height: 28),
          const SizedBox(height: PulseSpacing.base),
          const LoadingShimmer(width: 320, height: 100),
          const SizedBox(height: PulseSpacing.base),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: PulseSpacing.md),
              child: LoadingShimmer(height: 60, borderRadius: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PulseColors c, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: c.danger),
            const SizedBox(height: PulseSpacing.base),
            Text(
              l.competitorNotFound,
              style: PulseTypography.h3(color: c.textPrimary),
            ),
            const SizedBox(height: PulseSpacing.base),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Text(
                  l.back,
                  style: PulseTypography.body(color: c.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PulseColors c, AppLocalizations l) {
    final comp = _competitor!;
    final name = comp.name.isNotEmpty ? comp.name : comp.url;
    final domain = comp.url
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '');

    return RefreshIndicator(
      onRefresh: _loadCompetitorDetail,
      child: ListView(
        padding: const EdgeInsets.all(PulseSpacing.xl),
        children: [
          // Back + Name header
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: PulseRadii.borderSm,
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PulseSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: PulseTypography.h2(color: c.textPrimary),
                    ),
                    Text(
                      domain,
                      style: PulseTypography.mono(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PulseSpacing.xl),

          // Score card
          _buildScoreCard(c, l),
          const SizedBox(height: PulseSpacing.base),

          // Score breakdown
          if (_scoreBreakdown.isNotEmpty) ...[
            _buildScoreBreakdown(c, l),
            const SizedBox(height: PulseSpacing.base),
          ],

          // Screenshots
          if (_screenshots.isNotEmpty) ...[
            _buildScreenshots(c, l),
            const SizedBox(height: PulseSpacing.base),
          ],

          // Report summary
          if (_summary.isNotEmpty) ...[
            _buildSummaryCard(c, l),
            const SizedBox(height: PulseSpacing.base),
          ],

          // Recommendations
          if (_recommendations.isNotEmpty) ...[
            _buildRecommendations(c, l),
          ],

          // Empty state
          if (_overallScore == 0 &&
              _scoreBreakdown.isEmpty &&
              _screenshots.isEmpty &&
              _summary.isEmpty &&
              _recommendations.isEmpty)
            _buildNoData(c, l),

          const SizedBox(height: PulseSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildScoreCard(PulseColors c, AppLocalizations l) {
    final scoreColor = _scoreColor(_overallScore, c);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: PulseRadii.borderMd,
        border: Border.all(color: c.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xl),
        child: Row(
          children: [
            // Large score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _overallScore > 0 ? '$_overallScore' : '\u2014',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                    if (_overallScore > 0)
                      Text(
                        '/100',
                        style: PulseTypography.bodyLg(
                          color: c.textTertiary,
                        ),
                      ),
                  ],
                ),
                if (_scoreDelta != null)
                  Row(
                    children: [
                      Icon(
                        _scoreDelta! >= 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: _scoreDelta! >= 0
                            ? c.trendUp
                            : c.trendDown,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_scoreDelta! >= 0 ? '+' : ''}$_scoreDelta',
                        style: PulseTypography.label(
                          color: _scoreDelta! >= 0
                              ? c.trendUp
                              : c.trendDown,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Spacer(),
            // Score ring
            if (_overallScore > 0)
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _overallScore / 100,
                        backgroundColor: c.surface2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      l.avgScore,
                      style: PulseTypography.caption(
                          color: c.textTertiary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(PulseColors c, AppLocalizations l) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: PulseRadii.borderMd,
        border: Border.all(color: c.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.scoreBreakdownLabel,
              style: PulseTypography.label(color: c.textSecondary),
            ),
            const SizedBox(height: PulseSpacing.md),
            ..._scoreBreakdown.entries.map((entry) {
              final score = entry.value;
              final barColor = _scoreColor(score, c);
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: PulseSpacing.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        _formatLabel(entry.key),
                        style: PulseTypography.bodySm(
                            color: c.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score.clamp(0, 100) / 100,
                            backgroundColor: c.surface2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                barColor),
                            minHeight: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$score',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }

  Widget _buildScreenshots(PulseColors c, AppLocalizations l) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: PulseRadii.borderMd,
        border: Border.all(color: c.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.screenshotsSectionLabel,
              style: PulseTypography.label(color: c.textSecondary),
            ),
            const SizedBox(height: PulseSpacing.md),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _screenshots.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: PulseSpacing.sm),
                itemBuilder: (context, index) {
                  final s = _screenshots[index];
                  final screenshotId = s['id']?.toString();
                  final pageName =
                      (s['page_name'] as String?) ?? '';
                  final url = screenshotId != null
                      ? ApiConstants.screenshotImage(screenshotId)
                      : null;

                  return SizedBox(
                    width: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: PulseRadii.borderSm,
                            child: url != null
                                ? Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    width: 220,
                                    errorBuilder: (_, __, ___) =>
                                        DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: c.surface2,
                                      ),
                                      child: SizedBox(
                                        width: 220,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            color: c.textTertiary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: c.surface2,
                                    ),
                                    child: SizedBox(
                                      width: 220,
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_rounded,
                                          color: c.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (pageName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            pageName,
                            style: PulseTypography.caption(
                                color: c.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(PulseColors c, AppLocalizations l) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: PulseRadii.borderMd,
        border: Border.all(color: c.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.reportSummary,
              style: PulseTypography.label(color: c.textSecondary),
            ),
            const SizedBox(height: PulseSpacing.sm),
            Text(
              _summary,
              style: PulseTypography.body(color: c.textPrimary)
                  .copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(PulseColors c, AppLocalizations l) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: PulseRadii.borderMd,
        border: Border.all(color: c.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.keyRecommendations,
              style: PulseTypography.label(color: c.textSecondary),
            ),
            const SizedBox(height: PulseSpacing.md),
            ..._recommendations.take(8).map((rec) {
              final title = (rec['title'] ??
                      rec['action'] ??
                      rec['recommendation'] ??
                      '')
                  .toString();
              final description = (rec['description'] ??
                      rec['rationale'] ??
                      rec['reason'] ??
                      '')
                  .toString();
              final priority =
                  (rec['priority'] ?? rec['impact'] ?? '')
                      .toString()
                      .toLowerCase();

              final priorityColor = switch (priority) {
                'critical' || 'high' => c.danger,
                'medium' => c.warning,
                _ => c.textTertiary,
              };

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: PulseSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 6, height: 6),
                      ),
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (title.isNotEmpty)
                            Text(
                              title,
                              style: PulseTypography.body(
                                      color: c.textPrimary)
                                  .copyWith(
                                      fontWeight: FontWeight.w500),
                            ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: PulseTypography.bodySm(
                                  color: c.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildNoData(PulseColors c, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PulseSpacing.section),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: c.textTertiary,
            ),
            const SizedBox(height: PulseSpacing.base),
            Text(
              l.noReportData,
              style: PulseTypography.body(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score, PulseColors c) {
    if (score >= 80) return c.success;
    if (score >= 60) return c.accent;
    if (score >= 40) return c.warning;
    return c.danger;
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
