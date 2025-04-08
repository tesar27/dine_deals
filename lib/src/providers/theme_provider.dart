// lib/src/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Simple state provider for theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// Notifier to handle theme state with persistence
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  static const _themePreferenceKey = 'theme_mode';

  // Load saved theme from preferences
  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themePreferenceKey);

    if (themeName != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => ThemeMode.system,
      );
    }
  }

  // Change theme and save preference
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, mode.name);
  }

  // Toggle between light and dark
  void toggleTheme() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

// Theme data provider
final themeDataProvider =
    Provider.family<ThemeData, Brightness>((ref, brightness) {
  final isLight = brightness == Brightness.light;

  // Colors
  final backgroundColor = isLight ? Colors.white : const Color(0xFF121212);
  final textColor = isLight ? Colors.black : Colors.white;
  final primaryColor = isLight ? Colors.black : const Color(0xFF5FB709);
  const secondaryColor = Color(0xFF5FB709);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'SF Pro Display',
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,

    colorScheme: ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: isLight ? Colors.white : Colors.black,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      error: isLight ? Colors.red : const Color(0xFFCF6679),
      onError: isLight ? Colors.white : Colors.black,
      background: backgroundColor,
      onBackground: textColor,
      surface: backgroundColor,
      onSurface: textColor,
    ),

    // Keep TextStyle consistent
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: textColor, fontSize: 16),
      bodyMedium: TextStyle(color: textColor, fontSize: 14),
      titleLarge: TextStyle(
          color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(
          color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
    ).apply(fontFamily: 'SF Pro Display'),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(primaryColor),
        foregroundColor:
            MaterialStateProperty.all(isLight ? Colors.white : Colors.black),
        padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
      ),
    ),
  );
});
