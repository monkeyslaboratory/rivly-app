import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RivlyLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final Color? textColor;

  const RivlyLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final circleColor = color ?? Theme.of(context).colorScheme.onSurface;
    final labelColor = textColor ?? Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            size: Size(size, size),
            painter: _RivlyLogoPainter(
              circleColor: circleColor,
              triangleColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Text(
            'Rivly',
            style: GoogleFonts.inter(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w700,
              color: labelColor,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _RivlyLogoPainter extends CustomPainter {
  final Color circleColor;
  final Color triangleColor;

  _RivlyLogoPainter({
    required this.circleColor,
    required this.triangleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32;

    // Draw circle
    final circlePaint = Paint()..color = circleColor;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );

    // Draw upward-pointing triangle: M16 8L23.5 22H8.5L16 8Z
    final trianglePaint = Paint()..color = triangleColor;
    final path = Path()
      ..moveTo(16 * scale, 8 * scale)
      ..lineTo(23.5 * scale, 22 * scale)
      ..lineTo(8.5 * scale, 22 * scale)
      ..close();
    canvas.drawPath(path, trianglePaint);
  }

  @override
  bool shouldRepaint(_RivlyLogoPainter oldDelegate) {
    return oldDelegate.circleColor != circleColor ||
        oldDelegate.triangleColor != triangleColor;
  }
}
