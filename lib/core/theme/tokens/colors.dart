import 'package:flutter/material.dart';

/// Pulse Design System — Color tokens.
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
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderDefault,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.statusActive,
    required this.statusPending,
    required this.statusFailed,
    required this.statusBlocked,
  });

  // ── Core ──────────────────────────────────────────────────────────────
  final Color primary;
  final Color accent;

  // ── Surfaces ──────────────────────────────────────────────────────────
  final Color surface0; // page background
  final Color surface1; // card background
  final Color surface2; // nested / hover

  // ── Text ──────────────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ── Border ────────────────────────────────────────────────────────────
  final Color borderDefault;

  // ── Semantic ──────────────────────────────────────────────────────────
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  // ── Status ────────────────────────────────────────────────────────────
  final Color statusActive;
  final Color statusPending;
  final Color statusFailed;
  final Color statusBlocked;

  // ── Presets ───────────────────────────────────────────────────────────

  static const light = PulseColors._(
    primary: Color(0xFF1A1A2E),
    accent: Color(0xFF10B981),
    surface0: Color(0xFFF8F9FA),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFF1F3F5),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    borderDefault: Color(0x0D000000), // black ~5 %
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    statusActive: Color(0xFF10B981),
    statusPending: Color(0xFFF59E0B),
    statusFailed: Color(0xFFEF4444),
    statusBlocked: Color(0xFF6B7280),
  );

  static const dark = PulseColors._(
    primary: Color(0xFF1A1A2E),
    accent: Color(0xFF10B981),
    surface0: Color(0xFF0F0F14),
    surface1: Color(0xFF1A1A24),
    surface2: Color(0xFF252530),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    borderDefault: Color(0x14FFFFFF), // white ~8 %
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
    statusActive: Color(0xFF10B981),
    statusPending: Color(0xFFF59E0B),
    statusFailed: Color(0xFFEF4444),
    statusBlocked: Color(0xFF6B7280),
  );
}
