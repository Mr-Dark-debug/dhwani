import 'package:flutter/material.dart';

abstract final class DhwaniColors {
  static const paper = Color(0xFFF7F7F4);
  static const ink = Color(0xFF11110F);
  static const signal = Color(0xFFE33B32);
  static const mist = Color(0xFFE8E8E3);
  static const secondary = Color(0xFF777771);
  static const online = Color(0xFF2E7D5B);
  static const darkPaper = Color(0xFF11110F);
  static const darkSurface = Color(0xFF1B1B18);
}

abstract final class DhwaniTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? DhwaniColors.darkPaper : DhwaniColors.paper;
    final surface = dark ? DhwaniColors.darkSurface : Colors.white;
    final ink = dark ? const Color(0xFFF5F5F1) : DhwaniColors.ink;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: DhwaniColors.signal,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: DhwaniColors.signal,
          onPrimary: Colors.white,
          surface: surface,
          onSurface: ink,
          outline: dark ? const Color(0xFF3A3A36) : DhwaniColors.mist,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: TextStyle(
          fontSize: 76,
          height: .9,
          fontWeight: FontWeight.w700,
          letterSpacing: -5,
          color: ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 36,
          height: 1.02,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          height: 1.08,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: ink),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: ink.withValues(alpha: .74),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: surface,
        indicatorColor: dark
            ? const Color(0xFF32322E)
            : const Color(0xFFF0F0EB),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF242421) : Colors.white,
        hintStyle: TextStyle(color: ink.withValues(alpha: .42)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: DhwaniColors.signal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: background,
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
