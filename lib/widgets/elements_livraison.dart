import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'app_feedback.dart';

/// "09:41" à partir d'une date (heure locale).
String heureMinute(DateTime d) {
  final l = d.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// "Aujourd'hui, 09:41" / "Hier, 17:20" / "Lun. 21 sept.".
String dateRelative(DateTime d) {
  final l = d.toLocal();
  final maintenant = DateTime.now();
  final jour = DateTime(l.year, l.month, l.day);
  final aujourdhui =
      DateTime(maintenant.year, maintenant.month, maintenant.day);
  final ecart = aujourdhui.difference(jour).inDays;
  if (ecart == 0) return "Aujourd'hui, ${heureMinute(l)}";
  if (ecart == 1) return 'Hier, ${heureMinute(l)}';
  const jours = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
  const mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.'
  ];
  return '${jours[l.weekday - 1]} ${l.day} ${mois[l.month - 1]}';
}

/// Avatar rond 42 px à fond bleu pâle et pictogramme bleu.
class AvatarIcone extends StatelessWidget {
  final IconData icone;
  final double taille;
  final Color couleur;

  const AvatarIcone(
      {super.key,
      required this.icone,
      this.taille = 42,
      this.couleur = AppColors.accentBleu});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.13), shape: BoxShape.circle),
      child: Icon(icone, size: taille * 0.43, color: couleur),
    );
  }
}

/// Pilule d'estimation "~6 min" (vert) ou d'information (bleu).
class PiluleInfo extends StatelessWidget {
  final String texte;
  final Color couleur;
  const PiluleInfo(this.texte,
      {super.key, this.couleur = AppColors.statutTermineTexte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(10)),
      child: Text(texte,
          style: AppTextStyles.captionSmall(color: couleur)
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

/// Bouton téléphone rond : copie le numéro (pas d'appel direct depuis l'app).
class BoutonTelephone extends StatelessWidget {
  final String? telephone;
  const BoutonTelephone({super.key, required this.telephone});

  @override
  Widget build(BuildContext context) {
    final tel = telephone;
    if (tel == null || tel.isEmpty) return const SizedBox.shrink();
    return Material(
      color: AppColors.accentBleu.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: tel));
          if (!context.mounted) return;
          AppFeedback.success(context, 'Numéro copié : $tel');
        },
        child: const SizedBox(
          width: 36,
          height: 36,
          child:
              Icon(Icons.phone_outlined, size: 17, color: AppColors.accentBleu),
        ),
      ),
    );
  }
}

/// Lien texte gris centré ("Un problème avec cette livraison ?").
class LienDiscret extends StatelessWidget {
  final String texte;
  final VoidCallback? onTap;
  const LienDiscret(this.texte, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text(texte,
            style:
                AppTextStyles.caption().copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Grand rond vert avec coche (écrans de succès 27, 35, course terminée).
class PastilleSucces extends StatelessWidget {
  const PastilleSucces({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
          color: AppColors.statutTermineFond, shape: BoxShape.circle),
      child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
    );
  }
}

/// Tuile chiffre clé (valeur en gras + libellé gris) des maquettes 18 et 35.
class TuileChiffre extends StatelessWidget {
  final String valeur;
  final String libelle;
  const TuileChiffre({super.key, required this.valeur, required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: AppColors.surfaceL1,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(valeur, style: AppTextStyles.titleS()),
            const SizedBox(height: 6),
            Text(libelle, style: AppTextStyles.captionSmall()),
          ],
        ),
      ),
    );
  }
}

/// Panneau blanc arrondi posé en bas des écrans carte (31, 33, 15, 23).
class PanneauBasCarte extends StatelessWidget {
  final Widget child;
  const PanneauBasCarte({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceL1,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6))
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Pilule blanche flottante en haut à droite des écrans carte
/// ("Vers le vendeur · 4.2 km").
class PiluleCarte extends StatelessWidget {
  final String texte;
  final Color? fond;
  final Color? couleurTexte;
  final IconData? icone;
  const PiluleCarte(this.texte,
      {super.key, this.fond, this.couleurTexte, this.icone});

  @override
  Widget build(BuildContext context) {
    final c = couleurTexte ?? AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: fond ?? AppColors.surfaceL1,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 14, color: c),
            const SizedBox(width: 6)
          ],
          // Flexible + ellipsis : un texte long (ex. "Touchez la carte pour
          // choisir la destination") dans un espace resserré (ex. entre deux
          // boutons ronds sur la carte MotoTaxi) débordait le Row de
          // plusieurs dizaines de pixels au lieu de se tronquer proprement.
          Flexible(
            child: Text(
              texte,
              style: AppTextStyles.bodyMedium(color: c),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Moussa Konaté" → "MK".
String initiales(String nom) {
  final mots =
      nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
  if (mots.isEmpty) return '?';
  final premiere = mots.first[0];
  final derniere = mots.length > 1 ? mots.last[0] : '';
  return (premiere + derniere).toUpperCase();
}

/// Avatar rond à initiales (maquettes 15 et 16).
class AvatarInitiales extends StatelessWidget {
  final String nom;
  final double taille;
  const AvatarInitiales({super.key, required this.nom, this.taille = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: AppColors.accentBleu.withValues(alpha: 0.14),
          shape: BoxShape.circle),
      child: Text(
        initiales(nom),
        style: AppTextStyles.bodyBold(color: AppColors.accentBleu)
            .copyWith(fontSize: taille * 0.34),
      ),
    );
  }
}
