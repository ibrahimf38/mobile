import 'package:flutter/material.dart';

import '../core/models/commande_models.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Frise de suivi à 4 étapes (maquettes 10 et 25) : Confirmée → Livreur
/// assigné → Colis récupéré → Livrée.
class SuiviEtapes extends StatelessWidget {
  final CommandeResponse? commande;

  /// Étape à afficher quand on n'a pas de commande (ex. juste après la
  /// validation du panier, où toutes les commandes sont à l'étape 0).
  final int etapeParDefaut;

  const SuiviEtapes({super.key, this.commande, this.etapeParDefaut = 0});

  static const etapes = ['Confirmée', 'Livreur assigné', 'Colis récupéré', 'Livrée'];

  /// -1 si la commande est annulée.
  static int etapeDe(CommandeResponse c) {
    if (c.statut == StatutCommande.annulee) return -1;
    if (c.statut == StatutCommande.livree) return 3;
    switch (c.statutLivraison) {
      case null:
        return 0;
      case StatutLivraison.assignee:
        return 1;
      case StatutLivraison.recuperee:
      case StatutLivraison.enRoute:
        return 2;
      case StatutLivraison.livree:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courante = commande == null ? etapeParDefaut : etapeDe(commande!);
    if (courante < 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(etapes.length, (i) {
          final fait = i <= courante;
          return Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      Expanded(
                        child: i == 0
                            ? const SizedBox.shrink()
                            : Container(height: 2, color: fait ? AppColors.accentBleu : AppColors.divider),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: fait ? AppColors.accentBleu : AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: fait ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                      ),
                      Expanded(
                        child: i == etapes.length - 1
                            ? const SizedBox.shrink()
                            : Container(height: 2, color: i < courante ? AppColors.accentBleu : AppColors.divider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  etapes[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionSmall(color: fait ? AppColors.textPrimary : AppColors.textSecondary)
                      .copyWith(fontSize: 8.5),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
