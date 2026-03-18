import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/tokens/colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/sidebar/sidebar_cubit.dart';
import '../../../logic/sidebar/sidebar_state.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../job_creation_modal.dart';

/// Rivly sidebar -- Figma-inspired dark glass design.
///
/// Features:
/// - Top user section with avatar, role, name, collapse toggle
/// - Sectioned nav with icons and expandable sub-items
/// - Active state with accent left border + surface2 bg
/// - Bottom CTA card (expanded only)
/// - Smooth 200ms collapse animation
class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _overviewExpanded = false;

  int _activeIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/jobs') ||
        path.startsWith('/runs') ||
        path.startsWith('/competitors')) {
      return 1;
    }
    if (path.startsWith('/feature-matrix') || path.startsWith('/reports')) {
      return 2;
    }
    if (path.startsWith('/insights')) return 3;
    if (path.startsWith('/settings')) return 4;
    return -1;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/jobs');
      case 2:
        context.go('/feature-matrix');
      case 3:
        context.go('/insights');
      case 4:
        context.go('/settings');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = isDark ? PulseColors.dark : PulseColors.light;
    final l = AppLocalizations.of(context);
    final activeIndex = _activeIndex(context);

    return BlocBuilder<SidebarCubit, SidebarState>(
      builder: (context, sidebarState) {
        final collapsed = sidebarState.isCollapsed;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: collapsed ? 68 : 240,
          decoration: BoxDecoration(
            color: c.surface1,
            border: Border(
              right: BorderSide(color: c.borderDefault, width: 1),
            ),
          ),
          child: Column(
            children: [
              // -- User section (top) --
              _UserSection(
                collapsed: collapsed,
                colors: c,
              ),

              const SizedBox(height: 8),

              // -- MAIN section label --
              if (!collapsed)
                _SectionLabel(label: 'MAIN', colors: c),

              if (!collapsed) const SizedBox(height: 4),

              // -- Overview (expandable) --
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: l.overview,
                index: 0,
                activeIndex: activeIndex,
                collapsed: collapsed,
                colors: c,
                hasChildren: true,
                isExpanded: _overviewExpanded && !collapsed,
                onTap: () {
                  _onNavTap(context, 0);
                  if (!collapsed) {
                    setState(() => _overviewExpanded = !_overviewExpanded);
                  }
                },
              ),

              // -- Sub-items for Overview --
              if (!collapsed && _overviewExpanded && activeIndex == 0) ...[
                _SubNavItem(
                  label: l.recentRuns,
                  isActive: false,
                  colors: c,
                  onTap: () => _onNavTap(context, 0),
                ),
                _SubNavItem(
                  label: l.recentActivity,
                  isActive: false,
                  colors: c,
                  onTap: () => _onNavTap(context, 0),
                ),
              ],

              // -- Competitors --
              _NavItem(
                icon: Icons.people_outline_rounded,
                label: l.competitorsNav,
                index: 1,
                activeIndex: activeIndex,
                collapsed: collapsed,
                colors: c,
                onTap: () => _onNavTap(context, 1),
              ),

              // -- Reports --
              _NavItem(
                icon: Icons.assessment_outlined,
                label: l.reportsNav,
                index: 2,
                activeIndex: activeIndex,
                collapsed: collapsed,
                colors: c,
                onTap: () => _onNavTap(context, 2),
              ),

              // -- Insights --
              _NavItem(
                icon: Icons.lightbulb_outline_rounded,
                label: l.insights,
                index: 3,
                activeIndex: activeIndex,
                collapsed: collapsed,
                colors: c,
                onTap: () => _onNavTap(context, 3),
              ),

              const SizedBox(height: 16),

              // -- SETTINGS section label --
              if (!collapsed)
                _SectionLabel(label: 'SETTINGS', colors: c),

              if (!collapsed) const SizedBox(height: 4),

              // -- Settings --
              _NavItem(
                icon: Icons.settings_outlined,
                label: l.settings,
                index: 4,
                activeIndex: activeIndex,
                collapsed: collapsed,
                colors: c,
                onTap: () => _onNavTap(context, 4),
              ),

              // -- Theme toggle --
              _ThemeToggleItem(collapsed: collapsed, colors: c),

              const Spacer(),

              // -- Bottom CTA card (expanded only) --
              if (!collapsed)
                _BottomCtaCard(colors: c),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// User section -- avatar, role, name, collapse toggle
// ---------------------------------------------------------------------------
class _UserSection extends StatelessWidget {
  final bool collapsed;
  final PulseColors colors;

  const _UserSection({
    required this.collapsed,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final l = AppLocalizations.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String initial = '?';
        String displayName = l.user;

        if (authState is Authenticated) {
          final username = authState.user.username;
          displayName = username;
          if (username.isNotEmpty) {
            initial = username.substring(0, 1).toUpperCase();
          }
        }

        return Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 8,
            top: 16,
            bottom: 8,
          ),
          child: collapsed
              ? Center(
                  child: _UserAvatar(initial: initial, colors: c),
                )
              : Row(
                  children: [
                    _UserAvatar(initial: initial, colors: c),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANALYST',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: c.textTertiary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            displayName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    _CollapseToggle(colors: c),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// User avatar -- 40px circle, surface2 bg, initial letter
// ---------------------------------------------------------------------------
class _UserAvatar extends StatelessWidget {
  final String initial;
  final PulseColors colors;

  const _UserAvatar({required this.initial, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface2,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collapse toggle -- chevron in a small circle
// ---------------------------------------------------------------------------
class _CollapseToggle extends StatefulWidget {
  final PulseColors colors;

  const _CollapseToggle({required this.colors});

  @override
  State<_CollapseToggle> createState() => _CollapseToggleState();
}

class _CollapseToggleState extends State<_CollapseToggle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final sidebarCubit = context.read<SidebarCubit>();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: sidebarCubit.toggleCollapse,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isHovered ? c.surface3 : c.surface2,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label -- "MAIN", "SETTINGS"
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  final String label;
  final PulseColors colors;

  const _SectionLabel({
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav item -- icon + label expanded, icon only collapsed
// Active: surface2 bg, left 2px accent border
// ---------------------------------------------------------------------------
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int activeIndex;
  final bool collapsed;
  final PulseColors colors;
  final VoidCallback onTap;
  final bool hasChildren;
  final bool isExpanded;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.activeIndex,
    required this.collapsed,
    required this.colors,
    required this.onTap,
    this.hasChildren = false,
    this.isExpanded = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final isActive = widget.activeIndex == widget.index;
    final iconColor = isActive ? c.textPrimary : c.textSecondary;
    final textColor = isActive ? c.textPrimary : c.textSecondary;

    Color bgColor;
    if (isActive) {
      bgColor = c.surface2;
    } else if (_isHovered) {
      bgColor = c.surface2.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: c.accent,
                        width: 2,
                      ),
                    )
                  : null,
            ),
            padding: EdgeInsets.only(
              left: widget.collapsed ? 0 : (isActive ? 10 : 12),
              right: widget.collapsed ? 0 : 8,
            ),
            child: widget.collapsed
                ? Center(
                    child: Tooltip(
                      message: widget.label,
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        widget.icon,
                        size: 20,
                        color: iconColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.hasChildren)
                        AnimatedRotation(
                          turns: widget.isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: c.textTertiary,
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
// Sub-nav item -- indented, no icon, 13px text
// Active: surface3 pill bg
// ---------------------------------------------------------------------------
class _SubNavItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final PulseColors colors;
  final VoidCallback onTap;

  const _SubNavItem({
    required this.label,
    required this.isActive,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_SubNavItem> createState() => _SubNavItemState();
}

class _SubNavItemState extends State<_SubNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    Color bgColor;
    if (widget.isActive) {
      bgColor = c.surface3;
    } else if (_isHovered) {
      bgColor = c.surface2.withValues(alpha: 0.5);
    } else {
      bgColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 38, right: 8, top: 1, bottom: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: widget.isActive ? c.textPrimary : c.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme toggle -- sun/moon icon
// ---------------------------------------------------------------------------
class _ThemeToggleItem extends StatefulWidget {
  final bool collapsed;
  final PulseColors colors;

  const _ThemeToggleItem({
    required this.collapsed,
    required this.colors,
  });

  @override
  State<_ThemeToggleItem> createState() => _ThemeToggleItemState();
}

class _ThemeToggleItemState extends State<_ThemeToggleItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: 38,
            decoration: BoxDecoration(
              color: _isHovered
                  ? c.surface2.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 12,
            ),
            child: widget.collapsed
                ? Center(
                    child: Tooltip(
                      message: l.toggleTheme,
                      child: Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 20,
                        color: c.textSecondary,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 20,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isDark ? l.lightMode : l.darkMode,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
// Bottom CTA card -- "Run Analysis" + "New Job" button
// ---------------------------------------------------------------------------
class _BottomCtaCard extends StatelessWidget {
  final PulseColors colors;

  const _BottomCtaCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Run Analysis',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start tracking competitors',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              _CtaButton(
                label: l.newJob,
                colors: c,
                onTap: () => JobCreationModal.show(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA button -- accent bg, white text
// ---------------------------------------------------------------------------
class _CtaButton extends StatefulWidget {
  final String label;
  final PulseColors colors;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            color: _isHovered
                ? c.accent.withValues(alpha: 0.85)
                : c.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
