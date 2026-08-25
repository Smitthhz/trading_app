import 'package:flutter/material.dart';

import 'market_colors.dart';

abstract final class AppTheme {
  /// A trustworthy, saturated blue — the seed for the whole M3 tonal
  /// palette (secondary/tertiary/surface tones are derived from it).
  static const _seed = Color(0xFF2A5CE0);

  static ThemeData get light => _themeFrom(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
    MarketColors.light,
  );

  static ThemeData get dark => _themeFrom(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
    MarketColors.dark,
  );

  static ThemeData _themeFrom(
    ColorScheme colorScheme,
    MarketColors marketColors,
  ) {
    final radius12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final radius16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      useMaterial3: true,
      extensions: [marketColors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: radius16,
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: radius12),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: radius12),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: radius12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
