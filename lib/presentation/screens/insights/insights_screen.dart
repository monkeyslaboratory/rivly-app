import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../logic/insights/insights_cubit.dart';
import '../../../logic/insights/insights_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/scale_button.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the global InsightsCubit; trigger a refresh on screen entry
    context.read<InsightsCubit>().loadInsights();
    return const _InsightsBody();
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;

    return Scaffold(
      backgroundColor: c.surface0,
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildLoading();
          }

          if (state.error != null) {
            return _buildError(context, state.error!, l10n, c);
          }

          if (state.insights.isEmpty) {
            return _buildEmpty(context, l10n, c);
          }

          return _buildInsightsList(context, state, l10n, c);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(width: 180, height: 28),
          const SizedBox(height: 8),
          const LoadingShimmer(width: 320, height: 16),
          const SizedBox(height: 32),
          ...List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LoadingShimmer(height: 120, borderRadius: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    String error,
    AppLocalizations l10n,
    PulseColors c,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                  Icons.error_outline_rounded,
                  size: 24,
                  color: c.danger,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.somethingWentWrong,
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
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ScaleButton(
              onPressed: () =>
                  context.read<InsightsCubit>().loadInsights(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: c.borderDefault),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          size: 18, color: c.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.retry,
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
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    AppLocalizations l10n,
    PulseColors c,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surface2,
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 36,
                  color: c.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noInsightsYet,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.runFirstAnalysis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ScaleButton(
              onPressed: () => context.go('/jobs'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.viewAllJobs,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  Widget _buildInsightsList(
    BuildContext context,
    InsightsState state,
    AppLocalizations l10n,
    PulseColors c,
  ) {
    // Group by impact level
    final groups = <String, List<AggregatedInsight>>{
      'critical': [],
      'high': [],
      'medium': [],
      'low': [],
    };

    for (final insight in state.insights) {
      final key =
          groups.containsKey(insight.impact) ? insight.impact : 'medium';
      groups[key]!.add(insight);
    }

    groups.removeWhere((_, v) => v.isEmpty);

    return RefreshIndicator(
      onRefresh: () => context.read<InsightsCubit>().loadInsights(),
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          // Page title
          Text(
            l10n.insights,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.insightsSubtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // Groups
          for (final entry in groups.entries) ...[
            _ImpactGroupHeader(
              impact: entry.key,
              count: entry.value.length,
              l10n: l10n,
              colors: c,
            ),
            const SizedBox(height: 12),
            ...entry.value.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightCard(
                    insight: insight,
                    l10n: l10n,
                    colors: c,
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// -- Impact Group Header --

class _ImpactGroupHeader extends StatelessWidget {
  final String impact;
  final int count;
  final AppLocalizations l10n;
  final PulseColors colors;

  const _ImpactGroupHeader({
    required this.impact,
    required this.count,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final color = _impactColor(impact, c);
    final label = _impactLabel(impact, l10n);

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -- Insight Card --

class _InsightCard extends StatefulWidget {
  final AggregatedInsight insight;
  final AppLocalizations l10n;
  final PulseColors colors;

  const _InsightCard({
    required this.insight,
    required this.l10n,
    required this.colors,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final impactColor = _impactColor(widget.insight.impact, c);
    final impactLabel = _impactLabel(widget.insight.impact, widget.l10n);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isHovered ? c.surface2 : c.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderDefault, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority badge + title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    child: Text(
                      '#${widget.insight.priority}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.insight.action,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),

            // Rationale
            if (widget.insight.rationale.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.insight.rationale,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Bottom row: impact chip + effort chip + source
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Impact chip
                _Chip(
                  label: '${widget.l10n.impact}: $impactLabel',
                  color: impactColor,
                  colors: c,
                ),
                // Effort chip
                _Chip(
                  label: '${widget.l10n.effort}: ${widget.insight.effort}',
                  color: c.textSecondary,
                  colors: c,
                  outlined: true,
                ),
                // Source label
                Text(
                  '${widget.l10n.fromAnalysis} ${widget.insight.competitorName} / ${widget.insight.category}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -- Small Chip Widget --

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final PulseColors colors;
  final bool outlined;

  const _Chip({
    required this.label,
    required this.color,
    required this.colors,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: outlined
            ? Border.all(color: c.borderDefault, width: 1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// -- Helpers --

Color _impactColor(String impact, PulseColors c) {
  switch (impact.toLowerCase()) {
    case 'critical':
      return c.danger;
    case 'high':
      return c.warning;
    case 'medium':
      return c.info;
    case 'low':
      return c.textTertiary;
    default:
      return c.warning;
  }
}

String _impactLabel(String impact, AppLocalizations l10n) {
  switch (impact.toLowerCase()) {
    case 'critical':
      return l10n.critical;
    case 'high':
      return l10n.high;
    case 'medium':
      return l10n.medium2;
    case 'low':
      return l10n.low;
    default:
      return l10n.medium2;
  }
}
