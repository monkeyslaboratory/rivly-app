import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final bool isDark;
  final Locale locale;

  const ThemeState({this.isDark = true, this.locale = const Locale('en')});

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeState copyWith({bool? isDark, Locale? locale}) {
    return ThemeState(
      isDark: isDark ?? this.isDark,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [isDark, locale];
}
