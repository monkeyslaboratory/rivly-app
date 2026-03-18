import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/shadows.dart';
import '../../../core/theme/tokens/spacing.dart';

/// Dashboard widget showing competitive market position with animated score bars.
///
/// Example:
/// ```dart
/// MarketPositionWidget(key: ValueKey('market_position'))
/// ```
class MarketPositionWidget extends StatefulWidget {
  const MarketPositionWidget({super.key});

  @override
  State<MarketPositionWidget> createState() => _MarketPositionWidgetState();
}

class _MarketPositionWidgetState extends State<MarketPositionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovered = false;

  static const _mockData = <_RankEntry>[
    _RankEntry(name: 'Stripe', score: 92, isOurs: false),
    _RankEntry(name: 'Figma', score: 91, isOurs: false),
    _RankEntry(name: 'Linear', score: 88, isOurs: false),
    _RankEntry(name: 'You', score: 87, isOurs: true),
    _RankEntry(name: 'Notion', score: 85, isOurs: false),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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

    // Sort by score descending, find "You" rank
    final sorted = List<_RankEntry>.from(_mockData)
      ..sort((a, b) => b.score.compareTo(a.score));
    final ourRank = sorted.indexWhere((e) => e.isOurs) + 1;
    final maxScore = sorted.isNotEmpty ? sorted.first.score : 100;

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
                  'Market position',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.10),
                    borderRadius: PulseRadii.borderFull,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PulseSpacing.sm,
                      vertical: 2,
                    ),
                    child: Text(
                      '#$ourRank of ${sorted.length}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PulseSpacing.md),
            // Ranked bars
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      for (var i = 0; i < sorted.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < sorted.length - 1 ? 6.0 : 0,
                          ),
                          child: _RankedBar(
                            rank: i + 1,
                            entry: sorted[i],
                            maxScore: maxScore,
                            progress: _barProgress(i),
                            colors: c,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _barProgress(int index) {
    // 250ms base + 40ms stagger per item
    final totalDuration = 450.0;
    final start = (40.0 * index) / totalDuration;
    final end = (250.0 + 40.0 * index) / totalDuration;
    final t = ((_controller.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(t);
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _RankEntry {
  final String name;
  final int score;
  final bool isOurs;

  const _RankEntry({
    required this.name,
    required this.score,
    this.isOurs = false,
  });
}

// ---------------------------------------------------------------------------
// Ranked bar row
// ---------------------------------------------------------------------------

class _RankedBar extends StatelessWidget {
  final int rank;
  final _RankEntry entry;
  final int maxScore;
  final double progress;
  final PulseColors colors;

  const _RankedBar({
    required this.rank,
    required this.entry,
    required this.maxScore,
    required this.progress,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final fraction = maxScore > 0
        ? ((entry.score / maxScore) * progress).clamp(0.0, 1.0)
        : 0.0;

    final barColor = entry.isOurs ? c.accent : c.textTertiary.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: entry.isOurs ? c.accent.withValues(alpha: 0.03) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: entry.isOurs
            ? Border(left: BorderSide(color: c.accent, width: 2))
            : null,
      ),
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: EdgeInsets.only(left: entry.isOurs ? 6.0 : 0),
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 16,
                child: Text(
                  '$rank',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: c.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: PulseSpacing.xs),
              // Name
              SizedBox(
                width: 48,
                child: Text(
                  entry.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: entry.isOurs ? c.accent : c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: PulseSpacing.sm),
              // Score bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(PulseRadii.sm),
                  child: SizedBox(
                    height: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surface2.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(PulseRadii.sm),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(PulseRadii.sm),
                            boxShadow: entry.isOurs
                                ? [
                                    BoxShadow(
                                      color: c.accent.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: PulseSpacing.sm),
              // Score number
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.score}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: entry.isOurs ? c.accent : c.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
