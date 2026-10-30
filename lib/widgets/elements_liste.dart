import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Fonds pastel + couleur d'icône utilisés par les vignettes sans photo.
const palettesPastel = [
  (fond: Color(0xFFE7DDFB), icone: AppColors.accentViolet),
  (fond: Color(0xFFFBE6D4), icone: AppColors.accentOrange),
  (fond: Color(0xFFDCECFF), icone: AppColors.accentBleu),
  (fond: Color(0xFFFDE3E8), icone: Color(0xFFE0578A)),
];

/// Vignette carrée pastel (42 px, radius 11) avec pictogramme.
class VignettePastel extends StatelessWidget {
  final int graine;
  final IconData icone;
  final double taille;

  const VignettePastel(
      {super.key,
      required this.graine,
      this.icone = Icons.shopping_bag_outlined,
      this.taille = 42});

  @override
  Widget build(BuildContext context) {
    final p = palettesPastel[graine.abs() % palettesPastel.length];
    return Container(
      width: taille,
      height: taille,
      decoration:
          BoxDecoration(color: p.fond, borderRadius: BorderRadius.circular(11)),
      child: Icon(icone, size: taille * 0.4, color: p.icone),
    );
  }
}

/// Petite pastille de statut (fond 14 %, texte gras 8.5 px).
class Pastille extends StatelessWidget {
  final String texte;
  final Color couleur;
  final Color? couleurTexte;

  const Pastille(
      {super.key,
      required this.texte,
      required this.couleur,
      this.couleurTexte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
      decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10)),
      child: Text(
        texte,
        style: AppTextStyles.captionSmall(color: couleurTexte ?? couleur)
            .copyWith(fontSize: 8.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Chip de filtre en pilule (35 px) : active = bleu plein + ombre bleue,
/// inactive = fond clair + bordure.
class ChipFiltre extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback onTap;

  const ChipFiltre(
      {super.key,
      required this.label,
      required this.actif,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: actif ? AppColors.accentBleu : AppColors.surfaceL1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: actif ? AppColors.accentBleu : AppColors.divider),
            boxShadow: actif
                ? [
                    BoxShadow(
                      color: AppColors.accentBleu.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: -2,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyDefault(
                    color: actif ? Colors.white : AppColors.textPrimary)
                .copyWith(
              fontSize: 11.5,
              fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte de liste standard (fond clair, radius 14, padding 12).
class CarteListe extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const CarteListe(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(12)});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceL1,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Titre de section en majuscules grises (ex. "GÉRER").
class TitreSection extends StatelessWidget {
  final String texte;
  const TitreSection(this.texte, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texte.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
          fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.52),
    );
  }
}
