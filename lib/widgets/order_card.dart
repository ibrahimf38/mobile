import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/commande_models.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'status_badge.dart';

/// Carte "commande" réutilisée par la liste des commandes (onglets
/// Achats/Ventes/Livraisons) — radius 14, miniature 42×42, badge de statut.
class OrderCard extends StatelessWidget {
  final CommandeResponse commande;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Format purement numérique (pas de nom de mois) : évite de dépendre de
    // l'initialisation des données de locale intl (initializeDateFormatting),
    // absente de ce projet pour rester simple.
    final date = DateFormat('dd/MM/yyyy HH:mm').format(commande.dateCommande.toLocal());
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceL1,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.surfaceL2, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentBleu, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(commande.boutiqueNom, style: AppTextStyles.bodyMedium()),
                  const SizedBox(height: 2),
                  Text(date, style: AppTextStyles.caption()),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${commande.montantTotalAvecLivraison} MMC', style: AppTextStyles.bodyBold()),
                const SizedBox(height: 4),
                StatusBadge(statut: commande.statutAffiche),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
