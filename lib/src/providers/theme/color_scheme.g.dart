import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFFF8C00), // Orange color
  onPrimary: Color(0xFFFFFFFF), // White text on orange
  primaryContainer: Color(0xFFFFE0B2), // Light orange container
  onPrimaryContainer: Color(0xFF331800), // Dark brown on light orange
  secondary: Color(0xFF9E9E9E), // Gray for secondary elements
  onSecondary: Color(0xFFFFFFFF), // White text on gray
  secondaryContainer: Color(0xFFF5F5F5), // Very light gray container
  onSecondaryContainer: Color(0xFF1D1B16), // Dark text on light gray
  tertiary: Color(0xFFDD7530), // Darker orange variant
  onTertiary: Color(0xFFFFFFFF), // White text on dark orange
  tertiaryContainer: Color(0xFFFFDBCB), // Very light orange container
  onTertiaryContainer: Color(0xFF331D00), // Dark text on light container
  error: Color(0xFFB3261E), // Standard error color
  onError: Color(0xFFFFFFFF), // White text on error
  errorContainer: Color(0xFFF9DEDC), // Light error container
  onErrorContainer: Color(0xFF410E0B), // Dark text on error container
  outline: Color(0xFF79747E), // Standard outline color
  surface: Color(0xFFFFFBFE), // White surface
  onSurface: Color(0xFF1C1B1F), // Black text on surface
  surfaceContainerHighest: Color(0xFFE0E0E0), // Light gray for container areas
  onSurfaceVariant: Color(0xFF49454F), // Dark gray for secondary text
  inverseSurface: Color(0xFF313033), // Dark inverse surface
  onInverseSurface: Color(0xFFF4EFF4), // Light text on inverse surface
  inversePrimary: Color(0xFFFFAB40), // Light orange for inverse
  shadow: Color(0xFF000000), // Standard shadow
  surfaceTint: Color(0xFFFF8C00), // Orange tint
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFF9800), // Orange color for dark mode
  onPrimary: Color(0xFF000000), // Black text on orange buttons
  primaryContainer: Color(0xFF5C4200), // Dark orange container
  onPrimaryContainer: Color(0xFFFFE0B2), // Light orange text on dark container
  secondary: Color(0xFF757575), // Gray for secondary elements
  onSecondary: Color(0xFF000000), // Black text on gray
  secondaryContainer: Color(0xFF4A4458), // Darker gray container
  onSecondaryContainer: Color(0xFFE8DEF8), // Light text on dark container
  tertiary: Color(0xFFFFB74D), // Light orange for tertiary
  onTertiary: Color(0xFF000000), // Black text on light orange
  tertiaryContainer: Color(0xFF633B00), // Dark container
  onTertiaryContainer: Color(0xFFFFDBCB), // Light text on dark container
  error: Color(0xFFF2B8B5), // Standard error for dark mode
  onError: Color(0xFF601410), // Dark text on error
  errorContainer: Color(0xFF8C1D18), // Dark error container
  onErrorContainer: Color(0xFFF9DEDC), // Light text on error container
  outline: Color(0xFF938F99), // Standard outline for dark
  surface: Color(0xFF1C1B1F), // Dark surface
  onSurface: Color(0xFFE6E1E5), // Light text on surface
  surfaceContainerHighest: Color(0xFF424242), // Dark gray container
  onSurfaceVariant: Color(0xFFCAC4D0), // Light gray text
  inverseSurface: Color(0xFFE6E1E5), // Light inverse surface
  onInverseSurface: Color(0xFF313033), // Dark text on light surface
  inversePrimary: Color(0xFFFF8C00), // Orange for inverse primary
  shadow: Color(0xFF000000), // Standard shadow
  surfaceTint: Color(0xFFFF9800), // Orange tint
);
