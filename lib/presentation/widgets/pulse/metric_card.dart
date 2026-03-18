import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';

/// A compact metric card for the dashboard top row.
///
/// Displays a [label] (tiny gray), a large [value] (bold white),
/// and an optional [subline] (tiny, optionally colored).
/// Ultra-subtle border, surface1 bg, no hover shadow lift.
///
/// Example:
/// ```dart
/// PulseMetricCard(
///   label: 'UX Score',
///   value: '87/100',
///   subline: '+5',
///   sublineColor: PulseColors.dark.trendUp,
/// )
/// ```
class PulseMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subline;
  final Color? sublineColor;
  final int? trendDelta;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PulseMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subline,
    this.sublineColor,
    this.trendDelta,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface1,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderDefault, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label (tiny gray)
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // Value (large bold) + optional trend
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  if (trendDelta != null) ...[
                    const SizedBox(width: 8),
                    _TrendBadge(delta: trendDelta!, colors: c),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              // Optional subline (tiny colored)
              if (subline != null) ...[
                const SizedBox(height: 4),
                Text(
                  subline!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: sublineColor ?? c.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend arrow badge: "^ +5" in green or "v -3" in red
// ---------------------------------------------------------------------------
class _TrendBadge extends StatelessWidget {
  final int delta;
  final PulseColors colors;

  const _TrendBadge({required this.delta, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final color = isPositive ? colors.trendUp : colors.trendDown;
    final arrow = isPositive ? '\u25B2' : '\u25BC';
    final sign = isPositive ? '+' : '';

    return Text(
      '$arrow $sign$delta',
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
