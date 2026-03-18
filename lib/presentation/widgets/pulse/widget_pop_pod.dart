import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/shadows.dart';
import '../../../core/theme/tokens/spacing.dart';

/// Dashboard widget showing PoP (Points of Parity) and PoD (Points of
/// Difference) as a donut chart with legend.
///
/// Example:
/// ```dart
/// PopPodWidget(key: ValueKey('pop_pod'))
/// ```
class PopPodWidget extends StatefulWidget {
  const PopPodWidget({super.key});

  @override
  State<PopPodWidget> createState() => _PopPodWidgetState();
}

class _PopPodWidgetState extends State<PopPodWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHovered = false;

  // Mock data
  static const _covered = 30;
  static const _gaps = 3;
  static const _advantages = 6;
  static const _opportunities = 8;
  static const _total = _covered + _gaps + _advantages + _opportunities;

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

    final segments = <_DonutSegment>[
      _DonutSegment(
        value: _covered.toDouble(),
        color: c.textSecondary.withValues(alpha: 0.4),
        label: 'Covered',
        count: _covered,
      ),
      _DonutSegment(
        value: _gaps.toDouble(),
        color: c.danger,
        label: 'Gaps',
        count: _gaps,
        isAlert: _gaps > 0,
      ),
      _DonutSegment(
        value: _advantages.toDouble(),
        color: c.accent,
        label: 'Our edge',
        count: _advantages,
        hasGlow: true,
      ),
      _DonutSegment(
        value: _opportunities.toDouble(),
        color: c.warning.withValues(alpha: 0.6),
        label: 'Opportunity',
        count: _opportunities,
      ),
    ];

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
            Text(
              'Parity check',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: PulseSpacing.md),
            // Donut + Legend
            Expanded(
              child: Row(
                children: [
                  // Donut chart
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                          size: const Size(80, 80),
                          painter: _DonutPainter(
                            segments: segments,
                            progress: CurvedAnimation(
                              parent: _controller,
                              curve: Curves.easeOutCubic,
                            ).value,
                            centerTextColor: c.textPrimary,
                            centerLabelColor: c.textTertiary,
                            total: _total,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: PulseSpacing.base),
                  // Legend
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final seg in segments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _LegendItem(
                              segment: seg,
                              colors: c,
                            ),
                          ),
                      ],
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

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _DonutSegment {
  final double value;
  final Color color;
  final String label;
  final int count;
  final bool isAlert;
  final bool hasGlow;

  const _DonutSegment({
    required this.value,
    required this.color,
    required this.label,
    required this.count,
    this.isAlert = false,
    this.hasGlow = false,
  });
}

// ---------------------------------------------------------------------------
// Donut CustomPainter
// ---------------------------------------------------------------------------

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double progress;
  final Color centerTextColor;
  final Color centerLabelColor;
  final int total;

  _DonutPainter({
    required this.segments,
    required this.progress,
    required this.centerTextColor,
    required this.centerLabelColor,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 10.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final totalValue = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (totalValue == 0) return;

    var startAngle = -math.pi / 2; // Start from top
    final sweepTotal = 2 * math.pi * progress;
    final gapAngle = 0.03; // Small gap between segments

    for (final seg in segments) {
      final sweepAngle = (seg.value / totalValue) * sweepTotal - gapAngle;
      if (sweepAngle <= 0) {
        startAngle += (seg.value / totalValue) * sweepTotal;
        continue;
      }

      // Glow for accent segment
      if (seg.hasGlow && progress > 0.5) {
        final glowPaint = Paint()
          ..color = seg.color.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      }

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + gapAngle;
    }

    // Center text
    if (progress > 0.3) {
      final countPainter = TextPainter(
        text: TextSpan(
          text: '$total',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: centerTextColor,
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      countPainter.paint(
        canvas,
        Offset(
          center.dx - countPainter.width / 2,
          center.dy - countPainter.height / 2 - 4,
        ),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: 'features',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: centerLabelColor,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          center.dx - labelPainter.width / 2,
          center.dy + countPainter.height / 2 - 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// Legend item
// ---------------------------------------------------------------------------

class _LegendItem extends StatelessWidget {
  final _DonutSegment segment;
  final PulseColors colors;

  const _LegendItem({
    required this.segment,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Row(
      children: [
        // Color square
        DecoratedBox(
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: PulseSpacing.sm),
        // Label
        Expanded(
          child: Text(
            segment.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: segment.isAlert ? c.danger : c.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Count
        Text(
          '${segment.count}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: segment.isAlert ? c.danger : c.textPrimary,
          ),
        ),
      ],
    );
  }
}
