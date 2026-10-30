import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// AppBar de l'app — reprend le composant "AppBar" de la charte
/// (la maquette Figma MaliMall §6) : bouton retour rond 34×34 sur fond
/// Card-L1 plutôt que la flèche par défaut de Material, titre 16px/600 (déjà
/// réglé globalement par `AppBarTheme.titleTextStyle`). À utiliser à la place
/// de `AppBar(...)` sur tous les écrans qui peuvent être empilés par-dessus
/// un autre (tout sauf les 4 onglets racine de MainShell).
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String titre;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  /// À mettre à `false` uniquement pour un écran volontairement "sans retour"
  /// (ex. Commande confirmée, où la sortie se fait par le bouton d'action,
  /// pas par la flèche retour).
  final bool afficherRetour;

  const AppHeaderBar({
    super.key,
    required this.titre,
    this.actions,
    this.bottom,
    this.afficherRetour = true,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final peutRevenir = afficherRetour && Navigator.of(context).canPop();
    return AppBar(
      title: Text(titre),
      automaticallyImplyLeading: false,
      titleSpacing: peutRevenir ? 0 : 16,
      leadingWidth: 62,
      leading: peutRevenir
          ? Center(
              child: Material(
                color: AppColors.surfaceL1,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.accentBleu, size: 16),
                  ),
                ),
              ),
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }
}
