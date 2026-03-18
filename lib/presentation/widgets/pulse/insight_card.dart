import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';

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

  Color _barColor(PulseColors c) {
    switch (widget.priority) {
      case InsightPriority.critical:
        return c.danger;
      case InsightPriority.high:
        return c.warning;
      case InsightPriority.medium:
        return c.info;
      case InsightPriority.low:
        return c.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;
    final barColor = _barColor(c);

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
            color: _isHovered ? c.surface2 : c.surface1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.borderDefault, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left color bar -- full height, 4px wide
                  Container(width: 4, color: barColor),

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
                              color: c.textPrimary,
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
                                color: c.textTertiary,
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
                                    bgColor:
                                        barColor.withValues(alpha: 0.1),
                                    textColor: barColor,
                                  ),
                                ...widget.competitorNames.map(
                                  (name) => _Pill(
                                    label: name,
                                    bgColor: c.surface2,
                                    textColor: c.textSecondary,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
