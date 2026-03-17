import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: Import from pulse_theme.dart / tokens when available
// import 'package:rivly/core/theme/pulse_theme.dart';

/// A premium metric card for the dashboard top row.
///
/// Displays a [label], a large [value], an optional colored [subline],
/// and an optional [trailing] widget (e.g. sparkline or badge).
/// Hover lifts with shadow transition (sm -> md) over 120ms.
class PulseMetricCard extends StatefulWidget {
  final String label;
  final String value;
  final String? subline;
  final Color? sublineColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const PulseMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subline,
    this.sublineColor,
    this.trailing,
    this.onTap,
  });

  @override
  State<PulseMetricCard> createState() => _PulseMetricCardState();
}

class _PulseMetricCardState extends State<PulseMetricCard> {
  bool _isHovered = false;

  // TODO: Pull from tokens/pulse_theme when ready
  static const _shadowSm = [
    BoxShadow(
      color: Color(0x0A000000), // rgba(0,0,0,0.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const _shadowMd = [
    BoxShadow(
      color: Color(0x0F000000), // rgba(0,0,0,0.06)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // TODO: Replace raw values with token references when available
    final surface1 = isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0x0D000000); // rgba(0,0,0,0.05)
    final textPrimary =
        isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A2E);
    final textMuted =
        isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);

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
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minWidth: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDark
                ? null
                : (_isHovered ? _shadowMd : _shadowSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (widget.subline != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subline!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: widget.sublineColor ?? textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
