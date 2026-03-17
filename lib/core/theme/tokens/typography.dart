import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pulse Design System — Typography tokens.
///
/// Display / heading: Plus Jakarta Sans (distinctive but not decorative).
/// Body: Inter (clean workhorse).
/// Mono: JetBrains Mono.
class PulseTypography {
  PulseTypography._();

  // ── Display / Headings ────────────────────────────────────────────────

  static TextStyle display({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle h1({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Body ──────────────────────────────────────────────────────────────

  static TextStyle bodyLg({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySm({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // ── Labels ────────────────────────────────────────────────────────────

  static TextStyle label({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle labelSm({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // ── Mono ──────────────────────────────────────────────────────────────

  static TextStyle mono({Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // ── Metric ────────────────────────────────────────────────────────────

  static TextStyle metricValue({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle metricLabel({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
