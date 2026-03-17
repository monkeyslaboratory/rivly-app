import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final bool isDark;
  final bool useSystemTheme;
  final Locale locale;

  const ThemeState({
    this.isDark = true,
    this.useSystemTheme = true,
    this.locale = const Locale('en'),
  });

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeState copyWith({bool? isDark, bool? useSystemTheme, Locale? locale}) {
    return ThemeState(
      isDark: isDark ?? this.isDark,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [isDark, useSystemTheme, locale];
}
