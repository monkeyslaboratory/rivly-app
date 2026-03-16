import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  void toggleTheme() {
    emit(state.copyWith(isDark: !state.isDark));
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(isDark: mode == ThemeMode.dark));
  }

  void setLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }
}
