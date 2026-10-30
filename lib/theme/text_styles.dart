import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Styles de texte de la maquette Figma MaliMall, section 3 — tous en
/// Poppins. Les tailles et graisses reprennent exactement le tableau de la
/// fiche de specs (les usages y sont documentés, ex. Display/Montant pour le
/// solde du portefeuille).
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _poppins(double size, FontWeight weight, {Color? color, double? letterSpacing}) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle displayMontant({Color? color}) => _poppins(28, FontWeight.w700, color: color);
  static TextStyle headingXL({Color? color}) => _poppins(21, FontWeight.w700, color: color);
  static TextStyle headingL({Color? color}) => _poppins(19, FontWeight.w700, color: color);
  static TextStyle headingM({Color? color}) => _poppins(17, FontWeight.w700, color: color);
  static TextStyle titleAppBar({Color? color}) => _poppins(16, FontWeight.w600, color: color);
  static TextStyle titleS({Color? color}) => _poppins(15, FontWeight.w700, color: color);
  static TextStyle bodyBoldL({Color? color}) => _poppins(14, FontWeight.w700, color: color);
  static TextStyle bodyBold({Color? color}) => _poppins(13.5, FontWeight.w700, color: color);
  static TextStyle bodyDefault({Color? color}) =>
      _poppins(12.5, FontWeight.w400, color: color ?? AppColors.textPrimary);
  static TextStyle bodyMedium({Color? color}) => _poppins(12.5, FontWeight.w600, color: color);
  static TextStyle caption({Color? color}) =>
      _poppins(11, FontWeight.w500, color: color ?? AppColors.textSecondary);
  static TextStyle captionSmall({Color? color}) =>
      _poppins(9.5, FontWeight.w600, color: color ?? AppColors.textSecondary);
  static TextStyle eyebrow({Color? color}) =>
      _poppins(9, FontWeight.w700, color: color, letterSpacing: 0.45);
}
