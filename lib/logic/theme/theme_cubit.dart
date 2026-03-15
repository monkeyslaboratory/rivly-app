import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(themeMode: ThemeMode.dark));

  void toggleTheme() {
    emit(
      state.copyWith(
        themeMode:
            state.isDark ? ThemeMode.light : ThemeMode.dark,
      ),
    );
  }

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }
}
