import 'package:flutter/material.dart';

/// Pulse Design System — Shadow tokens.
class PulseShadows {
  PulseShadows._();

  static const sm = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
    ),
  ];

  static const md = [
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 12,
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
    ),
  ];

  static const lg = [
    BoxShadow(
      offset: Offset(0, 12),
      blurRadius: 32,
      color: Color(0x14000000), // rgba(0,0,0,0.08)
    ),
  ];
}
