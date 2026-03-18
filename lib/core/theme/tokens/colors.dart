import 'package:flutter/material.dart';

/// Pulse Design System — Color tokens (dark-first).
///
/// Use [PulseColors.light] or [PulseColors.dark] to obtain the palette for the
/// current brightness. Individual screens should never hard-code hex values;
/// always reference the token instead.
class PulseColors {
  const PulseColors._({
    required this.primary,
    required this.accent,
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderDefault,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.trendUp,
    required this.trendDown,
    required this.statusActive,
    required this.statusPending,
    required this.statusFailed,
    required this.statusBlocked,
  });

  // -- Core --
  final Color primary;
  final Color accent; // electric blue #3B82F6

  // -- Surfaces --
  final Color surface0; // page background
  final Color surface1; // card background
  final Color surface2; // hover / active background
  final Color surface3; // selected state

  // -- Text --
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // -- Border --
  final Color borderDefault;

  // -- Semantic --
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // -- Trends --
  final Color trendUp;
  final Color trendDown;

  // -- Status --
  final Color statusActive;
  final Color statusPending;
  final Color statusFailed;
  final Color statusBlocked;

  // -- Presets --

  /// Dark theme (PRIMARY) -- near-black surfaces, electric blue accent.
  static const dark = PulseColors._(
    primary: Color(0xFF0F0F14),
    accent: Color(0xFF3B82F6),
    surface0: Color(0xFF0F0F14),
    surface1: Color(0xFF1A1A24),
    surface2: Color(0xFF24242E),
    surface3: Color(0xFF2E2E3A),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFF8B8B9E),
    textTertiary: Color(0xFF5C5C6E),
    borderDefault: Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    trendUp: Color(0xFF4ADE80),
    trendDown: Color(0xFFF87171),
    statusActive: Color(0xFF4ADE80),
    statusPending: Color(0xFFFBBF24),
    statusFailed: Color(0xFFF87171),
    statusBlocked: Color(0xFF5C5C6E),
  );

  /// Light theme -- clean surfaces, electric blue accent.
  static const light = PulseColors._(
    primary: Color(0xFF1A1A2E),
    accent: Color(0xFF3B82F6),
    surface0: Color(0xFFF8F9FA),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1F3F5),
    surface3: Color(0xFFE8E9EB),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    borderDefault: Color(0x0F000000), // rgba(0,0,0,0.06)
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    trendUp: Color(0xFF22C55E),
    trendDown: Color(0xFFEF4444),
    statusActive: Color(0xFF22C55E),
    statusPending: Color(0xFFF59E0B),
    statusFailed: Color(0xFFEF4444),
    statusBlocked: Color(0xFF6B7280),
  );
}
