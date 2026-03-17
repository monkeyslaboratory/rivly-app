import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/sidebar/sidebar_cubit.dart';
import '../../../logic/sidebar/sidebar_state.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/theme/theme_state.dart';
import '../common/rivly_logo.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return BlocBuilder<SidebarCubit, SidebarState>(
      builder: (context, sidebarState) {
        final collapsed = sidebarState.isCollapsed;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: collapsed ? 64 : 240,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSecondary : AppColors.lightBgSecondary,
            border: Border(
              right: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, top: 20, bottom: 0),
                child: Align(
                  alignment:
                      collapsed ? Alignment.center : Alignment.centerLeft,
                  child: RivlyLogo(
                    size: 28,
                    showText: !collapsed,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Nav items
              _SidebarNavItem(
                icon: Icons.grid_view_rounded,
                label: l.dashboard,
                index: 0,
                collapsed: collapsed,
              ),
              _SidebarNavItem(
                icon: Icons.work_outline_rounded,
                label: l.jobs,
                index: 1,
                collapsed: collapsed,
              ),
              _SidebarNavItem(
                icon: Icons.lightbulb_outline_rounded,
                label: l.insights,
                index: 2,
                collapsed: collapsed,
              ),

              const Spacer(),

              // Settings
              _SidebarNavItem(
                icon: Icons.settings_outlined,
                label: l.settings,
                index: 3,
                collapsed: collapsed,
              ),

              const SizedBox(height: 8),

              // Divider
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 12 : 16,
                ),
                child: Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),

              // User section
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  String initials = '?';
                  String displayName = l.user;

                  if (authState is Authenticated) {
                    final username = authState.user.username;
                    displayName = username;
                    if (username.isNotEmpty) {
                      final parts = username.split(' ');
                      if (parts.length >= 2) {
                        initials =
                            '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                      } else {
                        initials = username.substring(0, 1).toUpperCase();
                      }
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: collapsed ? 12 : 16,
                      vertical: 12,
                    ),
                    child: collapsed
                        ? Center(
                            child: _UserAvatar(
                              initials: initials,
                              isDark: isDark,
                            ),
                          )
                        : Row(
                            children: [
                              _UserAvatar(
                                initials: initials,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              _HoverIconButton(
                                icon: Icons.logout_rounded,
                                size: 18,
                                isDark: isDark,
                                tooltip: l.logout,
                                onTap: () =>
                                    context.read<AuthCubit>().logout(),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// User avatar — neutral gray, no orange
// ---------------------------------------------------------------------------
class _UserAvatar extends StatelessWidget {
  final String initials;
  final bool isDark;

  const _UserAvatar({required this.initials, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hover icon button for sidebar bottom actions
// ---------------------------------------------------------------------------
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final bool isDark;
  final String? tooltip;
  final VoidCallback onTap;

  const _HoverIconButton({
    required this.icon,
    required this.size,
    required this.isDark,
    required this.onTap,
    this.tooltip,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.isDark
                      ? AppColors.darkBgSubtle
                      : AppColors.lightBgSubtle)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.size,
                color: _isHovered
                    ? (widget.isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                    : (widget.isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action item (theme toggle, etc.)
// ---------------------------------------------------------------------------
class _SidebarBottomAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool collapsed;
  final bool isDark;
  final VoidCallback onTap;

  const _SidebarBottomAction({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SidebarBottomAction> createState() => _SidebarBottomActionState();
}

class _SidebarBottomActionState extends State<_SidebarBottomAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle;
    final iconColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.collapsed ? 12 : 12,
        vertical: 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            decoration: BoxDecoration(
              color: _isHovered ? hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 12,
            ),
            child: widget.collapsed
                ? Center(
                    child: Icon(widget.icon, size: 18, color: iconColor),
                  )
                : Row(
                    children: [
                      Icon(widget.icon, size: 18, color: iconColor),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav Item — no orange, just subtle bg fills
// ---------------------------------------------------------------------------
class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool collapsed;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.collapsed,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  int _activeIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/jobs') ||
        path.startsWith('/runs') ||
        path.startsWith('/reports')) {
      return 1;
    }
    if (path.startsWith('/insights')) return 2;
    if (path.startsWith('/settings')) return 3;
    return -1;
  }

  void _onTap(BuildContext context) {
    switch (widget.index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/jobs');
      case 2:
        context.go('/insights');
      case 3:
        context.go('/settings');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = _activeIndex(context) == widget.index;

    // Colors — no orange
    final activeTextColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final inactiveTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textColor = isActive ? activeTextColor : inactiveTextColor;

    Color bgColor;
    if (isActive) {
      bgColor = isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle;
    } else if (_isHovered) {
      bgColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);
    } else {
      bgColor = Colors.transparent;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.collapsed ? 12 : 12,
        vertical: 2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.index >= 0 ? () => _onTap(context) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 12,
            ),
            child: widget.collapsed
                ? Center(
                    child: Icon(widget.icon, size: 18, color: textColor),
                  )
                : Row(
                    children: [
                      Icon(widget.icon, size: 18, color: textColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: widget.collapsed ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            widget.label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
