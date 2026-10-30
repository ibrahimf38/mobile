import 'package:flutter/material.dart';

import '../core/models/commande_models.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Pastille de statut — couleurs exactes de la maquette Figma MaliMall §2
/// ("Couleurs des badges de statut") : fond translucide + texte plein.
class StatusBadge extends StatelessWidget {
  final StatutAffiche statut;

  const StatusBadge({super.key, required this.statut});

  ({Color texte, Color fond, double opaciteFond, String libelle}) get _config {
    switch (statut) {
      case StatutAffiche.enAttente:
        return (
          texte: AppColors.statutEnAttente,
          fond: AppColors.statutEnAttente,
          opaciteFond: 0.14,
          libelle: 'En attente'
        );
      case StatutAffiche.enTransit:
        return (
          texte: AppColors.statutEnTransit,
          fond: AppColors.statutEnTransit,
          opaciteFond: 0.14,
          libelle: 'En livraison'
        );
      case StatutAffiche.termine:
        return (
          texte: AppColors.statutTermineTexte,
          fond: AppColors.statutTermineFond,
          opaciteFond: 0.16,
          libelle: 'Livré'
        );
      case StatutAffiche.annule:
        return (texte: AppColors.statutAnnule, fond: AppColors.statutAnnule, opaciteFond: 0.13, libelle: 'Annulé');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.fond.withValues(alpha: c.opaciteFond),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(c.libelle, style: AppTextStyles.captionSmall(color: c.texte)),
    );
  }
}
