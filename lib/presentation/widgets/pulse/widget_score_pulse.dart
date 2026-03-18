import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';
import '../../../core/theme/tokens/radii.dart';
import '../../../core/theme/tokens/shadows.dart';
import '../../../core/theme/tokens/spacing.dart';

/// Dashboard widget showing the UX Score with a sparkline chart, trend badge,
/// and competitor average reference line.
///
/// Example:
/// ```dart
/// ScorePulseWidget(key: ValueKey('score_pulse'))
/// ```
class ScorePulseWidget extends StatefulWidget {
  const ScorePulseWidget({super.key});

  @override
  State<ScorePulseWidget> createState() => _ScorePulseWidgetState();
}

class _ScorePulseWidgetState extends State<ScorePulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _lineProgress;
  bool _isHovered = false;

  static const _mockData = <double>[72, 75, 73, 78, 80, 77, 82, 85, 84, 87];
  static const _competitorAvg = 79.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _lineProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
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
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'UX Score',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
                const Spacer(),
                // Trend badge
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
                      '\u25B2 +5',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.trendUp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: PulseSpacing.xs),
            // Score value
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '87',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '/100',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Sparkline chart
            SizedBox(
              height: 60,
              child: AnimatedBuilder(
                animation: _lineProgress,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: _SparklinePainter(
                      data: _mockData,
                      competitorAvg: _competitorAvg,
                      progress: _lineProgress.value,
                      lineColor: c.accent,
                      avgLineColor: c.textTertiary,
                      avgLabelColor: c.textTertiary,
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
}

// ---------------------------------------------------------------------------
// Sparkline CustomPainter
// ---------------------------------------------------------------------------

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final double competitorAvg;
  final double progress;
  final Color lineColor;
  final Color avgLineColor;
  final Color avgLabelColor;

  _SparklinePainter({
    required this.data,
    required this.competitorAvg,
    required this.progress,
    required this.lineColor,
    required this.avgLineColor,
    required this.avgLabelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minVal = data.reduce(math.min) - 5;
    final maxVal = data.reduce(math.max) + 5;
    final range = maxVal - minVal;

    double yOf(double value) {
      return size.height - ((value - minVal) / range) * size.height;
    }

    double xOf(int index) {
      return (index / (data.length - 1)) * size.width;
    }

    // -- Competitor avg dashed line --
    final avgY = yOf(competitorAvg);
    final dashPaint = Paint()
      ..color = avgLineColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashGap = 3.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, avgY),
        Offset(math.min(startX + dashWidth, size.width), avgY),
        dashPaint,
      );
      startX += dashWidth + dashGap;
    }

    // "avg" label
    final avgTextPainter = TextPainter(
      text: TextSpan(
        text: 'avg',
        style: TextStyle(
          fontSize: 9,
          color: avgLabelColor.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    avgTextPainter.paint(
      canvas,
      Offset(size.width - avgTextPainter.width, avgY - avgTextPainter.height - 2),
    );

    // -- Build smooth path --
    final visibleCount = (data.length * progress).ceil().clamp(1, data.length);
    final path = Path();
    path.moveTo(xOf(0), yOf(data[0]));

    for (var i = 1; i < visibleCount; i++) {
      final x0 = xOf(i - 1);
      final y0 = yOf(data[i - 1]);
      final x1 = xOf(i);
      final y1 = yOf(data[i]);
      final cpx = (x0 + x1) / 2;
      path.cubicTo(cpx, y0, cpx, y1, x1, y1);
    }

    // -- Area fill gradient --
    final fillPath = Path.from(path);
    final lastVisibleX = xOf(visibleCount - 1);
    final lastVisibleY = yOf(data[visibleCount - 1]);
    fillPath.lineTo(lastVisibleX, size.height);
    fillPath.lineTo(xOf(0), size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withValues(alpha: 0.15),
        lineColor.withValues(alpha: 0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    // -- Line stroke --
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // -- Last point dot with pulse glow --
    if (progress > 0.8) {
      final dotX = lastVisibleX;
      final dotY = lastVisibleY;
      final pulseAlpha = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);

      // Glow
      canvas.drawCircle(
        Offset(dotX, dotY),
        6.0 * pulseAlpha,
        Paint()..color = lineColor.withValues(alpha: 0.2 * pulseAlpha),
      );
      // Dot
      canvas.drawCircle(
        Offset(dotX, dotY),
        3.0,
        Paint()..color = lineColor,
      );
      // Inner
      canvas.drawCircle(
        Offset(dotX, dotY),
        1.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.lineColor != lineColor;
}
