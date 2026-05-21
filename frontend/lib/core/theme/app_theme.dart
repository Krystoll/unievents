import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 28,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surfaceContainer,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: AppSpacing.cardElevation,
        color: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: AppColors.surfaceContainer,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelLarge?.copyWith(
            fontSize: 11,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceContainer,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelType: NavigationRailLabelType.all,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
