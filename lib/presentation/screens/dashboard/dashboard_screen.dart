import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../data/models/competitor_model.dart';
import '../../../logic/dashboard/dashboard_cubit.dart';
import '../../../logic/dashboard/dashboard_state.dart';
import '../../../logic/insights/insights_cubit.dart';
import '../../../logic/insights/insights_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/scale_button.dart';
import '../../widgets/job_creation_modal.dart';
import '../../widgets/pulse/metric_card.dart';
import '../../widgets/pulse/status_row.dart';
import '../../widgets/pulse/insight_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;

  // Stagger animations for sections
  late final Animation<double> _metricsOpacity;
  late final Animation<Offset> _metricsSlide;
  late final Animation<double> _middleOpacity;
  late final Animation<Offset> _middleSlide;
  late final Animation<double> _insightsOpacity;
  late final Animation<Offset> _insightsSlide;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
    context.read<InsightsCubit>().loadInsights();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Metric cards: 0ms - 300ms
    _metricsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.375, curve: Curves.easeOut),
      ),
    );
    _metricsSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.375, curve: Curves.easeOut),
      ),
    );

    // Middle section: 150ms - 500ms
    _middleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.1875, 0.625, curve: Curves.easeOut),
      ),
    );
    _middleSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.1875, 0.625, curve: Curves.easeOut),
      ),
    );

    // Insights: 300ms - 800ms
    _insightsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.375, 1.0, curve: Curves.easeOut),
      ),
    );
    _insightsSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.375, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _openCreateModal() {
    JobCreationModal.show(
      context,
      onJobCreated: () {
        context.read<DashboardCubit>().loadDashboard();
        context.read<InsightsCubit>().loadInsights();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, dashState) {
        if (dashState.isLoading && dashState.jobs.isEmpty) {
          return LoadingShimmer.list(count: 5);
        }

        if (dashState.error != null && dashState.jobs.isEmpty) {
          return _buildErrorState(context, dashState.error!);
        }

        if (dashState.jobs.isEmpty) {
          return _buildEmptyState(context);
        }

        // Trigger entrance animation when data arrives
        if (_staggerController.status == AnimationStatus.dismissed) {
          _staggerController.forward();
        }

        return BlocBuilder<InsightsCubit, InsightsState>(
          builder: (context, insightsState) {
            return _buildDashboardContent(context, dashState, insightsState);
          },
        );
      },
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardState state,
    InsightsState insightsState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    // --- Compute metric values ---
    final totalJobs = state.jobs.length;
    final activeRuns = state.recentRuns.where((r) => r.isRunning).length;

    // Last completed run
    final completedRuns =
        state.recentRuns.where((r) => r.isCompleted).toList();
    String lastReportValue = l.noReportsYet;
    String? lastReportSubline;
    if (completedRuns.isNotEmpty) {
      final lastRun = completedRuns.first;
      final jobForRun = state.jobs
          .where((j) => j.id == lastRun.jobId)
          .toList();
      lastReportValue =
          jobForRun.isNotEmpty ? jobForRun.first.name : lastRun.id.substring(0, 8);
      lastReportSubline = DateFormat.yMMMd().format(lastRun.completedAt ?? lastRun.createdAt);
    }

    // Avg score placeholder (no overall_scores in current data model)
    // TODO: Compute from report data when available
    const avgScoreDisplay = '\u2014';

    // --- Deduplicated competitors ---
    final Map<String, CompetitorModel> competitorMap = {};
    for (final job in state.jobs) {
      for (final comp in job.competitors) {
        competitorMap.putIfAbsent(comp.url, () => comp);
      }
    }
    final allCompetitors = competitorMap.values.toList();

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<DashboardCubit>().loadDashboard(),
              context.read<InsightsCubit>().loadInsights(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              // ── Header ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.dashboard,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.overviewSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleButton(
                    onPressed: _openCreateModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: isDark
                                ? AppColors.darkBg
                                : AppColors.lightBgElevated,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.newJob,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkBg
                                  : AppColors.lightBgElevated,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Metric Cards (top row, stagger 1) ──
              FadeTransition(
                opacity: _metricsOpacity,
                child: SlideTransition(
                  position: _metricsSlide,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth =
                          (constraints.maxWidth - 48) / 4; // 3 gaps * 16
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: cardWidth.clamp(180, double.infinity),
                            child: PulseMetricCard(
                              label: l.lastReport,
                              value: lastReportValue,
                              subline: lastReportSubline,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth.clamp(180, double.infinity),
                            child: PulseMetricCard(
                              label: l.totalJobs,
                              value: '$totalJobs',
                            ),
                          ),
                          SizedBox(
                            width: cardWidth.clamp(180, double.infinity),
                            child: PulseMetricCard(
                              label: l.activeRuns,
                              value: '$activeRuns',
                              trailing: activeRuns > 0
                                  ? _PulseDot()
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: cardWidth.clamp(180, double.infinity),
                            child: PulseMetricCard(
                              label: l.avgScore,
                              value: avgScoreDisplay,
                              subline: '/100',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Middle row: Competitors + Activity (stagger 2) ──
              FadeTransition(
                opacity: _middleOpacity,
                child: SlideTransition(
                  position: _middleSlide,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        // Stack on narrow screens
                        return Column(
                          children: [
                            _CompetitorPanel(
                              competitors: allCompetitors,
                              isDark: isDark,
                              onAddCompetitor: _openCreateModal,
                            ),
                            const SizedBox(height: 16),
                            _ActivityPanel(
                              runs: state.recentRuns,
                              jobs: state.jobs,
                              isDark: isDark,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _CompetitorPanel(
                              competitors: allCompetitors,
                              isDark: isDark,
                              onAddCompetitor: _openCreateModal,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ActivityPanel(
                              runs: state.recentRuns,
                              jobs: state.jobs,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Insights block (bottom hero, stagger 3) ──
              FadeTransition(
                opacity: _insightsOpacity,
                child: SlideTransition(
                  position: _insightsSlide,
                  child: _InsightsBlock(
                    insights: insightsState.insights,
                    isLoading: insightsState.isLoading,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty state (preserved from original)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkBgSubtle : AppColors.lightBorder,
              ),
              child: Icon(
                Icons.insights,
                size: 36,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.noAnalysesYet,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.setUpFirstAnalysis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ScaleButton(
              onPressed: _openCreateModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.createFirstAnalysis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkBg
                            : AppColors.lightBgElevated,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: isDark
                          ? AppColors.darkBg
                          : AppColors.lightBgElevated,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.freePlanInfo,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Error state (preserved from original)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, String error) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 24,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.somethingWentWrong,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ScaleButton(
                onPressed: () =>
                    context.read<DashboardCubit>().loadDashboard(),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 18, color: textPrimary),
                      const SizedBox(width: 8),
                      Text(
                        l.tryAgain,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Pulse Dot — animated indicator for active runs
// =============================================================================
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981)
                .withValues(alpha: 0.5 + _controller.value * 0.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981)
                    .withValues(alpha: 0.3 * _controller.value),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// Competitor Panel
// =============================================================================
class _CompetitorPanel extends StatelessWidget {
  final List<CompetitorModel> competitors;
  final bool isDark;
  final VoidCallback? onAddCompetitor;

  const _CompetitorPanel({
    required this.competitors,
    required this.isDark,
    this.onAddCompetitor,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface1 = isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated;
    final borderColor = isDark
        ? AppColors.darkBorder
        : const Color(0x0D000000);

    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  l.competitorsLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBgSubtle
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${competitors.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          if (competitors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                l.noDataYet,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: competitors.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0x0D000000),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final comp = competitors[index];
                  return PulseStatusRow(
                    name: comp.name.isNotEmpty ? comp.name : comp.url,
                    url: comp.url,
                    accessStatus: _mapAccessStatus(comp.accessStatus),
                  );
                },
              ),
            ),

          // Ghost button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ScaleButton(
              onPressed: onAddCompetitor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: textMuted),
                  const SizedBox(width: 4),
                  Text(
                    l.addCompetitor,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  CompetitorAccessStatus _mapAccessStatus(String status) {
    switch (status) {
      case 'auth_required':
        return CompetitorAccessStatus.authRequired;
      case 'blocked':
        return CompetitorAccessStatus.blocked;
      default:
        return CompetitorAccessStatus.public_;
    }
  }
}

// =============================================================================
// Activity Feed Panel
// =============================================================================
class _ActivityPanel extends StatelessWidget {
  final List<dynamic> runs;
  final List<dynamic> jobs;
  final bool isDark;

  const _ActivityPanel({
    required this.runs,
    required this.jobs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final surface1 = isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated;
    final borderColor = isDark
        ? AppColors.darkBorder
        : const Color(0x0D000000);

    // Build activity items with time grouping
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final todayRuns = runs.where((r) => r.createdAt.isAfter(todayStart)).toList();
    final yesterdayRuns = runs
        .where((r) =>
            r.createdAt.isAfter(yesterdayStart) &&
            r.createdAt.isBefore(todayStart))
        .toList();
    final earlierRuns = runs
        .where((r) => r.createdAt.isBefore(yesterdayStart))
        .toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 360),
      decoration: BoxDecoration(
        color: surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l.recentActivity,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),

          if (runs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                l.noDataYet,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                ),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (todayRuns.isNotEmpty) ...[
                      _GroupLabel(label: l.today, isDark: isDark),
                      ...todayRuns.map((r) => _ActivityItem(
                            run: r,
                            jobs: jobs,
                            isDark: isDark,
                          )),
                    ],
                    if (yesterdayRuns.isNotEmpty) ...[
                      _GroupLabel(label: l.yesterday, isDark: isDark),
                      ...yesterdayRuns.map((r) => _ActivityItem(
                            run: r,
                            jobs: jobs,
                            isDark: isDark,
                          )),
                    ],
                    if (earlierRuns.isNotEmpty) ...[
                      _GroupLabel(label: l.earlier, isDark: isDark),
                      ...earlierRuns.map((r) => _ActivityItem(
                            run: r,
                            jobs: jobs,
                            isDark: isDark,
                          )),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _GroupLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActivityItem extends StatefulWidget {
  final dynamic run;
  final List<dynamic> jobs;
  final bool isDark;

  const _ActivityItem({
    required this.run,
    required this.jobs,
    required this.isDark,
  });

  @override
  State<_ActivityItem> createState() => _ActivityItemState();
}

class _ActivityItemState extends State<_ActivityItem> {
  bool _isHovered = false;

  String _activityText(AppLocalizations l) {
    final jobMatch = widget.jobs.where((j) => j.id == widget.run.jobId).toList();
    final jobName = jobMatch.isNotEmpty ? jobMatch.first.name : widget.run.jobId;

    if (widget.run.isCompleted) return l.analysisCompleted2;
    if (widget.run.isFailed) return l.runFailed2;
    return l.runStartedFor(jobName);
  }

  Color get _statusColor {
    if (widget.run.isCompleted) return AppColors.success;
    if (widget.run.isFailed) return AppColors.error;
    if (widget.run.isRunning) return AppColors.accentSecondary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = widget.isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final hoverBg = widget.isDark
        ? AppColors.darkBgSubtle.withValues(alpha: 0.5)
        : const Color(0xFFF8F9FA);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.run.isRunning) {
            context.go('/runs/${widget.run.id}');
          } else if (widget.run.isCompleted) {
            context.go('/reports/${widget.run.id}');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _isHovered ? hoverBg : Colors.transparent,
          child: Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                ),
              ),
              const SizedBox(width: 10),
              // Description
              Expanded(
                child: Text(
                  _activityText(l),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.run.status.toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Time
              Text(
                DateFormat.Hm().format(widget.run.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Insights Block (hero section)
// =============================================================================
class _InsightsBlock extends StatefulWidget {
  final List<AggregatedInsight> insights;
  final bool isLoading;
  final bool isDark;

  const _InsightsBlock({
    required this.insights,
    required this.isLoading,
    required this.isDark,
  });

  @override
  State<_InsightsBlock> createState() => _InsightsBlockState();
}

class _InsightsBlockState extends State<_InsightsBlock> {
  String _activeFilter = 'all';

  List<AggregatedInsight> get _filteredInsights {
    if (_activeFilter == 'all') return widget.insights;
    return widget.insights
        .where((i) => i.impact == _activeFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted = widget.isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final surface1 =
        widget.isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated;
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : const Color(0x0D000000);

    return Container(
      decoration: BoxDecoration(
        color: surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: widget.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(
                  l.improvementOpportunities,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.darkBgSubtle
                        : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.insights.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter pills
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Wrap(
              spacing: 8,
              children: [
                _FilterPill(
                  label: l.all,
                  isActive: _activeFilter == 'all',
                  onTap: () => setState(() => _activeFilter = 'all'),
                  isDark: widget.isDark,
                ),
                _FilterPill(
                  label: l.critical,
                  isActive: _activeFilter == 'critical',
                  color: const Color(0xFFEF4444),
                  onTap: () => setState(() => _activeFilter = 'critical'),
                  isDark: widget.isDark,
                ),
                _FilterPill(
                  label: l.high,
                  isActive: _activeFilter == 'high',
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _activeFilter = 'high'),
                  isDark: widget.isDark,
                ),
                _FilterPill(
                  label: l.medium2,
                  isActive: _activeFilter == 'medium',
                  color: const Color(0xFF14B8A6),
                  onTap: () => setState(() => _activeFilter = 'medium'),
                  isDark: widget.isDark,
                ),
                _FilterPill(
                  label: l.low,
                  isActive: _activeFilter == 'low',
                  color: const Color(0xFF9CA3AF),
                  onTap: () => setState(() => _activeFilter = 'low'),
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),

          // Content
          if (widget.isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: LoadingShimmer.list(count: 3, itemHeight: 80),
            )
          else if (_filteredInsights.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Text(
                l.noInsightsYet,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textMuted,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filteredInsights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final insight = _filteredInsights[index];
                return PulseInsightCard(
                  title: insight.action,
                  impact: insight.rationale,
                  priority: _mapPriority(insight.impact),
                  category: insight.category,
                  competitorNames: [insight.competitorName],
                  onTap: () => context.go('/reports/${insight.runId}'),
                );
              },
            ),
        ],
      ),
    );
  }

  InsightPriority _mapPriority(String impact) {
    switch (impact) {
      case 'critical':
        return InsightPriority.critical;
      case 'high':
        return InsightPriority.high;
      case 'low':
        return InsightPriority.low;
      default:
        return InsightPriority.medium;
    }
  }
}

// =============================================================================
// Filter Pill
// =============================================================================
class _FilterPill extends StatefulWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterPill({
    required this.label,
    required this.isActive,
    this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_FilterPill> createState() => _FilterPillState();
}

class _FilterPillState extends State<_FilterPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final defaultBg = widget.isDark
        ? AppColors.darkBgSubtle
        : const Color(0xFFF4F4F5);
    final activeBg = widget.color?.withValues(alpha: 0.15) ?? defaultBg;
    final activeText = widget.color ??
        (widget.isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary);
    final inactiveText = widget.isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : (_isHovered ? defaultBg : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
            border: widget.isActive
                ? Border.all(
                    color: (widget.color ?? activeText).withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
              color: widget.isActive ? activeText : inactiveText,
            ),
          ),
        ),
      ),
    );
  }
}
