import 'package:flutter/material.dart';

/// Legacy color palette — kept for backward compatibility with existing screens.
/// New screens should use [PulseColors] from `tokens/colors.dart` instead.
class AppColors {
  // Brand
  static const accentPrimary = Color(0xFFFF6B2C);
  static const accentWarm = Color(0xFFFF8F5C);
  static const accentHot = Color(0xFFFF4500);
  static const accentSecondary = Color(0xFF6366F1);
  static const accentSecondaryLight = Color(0xFF818CF8);

  // Dark theme — Zinc palette
  static const darkBg = Color(0xFF09090B);
  static const darkBgSecondary = Color(0xFF111111);
  static const darkBgElevated = Color(0xFF18181B);
  static const darkBgSubtle = Color(0xFF27272A);
  static const darkTextPrimary = Color(0xFFFAFAFA);
  static const darkTextSecondary = Color(0xFFA1A1AA);
  static const darkTextMuted = Color(0xFF71717A);
  static const darkBorder = Color(0xFF27272A);

  // Light theme — Zinc palette (gray background, white cards)
  static const lightBg = Color(0xFFF4F4F5);
  static const lightBgSecondary = Color(0xFFFFFFFF);
  static const lightBgElevated = Color(0xFFFFFFFF);
  static const lightBgSubtle = Color(0xFFF4F4F5);
  static const lightTextPrimary = Color(0xFF09090B);
  static const lightTextSecondary = Color(0xFF71717A);
  static const lightTextMuted = Color(0xFFA1A1AA);
  static const lightBorder = Color(0xFFE4E4E7);

  // Status
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}
