// lib/src/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _themePreferenceKey = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themePreferenceKey);

    AppThemeMode appMode = savedTheme == null
        ? AppThemeMode.system
        : AppThemeMode.values.firstWhere((e) => e.name == savedTheme,
            orElse: () => AppThemeMode.system);

    return _convertToThemeMode(appMode);
  }

  ThemeMode _convertToThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, mode.name);
    state = AsyncData(_convertToThemeMode(mode));
  }

  ThemeMode getFlutterThemeMode() {
    return state.valueOrNull ?? ThemeMode.system;
  }
}

@riverpod
ThemeData themeData(Ref ref, Brightness brightness) {
  final isLight = brightness == Brightness.light;

  // Set base colors
  final backgroundColor = isLight ? Colors.white : const Color(0xFF121212);
  final textColor = isLight ? Colors.black : Colors.white;
  final primaryColor = isLight ? Colors.black : const Color(0xFF5FB709);
  const secondaryColor = Color(0xFF5FB709);

  // Create a single consistent text theme to avoid interpolation issues
  final textTheme = TextTheme(
    // All TextStyles have the same inherit value
    bodyLarge: TextStyle(
      inherit: true,
      color: textColor,
      fontSize: 16,
    ),
    bodyMedium: TextStyle(
      inherit: true,
      color: textColor,
      fontSize: 14,
    ),
    titleLarge: TextStyle(
      inherit: true,
      color: textColor,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
    titleMedium: TextStyle(
      inherit: true,
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: TextStyle(
      inherit: true,
      color: textColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'SF Pro Display',
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,

    // Set consistent color scheme
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: isLight ? Colors.white : Colors.black,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      error: isLight ? Colors.red : const Color(0xFFCF6679),
      onError: isLight ? Colors.white : Colors.black,
      surface: backgroundColor,
      onSurface: textColor,
    ),

    // Use the consistent text theme
    textTheme: textTheme,

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(primaryColor),
        foregroundColor:
            WidgetStateProperty.all(isLight ? Colors.white : Colors.black),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        )),
      ),
    ),
  );
}
