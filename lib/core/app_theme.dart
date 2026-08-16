import 'package:flutter/material.dart';

class XynovaTheme {
  static const lightBg = Color(0xFFFAFAFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E2E2);
  static const lightText = Color(0xFF171717);
  static const lightMuted = Color(0xFF6B6B6B);

  static const darkBg = Color(0xFF070707);
  static const darkSurface = Color(0xFF111111);
  static const darkBorder = Color(0xFF292929);
  static const darkText = Color(0xFFF2F2F2);
  static const darkMuted = Color(0xFFA4A4A4);

  static ThemeData _base({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color border,
    required Color text,
    required Color muted,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: text,
      onPrimary: background,
      secondary: muted,
      onSecondary: background,
      error: text,
      onError: background,
      surface: surface,
      onSurface: text,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: text, width: 1.2),
        ),
      ),
      dividerColor: border,
    );
  }

  static ThemeData light() => _base(
        brightness: Brightness.light,
        background: lightBg,
        surface: lightSurface,
        border: lightBorder,
        text: lightText,
        muted: lightMuted,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        background: darkBg,
        surface: darkSurface,
        border: darkBorder,
        text: darkText,
        muted: darkMuted,
      );
}
