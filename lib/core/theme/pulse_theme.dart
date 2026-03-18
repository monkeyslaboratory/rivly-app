import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens/colors.dart';
import 'tokens/radii.dart';
import 'tokens/typography.dart';

/// Pulse Design System — ThemeData builder (dark-first).
///
/// Provides [light] and [dark] theme constructors that map Pulse tokens onto
/// Material's [ThemeData]. Screens should prefer using Pulse tokens directly
/// (e.g. `PulseColors.dark.accent`) for any value not covered by the Material
/// theme, but standard Material widgets will automatically pick up the correct
/// colors, typography and shapes.
class PulseTheme {
  PulseTheme._();

  // -- Public API --

  static ThemeData light() => _build(Brightness.light, PulseColors.light);
  static ThemeData dark() => _build(Brightness.dark, PulseColors.dark);

  // -- Internal builder --

  static ThemeData _build(Brightness brightness, PulseColors c) {
    final isLight = brightness == Brightness.light;
    final base = isLight ? ThemeData.light() : ThemeData.dark();

    final colorScheme = (isLight
            ? const ColorScheme.light()
            : const ColorScheme.dark())
        .copyWith(
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.accent,
      onSecondary: Colors.white,
      surface: c.surface1,
      onSurface: c.textPrimary,
      error: c.danger,
      onError: Colors.white,
    );

    final textTheme = _buildTextTheme(base.textTheme, c);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surface0,
      textTheme: textTheme,

      // -- Text selection --
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.25),
        selectionHandleColor: c.accent,
      ),

      // -- AppBar --
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: PulseTypography.h3(color: c.textPrimary),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),

      // -- Card --
      cardTheme: CardThemeData(
        color: c.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: PulseRadii.borderMd,
          side: BorderSide(color: c.borderDefault),
        ),
      ),

      // -- Input --
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface1,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: PulseRadii.borderSm,
          borderSide: BorderSide(color: c.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PulseRadii.borderSm,
          borderSide: BorderSide(color: c.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PulseRadii.borderSm,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: PulseRadii.borderSm,
          borderSide: BorderSide(color: c.danger),
        ),
        hintStyle: GoogleFonts.inter(color: c.textTertiary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: c.textSecondary, fontSize: 14),
      ),

      // -- Elevated button (accent bg) --
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: PulseRadii.borderMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // -- Outlined button (border) --
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.borderDefault),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: PulseRadii.borderMd,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // -- Text button (ghost) --
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // -- Divider --
      dividerTheme: DividerThemeData(
        color: c.borderDefault,
        thickness: 1,
      ),

      // -- Bottom nav --
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface1,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textTertiary,
      ),

      // -- Snackbar --
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface1,
        contentTextStyle: GoogleFonts.inter(color: c.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: PulseRadii.borderSm),
        behavior: SnackBarBehavior.floating,
      ),

      // -- Progress indicator --
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
      ),

      // -- FAB --
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
      ),

      // -- Dialog --
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: PulseRadii.borderLg,
        ),
      ),

      // -- Switch --
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.accent;
          return c.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.accent.withValues(alpha: 0.3);
          }
          return c.surface2;
        }),
      ),
    );
  }

  // -- Text theme mapping --

  static TextTheme _buildTextTheme(TextTheme base, PulseColors c) {
    return base.copyWith(
      displayLarge: PulseTypography.display(color: c.textPrimary),
      displayMedium: PulseTypography.h1(color: c.textPrimary),
      displaySmall: PulseTypography.h2(color: c.textPrimary),
      headlineLarge: PulseTypography.h2(color: c.textPrimary),
      headlineMedium: PulseTypography.h3(color: c.textPrimary),
      headlineSmall:
          PulseTypography.bodyLg(color: c.textPrimary).copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: PulseTypography.bodyLg(color: c.textPrimary).copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: PulseTypography.label(color: c.textSecondary),
      titleSmall: PulseTypography.labelSm(color: c.textSecondary),
      bodyLarge: PulseTypography.bodyLg(color: c.textPrimary),
      bodyMedium: PulseTypography.body(color: c.textSecondary),
      bodySmall: PulseTypography.bodySm(color: c.textTertiary),
      labelLarge: PulseTypography.label(color: c.textPrimary),
      labelMedium: PulseTypography.labelSm(color: c.textSecondary),
      labelSmall: PulseTypography.caption(color: c.textTertiary),
    );
  }
}
