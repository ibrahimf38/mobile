import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Pastille ronde 50 px avec le logo MaliMall (en-tête des onglets).
class LogoPastille extends StatelessWidget {
  final double taille;
  const LogoPastille({super.key, this.taille = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      padding: EdgeInsets.all(taille * 0.14),
      decoration: BoxDecoration(
        color: const Color(0xFFD3D3D4).withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: Image.asset('assets/branding/logo_mark.png', fit: BoxFit.contain),
    );
  }
}

/// En-tête des écrans d'onglet (Market, MotoTaxis, Wallet, Compte) : titre à
/// gauche, actions éventuelles, pastille logo à droite.
class EnTeteOnglet extends StatelessWidget {
  final String titre;
  final double tailleTitre;
  final List<Widget> actions;

  const EnTeteOnglet({super.key, required this.titre, this.tailleTitre = 16, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(tailleTitre >= 20 ? 24 : 16, 16, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titre,
                style: AppTextStyles.titleAppBar(color: AppColors.textPrimary).copyWith(fontSize: tailleTitre),
              ),
            ),
            for (final a in actions) ...[a, const SizedBox(width: 10)],
            const LogoPastille(),
          ],
        ),
      ),
    );
  }
}
