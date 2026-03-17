import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState()) {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    emit(state.copyWith(isDark: brightness == Brightness.dark, useSystemTheme: true));

    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (state.useSystemTheme) {
        final newBrightness = PlatformDispatcher.instance.platformBrightness;
        emit(state.copyWith(isDark: newBrightness == Brightness.dark));
      }
    };
  }

  void toggleTheme() {
    emit(state.copyWith(isDark: !state.isDark, useSystemTheme: false));
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(isDark: mode == ThemeMode.dark, useSystemTheme: false));
  }

  void resetToSystem() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    emit(state.copyWith(isDark: brightness == Brightness.dark, useSystemTheme: true));
  }

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
    // Sync to backend so AI generates reports in the right language
    AuthRepository().updateMe(locale: locale.languageCode).ignore();
  }
}
