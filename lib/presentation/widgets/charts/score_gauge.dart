import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class ScoreGauge extends StatelessWidget {
  final int score;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? label;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 10,
    this.color,
    this.label,
  });

  Color get _scoreColor {
    if (color != null) return color!;
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.accentPrimary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreGaugePainter(
          score: score,
          color: _scoreColor,
          strokeWidth: strokeWidth,
          backgroundColor: Theme.of(context).dividerColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w700,
                  color: _scoreColor,
                ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreGaugePainter extends CustomPainter {
  final int score;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  _ScoreGaugePainter({
    required this.score,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    const fullAngle = 2 * math.pi;
    final sweepAngle = fullAngle * (score / 100.0);

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullAngle,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
