import 'package:flutter/material.dart';

/// Palette exacte de la maquette Figma MaliMall (extraite du CSS réel des
/// maquettes) — ne pas improviser d'autres teintes ailleurs dans l'app.
///
/// Charte : accents en teintes pleines uniquement (bleu uni [accentBleu]),
/// aucun dégradé de couleur de marque.
class AppColors {
  AppColors._();

  // Fond & surfaces
  static const Color background = Color(0xFFECECF2);
  static const Color surfaceL1 = Color(0xFFF7F7FB);
  static const Color surfaceL2 = Color(0xFFF0F0F6);
  static const Color divider = Color(0xFFE2E2EA);

  // Texte
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF9A9AA6);
  static const Color iconDisabled = Color(0xFFC4C4CE);

  // Accents (jamais de dégradé — teintes pleines uniquement)
  static const Color accentBleu = Color(0xFF3C6FD1);
  static const Color accentViolet = Color(0xFF8B78F0);
  static const Color accentOrange = Color(0xFFD97C2E);
  static const Color danger = Color(0xFFFF5252);

  // Couleurs de marque brutes — réservées aux éléments graphiques colorés,
  // jamais au texte.
  static const Color brandVioletRaw = Color(0xFF9B8BFF);
  static const Color brandBleuRaw = Color(0xFF3C6FD1);
  static const Color brandOrangeRaw = Color(0xFFFFB574);

  // Boutons d'action Wallet
  static const Color walletDepot = Color(0xFF3A78EB);
  static const Color walletRetrait = Color(0xFF654FF5);
  static const Color walletEnvoyer = Color(0xFFF48422);

  // Badges de statut — couleur "texte plein" ; le fond translucide se calcule
  // avec .withValues(alpha: ...) à l'usage (voir StatusBadge).
  static const Color statutEnAttente = Color(0xFFD97C2E);
  static const Color statutEnTransit = Color(0xFF3C6FD1);
  static const Color statutTermineFond = Color(0xFF4CAF8C);
  static const Color statutTermineTexte = Color(0xFF2E9E76);
  static const Color statutAnnule = Color(0xFFFF5252);
}
