import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/theme/theme_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.settings, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 32),

          // Appearance section
          _SectionCard(
            isDark: isDark,
            title: l.theme,
            children: [
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return Column(
                    children: [
                      _SettingsRow(
                        isDark: isDark,
                        icon: Icons.computer_outlined,
                        label: l.systemTheme,
                        trailing: Switch.adaptive(
                          value: themeState.useSystemTheme,
                          onChanged: (v) {
                            if (v) {
                              context.read<ThemeCubit>().resetToSystem();
                            } else {
                              context.read<ThemeCubit>().toggleTheme();
                            }
                          },
                          activeColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (!themeState.useSystemTheme) ...[
                        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        _SettingsRow(
                          isDark: isDark,
                          icon: themeState.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          label: themeState.isDark ? l.darkMode : l.lightMode,
                          trailing: Switch.adaptive(
                            value: themeState.isDark,
                            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                            activeColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Language section
          _SectionCard(
            isDark: isDark,
            title: l.language,
            children: [
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return Column(
                    children: [
                      _LanguageOption(
                        isDark: isDark,
                        label: 'English',
                        flag: '🇬🇧',
                        isSelected: themeState.locale.languageCode == 'en',
                        onTap: () => context.read<ThemeCubit>().setLocale(const Locale('en')),
                      ),
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      _LanguageOption(
                        isDark: isDark,
                        label: 'Русский',
                        flag: '🇷🇺',
                        isSelected: themeState.locale.languageCode == 'ru',
                        onTap: () => context.read<ThemeCubit>().setLocale(const Locale('ru')),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Profile section
          _SectionCard(
            isDark: isDark,
            title: l.profile,
            children: [
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState is! Authenticated) return const SizedBox.shrink();
                  final user = authState.user;
                  return Column(
                    children: [
                      _SettingsRow(
                        isDark: isDark,
                        icon: Icons.person_outline_rounded,
                        label: user.username,
                        trailing: Text(
                          user.email,
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      _SettingsRow(
                        isDark: isDark,
                        icon: Icons.logout_rounded,
                        label: l.signOut,
                        iconColor: AppColors.error,
                        labelColor: AppColors.error,
                        onTap: () => context.read<AuthCubit>().logout(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card container
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.isDark, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settings row
// ---------------------------------------------------------------------------

class _SettingsRow extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsRow({required this.isDark, required this.icon, required this.label, this.trailing, this.onTap, this.iconColor, this.labelColor});

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: _hovered && widget.onTap != null
              ? (widget.isDark ? AppColors.darkBgSubtle.withValues(alpha: 0.5) : AppColors.lightBgSubtle.withValues(alpha: 0.5))
              : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: widget.iconColor ?? (widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: widget.labelColor ?? (widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary))),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language option
// ---------------------------------------------------------------------------

class _LanguageOption extends StatefulWidget {
  final bool isDark;
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({required this.isDark, required this.label, required this.flag, required this.isSelected, required this.onTap});

  @override
  State<_LanguageOption> createState() => _LanguageOptionState();
}

class _LanguageOptionState extends State<_LanguageOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: _hovered
              ? (widget.isDark ? AppColors.darkBgSubtle.withValues(alpha: 0.5) : AppColors.lightBgSubtle.withValues(alpha: 0.5))
              : Colors.transparent,
          child: Row(
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              ),
              if (widget.isSelected)
                Icon(Icons.check_rounded, size: 18, color: AppColors.success),
            ],
          ),
        ),
      ),
    );
  }
}
