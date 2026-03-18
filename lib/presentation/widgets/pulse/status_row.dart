import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/tokens/colors.dart';

/// Access status for a competitor row.
enum CompetitorAccessStatus {
  /// Site is publicly accessible.
  public_,

  /// Site requires authentication.
  authRequired,

  /// Site is blocked / unreachable.
  blocked,
}

/// A single row in the competitor list panel.
///
/// Shows an icon/favicon, competitor name, URL (mono), status dot,
/// relative time label, and a hover-reveal action button.
class PulseStatusRow extends StatefulWidget {
  final String name;
  final String url;
  final CompetitorAccessStatus accessStatus;
  final String? timeAgo;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const PulseStatusRow({
    super.key,
    required this.name,
    required this.url,
    this.accessStatus = CompetitorAccessStatus.public_,
    this.timeAgo,
    this.onTap,
    this.onAction,
    this.actionIcon,
  });

  @override
  State<PulseStatusRow> createState() => _PulseStatusRowState();
}

class _PulseStatusRowState extends State<PulseStatusRow> {
  bool _isHovered = false;

  Color _dotColor(PulseColors c) {
    switch (widget.accessStatus) {
      case CompetitorAccessStatus.public_:
        return c.success;
      case CompetitorAccessStatus.authRequired:
        return c.warning;
      case CompetitorAccessStatus.blocked:
        return c.danger;
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered ? c.surface2 : Colors.transparent,
          ),
          child: Row(
            children: [
              // Favicon placeholder
              SizedBox(
                width: 28,
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      widget.name.isNotEmpty
                          ? widget.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + URL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      _shortenUrl(widget.url),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: c.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status dot
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dotColor(c),
                ),
              ),

              // Time ago
              if (widget.timeAgo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.timeAgo!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: c.textTertiary,
                    ),
                  ),
                ),

              // Hover action button
              AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _isHovered && widget.onAction != null ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: widget.onAction,
                  child: Icon(
                    widget.actionIcon ?? Icons.open_in_new,
                    size: 16,
                    color: c.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortenUrl(String url) {
    return url
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '');
  }
}
