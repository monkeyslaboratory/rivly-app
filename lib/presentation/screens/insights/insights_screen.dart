import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
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
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildLoading();
          }

          if (state.error != null) {
            return _buildError(
                context, state.error!, l10n, textPrimary, textMuted);
          }

          if (state.insights.isEmpty) {
            return _buildEmpty(context, l10n, isDark, textPrimary, textMuted);
          }

          return _buildInsightsList(
              context, state, l10n, isDark, textPrimary, textMuted);
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
    Color textPrimary,
    Color textMuted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.error_outline_rounded,
                size: 24,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.somethingWentWrong,
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
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ScaleButton(
              onPressed: () =>
                  context.read<InsightsCubit>().loadInsights(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: textPrimary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.retry,
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
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkBgSubtle
                    : AppColors.lightBorder,
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 36,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noInsightsYet,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.runFirstAnalysis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ScaleButton(
              onPressed: () => context.go('/jobs'),
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
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkBg
                          : AppColors.lightBgElevated,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.viewAllJobs,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildInsightsList(
    BuildContext context,
    InsightsState state,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textMuted,
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
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.insightsSubtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 28),

          // Groups
          for (final entry in groups.entries) ...[
            _ImpactGroupHeader(
              impact: entry.key,
              count: entry.value.length,
              l10n: l10n,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            ...entry.value.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InsightCard(
                    insight: insight,
                    l10n: l10n,
                    isDark: isDark,
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
  final bool isDark;

  const _ImpactGroupHeader({
    required this.impact,
    required this.count,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = _impactColor(impact);
    final label = _impactLabel(impact, l10n);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
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
  final bool isDark;

  const _InsightCard({
    required this.insight,
    required this.l10n,
    required this.isDark,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final surfaceBg = widget.isDark
        ? AppColors.darkBgElevated
        : AppColors.lightBgElevated;
    final hoverBg = widget.isDark
        ? AppColors.darkBgSubtle.withValues(alpha: 0.5)
        : AppColors.lightBgSubtle;
    final borderColor =
        widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textMuted =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final impactColor = _impactColor(widget.insight.impact);
    final impactLabel = _impactLabel(widget.insight.impact, widget.l10n);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isHovered ? hoverBg : surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: !widget.isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority badge + title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppColors.darkBgSubtle
                        : AppColors.lightBgSubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${widget.insight.priority}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
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
                      color: textPrimary,
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
                  color: textMuted,
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
                  isDark: widget.isDark,
                ),
                // Effort chip
                _Chip(
                  label: '${widget.l10n.effort}: ${widget.insight.effort}',
                  color: textSecondary,
                  isDark: widget.isDark,
                  outlined: true,
                ),
                // Source label
                Text(
                  '${widget.l10n.fromAnalysis} ${widget.insight.competitorName} / ${widget.insight.category}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: textMuted,
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
  final bool isDark;
  final bool outlined;

  const _Chip({
    required this.label,
    required this.color,
    required this.isDark,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: outlined
            ? Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              )
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// -- Helpers --

Color _impactColor(String impact) {
  switch (impact.toLowerCase()) {
    case 'critical':
      return AppColors.error;
    case 'high':
      return AppColors.accentHot;
    case 'medium':
      return AppColors.warning;
    case 'low':
      return AppColors.accentSecondary;
    default:
      return AppColors.warning;
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
