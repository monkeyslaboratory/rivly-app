import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';

/// A Rivly-pattern competitor score row.
///
/// Displays an avatar circle with initial, name + domain (mono, tertiary),
/// score (bold), optional trend delta arrow, and a mini progress bar.
/// Each row is a standalone card with surface1 bg, borderDefault, 10px radius.
///
/// Example:
/// ```dart
/// CompetitorScoreRow(
///   name: 'Figma',
///   domain: 'figma.com',
///   initial: 'F',
///   score: 87,
///   scoreDelta: 5,
///   onTap: () {},
/// )
/// ```
class CompetitorScoreRow extends StatefulWidget {
  final String name;
  final String domain;
  final String initial;
  final int score; // 0-100
  final int? scoreDelta; // +5 or -3
  final VoidCallback? onTap;

  const CompetitorScoreRow({
    super.key,
    required this.name,
    required this.domain,
    required this.initial,
    required this.score,
    this.scoreDelta,
    this.onTap,
  });

  @override
  State<CompetitorScoreRow> createState() => _CompetitorScoreRowState();
}

class _CompetitorScoreRowState extends State<CompetitorScoreRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? c.surface2 : c.surface1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.borderDefault, width: 1),
          ),
          child: Row(
            children: [
              // Avatar circle -- 40px (radius 20), surface2 bg
              CircleAvatar(
                radius: 20,
                backgroundColor: c.surface2,
                child: Text(
                  widget.initial,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + domain
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.domain,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: c.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Score + trend + mini bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.score}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      if (widget.scoreDelta != null) ...[
                        const SizedBox(width: 6),
                        _TrendArrow(
                          delta: widget.scoreDelta!,
                          colors: c,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Mini progress bar -- 80px wide, 3px tall, accent fill
                  SizedBox(
                    width: 80,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: widget.score.clamp(0, 100) / 100,
                        backgroundColor: c.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(c.accent),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trend arrow: "^ +3" or "v -2"
// ---------------------------------------------------------------------------
class _TrendArrow extends StatelessWidget {
  final int delta;
  final PulseColors colors;

  const _TrendArrow({required this.delta, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final color = isPositive ? colors.trendUp : colors.trendDown;
    final arrow = isPositive ? '\u25B2' : '\u25BC';
    final sign = isPositive ? '+' : '';

    return Text(
      '$arrow $sign$delta',
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
