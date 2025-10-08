import 'package:flutter/material.dart';
import 'color_scheme.g.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    // Explicitly set ElevatedButton theme to use primary color (orange)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightColorScheme.primary, // Orange
        foregroundColor: lightColorScheme.onPrimary, // White
        elevation: 2,
      ),
    ),
    // TextButton style for consistent color
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightColorScheme.primary,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    // Explicitly set ElevatedButton theme to use primary color (orange)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkColorScheme.primary, // Orange
        foregroundColor: darkColorScheme.onPrimary, // Black
        elevation: 2,
      ),
    ),
    // TextButton style for consistent color
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkColorScheme.primary,
      ),
    ),
  );
}
