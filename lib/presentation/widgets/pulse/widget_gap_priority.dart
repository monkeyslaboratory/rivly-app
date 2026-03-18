import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/shadows.dart';
import '../../../core/theme/tokens/spacing.dart';
import '../../../logic/insights/insights_cubit.dart';
import '../../../logic/insights/insights_state.dart';

/// Dashboard widget showing the top 3 priority gaps with staggered entrance.
///
/// Example:
/// ```dart
/// GapPriorityWidget(key: ValueKey('gap_priority'))
/// ```
class GapPriorityWidget extends StatefulWidget {
  const GapPriorityWidget({super.key});

  @override
  State<GapPriorityWidget> createState() => _GapPriorityWidgetState();
}

class _GapPriorityWidgetState extends State<GapPriorityWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;

    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, insightsState) {
        // Get top 3 critical/high insights, else fall back to mock
        final realInsights = insightsState.insights
            .where((i) => i.impact == 'critical' || i.impact == 'high')
            .take(3)
            .toList();

        final items = realInsights.isNotEmpty
            ? realInsights
                .asMap()
                .entries
                .map((e) => _GapItem(
                      name: e.value.action,
                      coverage: '${e.value.priority}/5',
                      dotColor: e.value.impact == 'critical'
                          ? c.danger
                          : e.key == 2
                              ? c.accent
                              : c.warning,
                    ))
                .toList()
            : <_GapItem>[
                _GapItem(name: 'Onboarding flow', coverage: '2/5', dotColor: c.danger),
                _GapItem(name: 'Search experience', coverage: '3/5', dotColor: c.warning),
                _GapItem(name: 'Mobile nav', coverage: '4/5', dotColor: c.accent),
              ];

        final gapCount = realInsights.isNotEmpty ? realInsights.length : 3;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 180,
            decoration: BoxDecoration(
              color: c.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderDefault),
              boxShadow: _isHovered ? PulseShadows.sm : null,
            ),
            padding: const EdgeInsets.all(PulseSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Top gaps',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.danger.withValues(alpha: 0.12),
                        borderRadius: PulseRadii.borderFull,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          '$gapCount',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: c.danger,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PulseSpacing.md),
                // Gap items with stagger
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        _StaggeredGapRow(
                          item: items[i],
                          colors: c,
                          controller: _controller,
                          index: i,
                        ),
                    ],
                  ),
                ),
                // Footer
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go('/insights'),
                    child: _HoverUnderlineText(
                      text: 'View all insights \u2192',
                      color: c.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _GapItem {
  final String name;
  final String coverage;
  final Color dotColor;

  const _GapItem({
    required this.name,
    required this.coverage,
    required this.dotColor,
  });
}

// ---------------------------------------------------------------------------
// Staggered gap row
// ---------------------------------------------------------------------------

class _StaggeredGapRow extends StatelessWidget {
  final _GapItem item;
  final PulseColors colors;
  final AnimationController controller;
  final int index;

  const _StaggeredGapRow({
    required this.item,
    required this.colors,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // Stagger: 60ms per item
    final start = (index * 0.15).clamp(0.0, 0.7);
    final end = (start + 0.5).clamp(0.0, 1.0);

    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: PulseSpacing.xs),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface2.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(PulseRadii.sm),
            ),
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PulseSpacing.md),
                child: Row(
                  children: [
                    // Priority dot
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: item.dotColor,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox(width: 8, height: 8),
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    // Feature name
                    Expanded(
                      child: Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: PulseSpacing.sm),
                    // Coverage
                    Text(
                      item.coverage,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hover underline text
// ---------------------------------------------------------------------------

class _HoverUnderlineText extends StatefulWidget {
  final String text;
  final Color color;

  const _HoverUnderlineText({required this.text, required this.color});

  @override
  State<_HoverUnderlineText> createState() => _HoverUnderlineTextState();
}

class _HoverUnderlineTextState extends State<_HoverUnderlineText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Text(
        widget.text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: widget.color,
          decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
          decorationColor: widget.color,
        ),
      ),
    );
  }
}
