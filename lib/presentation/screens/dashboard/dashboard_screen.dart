import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../data/models/competitor_model.dart';
import '../../../logic/dashboard/dashboard_cubit.dart';
import '../../../logic/dashboard/dashboard_state.dart';
import '../../../logic/insights/insights_cubit.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/scale_button.dart';
import '../../widgets/job_creation_modal.dart';
import '../../widgets/pulse/metric_card.dart';
import '../../widgets/pulse/competitor_score_row.dart';
import '../../widgets/pulse/widget_score_pulse.dart';
import '../../widgets/pulse/widget_gap_priority.dart';
import '../../widgets/pulse/widget_market_position.dart';
import '../../widgets/pulse/widget_pop_pod.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;

  late final Animation<double> _metricsOpacity;
  late final Animation<Offset> _metricsSlide;
  late final Animation<double> _competitorsOpacity;
  late final Animation<Offset> _competitorsSlide;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Metric cards: 0ms - 300ms
    _metricsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _metricsSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Competitor rows: 150ms - 600ms
    _competitorsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
      ),
    );
    _competitorsSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
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

        return _buildDashboardContent(context, dashState);
      },
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;
    final l = AppLocalizations.of(context);

    // --- Compute metric values ---
    final totalCompetitors = _deduplicatedCompetitors(state).length;

    // UX Score placeholder
    // TODO(tech): Compute from actual report data when available
    const uxScoreDisplay = '\u2014';

    // Changes this week
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final changesThisWeek =
        state.recentRuns.where((r) => r.createdAt.isAfter(weekAgo)).length;

    // Next run
    String nextRunDisplay = l.manual;
    for (final job in state.jobs) {
      if (job.scheduleFrequency != 'one_time') {
        nextRunDisplay = _computeNextRun(job.scheduleFrequency);
        break;
      }
    }

    // --- Deduplicated competitors ---
    final allCompetitors = _deduplicatedCompetitors(state);

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await context.read<DashboardCubit>().loadDashboard();
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // -- Metric Cards (4 in a row, no title) --
              FadeTransition(
                opacity: _metricsOpacity,
                child: SlideTransition(
                  position: _metricsSlide,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: PulseMetricCard(
                            label: l.avgScore,
                            value: uxScoreDisplay,
                            subline: '/100',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PulseMetricCard(
                            label: l.competitorsLabel,
                            value: '$totalCompetitors',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PulseMetricCard(
                            label: l.nextRun,
                            value: nextRunDisplay,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // -- Changes banner --
              FadeTransition(
                opacity: _metricsOpacity,
                child: _ChangesBanner(
                  changesCount: changesThisWeek,
                  competitors: allCompetitors,
                  recentRuns: state.recentRuns,
                  colors: c,
                ),
              ),
              const SizedBox(height: 16),

              // -- Dashboard Widgets Row (4 columns) --
              FadeTransition(
                opacity: _competitorsOpacity,
                child: SlideTransition(
                  position: _competitorsSlide,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 800;
                      if (isWide) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              Expanded(child: ScorePulseWidget()),
                              SizedBox(width: 12),
                              Expanded(child: GapPriorityWidget()),
                              SizedBox(width: 12),
                              Expanded(child: MarketPositionWidget()),
                              SizedBox(width: 12),
                              Expanded(child: PopPodWidget()),
                            ],
                          ),
                        );
                      }
                      // Narrow: 2x2 grid
                      return Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                Expanded(child: ScorePulseWidget()),
                                SizedBox(width: 12),
                                Expanded(child: GapPriorityWidget()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                Expanded(child: MarketPositionWidget()),
                                SizedBox(width: 12),
                                Expanded(child: PopPodWidget()),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // -- Competitor score rows (full width) --
              FadeTransition(
                opacity: _competitorsOpacity,
                child: SlideTransition(
                  position: _competitorsSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allCompetitors.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              l.noDataYet,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: c.textTertiary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...allCompetitors.map((comp) {
                          final name =
                              comp.name.isNotEmpty ? comp.name : comp.url;
                          final domain = _shortenUrl(comp.url);
                          final initial =
                              name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CompetitorScoreRow(
                              name: name,
                              domain: domain,
                              initial: initial,
                              score:
                                  0, // TODO(tech): Wire to actual score data
                              scoreDelta: null,
                              onTap: () {
                                context.push('/competitors/${comp.id}');
                              },
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<CompetitorModel> _deduplicatedCompetitors(DashboardState state) {
    final Map<String, CompetitorModel> competitorMap = {};
    for (final job in state.jobs) {
      for (final comp in job.competitors) {
        competitorMap.putIfAbsent(comp.url, () => comp);
      }
    }
    return competitorMap.values.toList();
  }

  String _shortenUrl(String url) {
    return url
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '');
  }

  String _computeNextRun(String frequency) {
    switch (frequency) {
      case 'weekly':
        return '~7d';
      case 'biweekly':
        return '~14d';
      case 'monthly':
        return '~30d';
      default:
        return '\u2014';
    }
  }

  // ---------------------------------------------------------------------------
  // Empty state -- minimal, centered
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l.noAnalysesYet,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.setUpFirstAnalysis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ScaleButton(
              onPressed: _openCreateModal,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Text(
                    l.createFirstAnalysis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger insights load for the Top Gaps widget
    context.read<InsightsCubit>().loadInsights();
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------
  Widget _buildErrorState(BuildContext context, String error) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.borderDefault),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.danger.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.error_outline,
                        size: 24,
                        color: c.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.somethingWentWrong,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ScaleButton(
                    onPressed: () =>
                        context.read<DashboardCubit>().loadDashboard(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: c.borderDefault),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh,
                                size: 18, color: c.textPrimary),
                            const SizedBox(width: 8),
                            Text(
                              l.tryAgain,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Changes banner -- shows recent changes count + competitor avatars
// ---------------------------------------------------------------------------

class _ChangesBanner extends StatelessWidget {
  final int changesCount;
  final List<dynamic> competitors;
  final List<dynamic> recentRuns;
  final PulseColors colors;

  const _ChangesBanner({
    required this.changesCount,
    required this.competitors,
    required this.recentRuns,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    // Find competitors that had changes (runs this week)
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final changedJobIds = <String>{};
    for (final run in recentRuns) {
      try {
        final createdAt = run.createdAt;
        if (createdAt.isAfter(weekAgo)) {
          changedJobIds.add(run.jobId ?? '');
        }
      } catch (_) {}
    }

    // Get unique competitor initials
    final changedCompetitors = <Map<String, String>>[];
    for (final comp in competitors) {
      final name = (comp is CompetitorModel) ? comp.name : (comp.name ?? '?');
      if (changedCompetitors.length < 5) {
        changedCompetitors.add({
          'name': name,
          'initial': name.isNotEmpty ? name[0].toUpperCase() : '?',
        });
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.borderDefault),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Changes count
            Text(
              '$changesCount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: changesCount > 0 ? c.textPrimary : c.textTertiary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    changesCount > 0
                        ? 'changes this week'
                        : 'No changes yet',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: changesCount > 0 ? c.trendUp : c.textTertiary,
                    ),
                  ),
                  if (changesCount == 0)
                    Text(
                      'Run an analysis to start tracking',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: c.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            // Competitor avatars (overlapping stack)
            if (changedCompetitors.isNotEmpty)
              SizedBox(
                height: 32,
                width: 32.0 + (changedCompetitors.length - 1) * 22,
                child: Stack(
                  children: [
                    for (var i = 0; i < changedCompetitors.length; i++)
                      Positioned(
                        left: i * 22.0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.surface1, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            changedCompetitors[i]['initial']!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

