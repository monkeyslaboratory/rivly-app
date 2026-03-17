import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: Import from pulse_theme.dart / tokens when available
// import 'package:rivly/core/theme/pulse_theme.dart';

/// Priority level for an insight, controlling the left color bar.
enum InsightPriority {
  critical,
  high,
  medium,
  low,
}

/// THE most important component on the dashboard.
///
/// Displays an insight with a left color bar indicating priority,
/// a title, impact description, category/competitor pills,
/// and hover shadow lift. Clicking navigates to the report.
class PulseInsightCard extends StatefulWidget {
  final String title;
  final String? impact;
  final InsightPriority priority;
  final String? category;
  final List<String> competitorNames;
  final VoidCallback? onTap;

  const PulseInsightCard({
    super.key,
    required this.title,
    this.impact,
    this.priority = InsightPriority.medium,
    this.category,
    this.competitorNames = const [],
    this.onTap,
  });

  @override
  State<PulseInsightCard> createState() => _PulseInsightCardState();
}

class _PulseInsightCardState extends State<PulseInsightCard> {
  bool _isHovered = false;

  // TODO: Pull from tokens/pulse_theme when ready
  static const _shadowSm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const _shadowMd = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  Color _barColor() {
    switch (widget.priority) {
      case InsightPriority.critical:
        return const Color(0xFFEF4444); // red
      case InsightPriority.high:
        return const Color(0xFFF59E0B); // amber
      case InsightPriority.medium:
        return const Color(0xFF14B8A6); // teal
      case InsightPriority.low:
        return const Color(0xFF9CA3AF); // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // TODO: Replace raw values with token references when available
    final surface1 = isDark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    final borderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0x0D000000);
    final textPrimary =
        isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A2E);
    final textMuted =
        isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
    final pillBg = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFF4F4F5);
    final pillText = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF6B7280);

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
          decoration: BoxDecoration(
            color: surface1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDark
                ? null
                : (_isHovered ? _shadowMd : _shadowSm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left color bar — full height, 4px wide
                  Container(
                    width: 4,
                    color: _barColor(),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textPrimary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Impact line
                          if (widget.impact != null &&
                              widget.impact!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.impact!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: textMuted,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // Tags row
                          if (widget.category != null ||
                              widget.competitorNames.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (widget.category != null)
                                  _Pill(
                                    label: widget.category!,
                                    bgColor: _barColor().withValues(alpha: 0.1),
                                    textColor: _barColor(),
                                  ),
                                ...widget.competitorNames.map(
                                  (name) => _Pill(
                                    label: name,
                                    bgColor: pillBg,
                                    textColor: pillText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
