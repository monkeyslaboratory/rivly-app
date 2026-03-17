import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// TODO: Import from pulse_theme.dart / tokens when available
// import 'package:rivly/core/theme/pulse_theme.dart';

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

  Color _dotColor() {
    switch (widget.accessStatus) {
      case CompetitorAccessStatus.public_:
        return const Color(0xFF22C55E); // green
      case CompetitorAccessStatus.authRequired:
        return const Color(0xFFF59E0B); // amber
      case CompetitorAccessStatus.blocked:
        return const Color(0xFFEF4444); // red
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // TODO: Replace raw values with token references when available
    final textPrimary =
        isDark ? const Color(0xFFFAFAFA) : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final textMuted =
        isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF);
    final hoverBg = isDark
        ? const Color(0xFF27272A).withValues(alpha: 0.5)
        : const Color(0xFFF8F9FA);

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
            color: _isHovered ? hoverBg : Colors.transparent,
          ),
          child: Row(
            children: [
              // Favicon placeholder
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF27272A)
                      : const Color(0xFFF4F4F5),
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
                      color: textSecondary,
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
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shortenUrl(widget.url),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: textMuted,
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
                  color: _dotColor(),
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
                      color: textMuted,
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
                    color: textMuted,
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
