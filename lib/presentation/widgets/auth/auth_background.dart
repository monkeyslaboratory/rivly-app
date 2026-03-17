import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'threejs_background_stub.dart'
    if (dart.library.html) 'threejs_background_web.dart';

/// Animated background for auth screens.
/// On web: real Three.js hero scene (same as landing page) via iframe.
/// On mobile: Flutter CustomPainter fallback with animated gradient blobs.
class AuthBackground extends StatefulWidget {
  const AuthBackground({super.key});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _viewType;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (kIsWeb) {
      // Register only once
      _viewType ??= 'threejs-hero-${DateTime.now().millisecondsSinceEpoch}';
      registerThreeJsBackground(_viewType!, isDark);
      return HtmlElementView(viewType: _viewType!);
    }

    // Mobile fallback
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BackgroundPainter(
              time: _controller.value * 120,
              isDark: isDark,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile fallback painter
// ---------------------------------------------------------------------------

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({required this.time, required this.isDark});
  final double time;
  final bool isDark;

  static const _darkPalette = [Color(0xFF4338CA), Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFFFF6B2C), Color(0xFFFF4500)];
  static const _lightPalette = [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFFA5B4FC), Color(0xFFFF8F5C), Color(0xFFFFB088)];

  @override
  void paint(Canvas canvas, Size size) {
    final palette = isDark ? _darkPalette : _lightPalette;
    final bgColor = isDark ? const Color(0xFF050505) : const Color(0xFFFAFAFA);
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    // Gradient blobs
    final blobs = [
      (0.3, 0.35, 0.45, 0.07, 0.05, 0.0, 1.2, palette[0], palette[1]),
      (0.7, 0.55, 0.40, 0.05, 0.08, 2.1, 0.5, palette[1], palette[2]),
      (0.5, 0.45, 0.35, 0.09, 0.06, 4.0, 3.3, palette[3], palette[4]),
      (0.4, 0.6, 0.30, 0.06, 0.07, 1.5, 5.0, palette[2], palette[3]),
    ];
    for (final b in blobs) {
      final dx = b.$1 + 0.12 * sin(time * b.$4 + b.$6);
      final dy = b.$2 + 0.10 * cos(time * b.$5 + b.$7);
      final r = b.$3 * (1.0 + 0.15 * sin(time * 0.3 + b.$6 + b.$7)) * size.shortestSide;
      final center = Offset(dx * size.width, dy * size.height);
      final color = Color.lerp(b.$8, b.$9, (sin(time * 0.15 + b.$6) + 1) / 2)!;
      canvas.drawCircle(center, r, Paint()
        ..shader = ui.Gradient.radial(center, r, [color.withValues(alpha: isDark ? 0.55 : 0.40), color.withValues(alpha: 0.0)], [0.0, 1.0])
        ..blendMode = BlendMode.plus);
    }

    // Particles
    final rng = Random(42);
    final pColor = isDark ? const Color(0xFFFF6B2C) : const Color(0xFFFF8F5C);
    for (var i = 0; i < 60; i++) {
      final sx = rng.nextDouble(), sy = rng.nextDouble();
      final speed = 0.02 + rng.nextDouble() * 0.04;
      final pr = 1.2 + rng.nextDouble() * 2.0;
      final ab = 0.15 + rng.nextDouble() * 0.35;
      final x = (sx + sin(time * 0.02 + i) * 0.03) % 1.0;
      var y = (sy - time * speed) % 1.0; if (y < 0) y += 1.0;
      final a = ab * (0.5 + 0.5 * sin(time * 0.5 + i * 0.7)).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x * size.width, y * size.height), pr, Paint()..color = pColor.withValues(alpha: a));
    }

    // Overlay + grain
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor.withValues(alpha: isDark ? 0.35 : 0.45));
    final grng = Random(time.toInt() * 7 + 31);
    final gp = Paint()..color = (isDark ? const Color(0x0DFFFFFF) : const Color(0x0D000000));
    for (var i = 0; i < 400; i++) {
      canvas.drawRect(Rect.fromLTWH(grng.nextDouble() * size.width, grng.nextDouble() * size.height, 1.2, 1.2), gp);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) => old.time != time || old.isDark != isDark;
}
