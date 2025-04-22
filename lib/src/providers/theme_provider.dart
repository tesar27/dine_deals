// lib/src/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dine_deals/src/providers/theme/app_theme.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final themeProvider = Provider<ThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode == ThemeMode.light
      ? AppTheme.lightTheme
      : AppTheme.darkTheme;
});
