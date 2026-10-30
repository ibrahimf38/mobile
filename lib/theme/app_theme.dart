import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'text_styles.dart';

/// Thème Material centralisé — les écrans ne redéfinissent jamais une couleur
/// ou un rayon en dur, ils consomment [AppColors]/[AppTextStyles] ou ce thème.
class AppTheme {
  AppTheme._();

  static const double radiusBouton = 100; // pilule
  static const double radiusCarte = 16;
  static const double radiusChamp = 12;
  static const double radiusPanneau = 15;

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentBleu,
        brightness: Brightness.light,
        primary: AppColors.accentBleu,
        error: AppColors.danger,
        surface: AppColors.surfaceL1,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleAppBar(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBleu,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.bodyBoldL(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusBouton)),
          elevation: 4,
          shadowColor: AppColors.accentBleu.withValues(alpha: 0.55),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusBouton)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceL2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusChamp),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusChamp),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusChamp),
          borderSide: const BorderSide(color: AppColors.accentBleu, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusChamp),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        hintStyle: AppTextStyles.bodyDefault(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceL1,
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCarte)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
          color: AppColors.divider, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.white,
        contentTextStyle: AppTextStyles.bodyDefault(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
