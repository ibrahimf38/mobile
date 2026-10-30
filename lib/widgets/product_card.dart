import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/models/catalogue_models.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'reseau_image.dart';

/// Fonds pastel + couleur d'icône des cartes sans photo (maquette 05).
const _palettes = [
  (fond: Color(0xFFE7DDFB), icone: AppColors.accentViolet),
  (fond: Color(0xFFFBE6D4), icone: AppColors.accentOrange),
  (fond: Color(0xFFDCECFF), icone: AppColors.accentBleu),
  (fond: Color(0xFFFDE3E8), icone: Color(0xFFE0578A)),
];

/// Carte produit de la grille Market (2 colonnes) — radius 16, image carrée
/// en haut, nom + prix en bas. Affiche la vraie photo du produit si le
/// vendeur en a téléversé une, sinon un fond pastel avec pictogramme.
class ProductCard extends StatelessWidget {
  final ProduitResponse produit;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.produit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[produit.id % _palettes.length];
    return Material(
      color: AppColors.surfaceL1,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ReseauImage(
                        imageUrl: produit.imageUrl,
                        icone: Icons.shopping_bag_outlined,
                        tailleIcone: 34,
                        couleurFond: palette.fond,
                        couleurIcone: palette.icone,
                      ),
                    ),
                    // Badge "vendus" — uniquement si au moins une vente réelle
                    // a eu lieu (quantiteVendue calculée côté serveur).
                    if (produit.quantiteVendue > 0)
                      Positioned(
                        left: 7,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(7, 3, 7, 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBleu.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🔥 ${produit.quantiteVendue} vendu${produit.quantiteVendue > 1 ? 's' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.eyebrow(color: Colors.white)
                                .copyWith(letterSpacing: 0),
                          ),
                        ),
                      ),
                    if (produit.stock == 0)
                      Positioned(
                        right: 6,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(7, 3, 7, 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Épuisé',
                              style: AppTextStyles.eyebrow(color: Colors.white)
                                  .copyWith(
                                letterSpacing: 0,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      )
                    else if (produit.enPromotion)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(7, 3, 7, 4),
                          decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('PROMO',
                              style: AppTextStyles.eyebrow(color: Colors.white)
                                  .copyWith(letterSpacing: 0.4)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyDefault()
                        .copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  if (produit.enPromotion) ...[
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            formatMmc(produit.prixMmc),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(
                                    color: AppColors.textSecondary)
                                .copyWith(
                              fontSize: 10.5,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${formatMmc(produit.prixEffectifMmc)} MMC',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTextStyles.bodyBold(color: AppColors.danger)
                                    .copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '≈ ${formatMmc(equivalentFcfa(produit.prixEffectifMmc))} FCFA',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionSmall(
                          color: AppColors.textSecondary),
                    ),
                  ] else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatMmc(produit.prixMmc)} MMC',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyBold(
                                  color: AppColors.accentBleu)
                              .copyWith(fontSize: 13),
                        ),
                        Text(
                          '≈ ${formatMmc(equivalentFcfa(produit.prixMmc))} FCFA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionSmall(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
