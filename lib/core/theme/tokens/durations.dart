import 'package:flutter/animation.dart';

/// Pulse Design System — Animation duration & curve tokens.
class PulseDurations {
  PulseDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve entranceCurve = Cubic(0.16, 1, 0.3, 1);
  static const Curve exitCurve = Curves.easeOut;
}
