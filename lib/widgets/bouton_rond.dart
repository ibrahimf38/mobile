import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Bouton rond 34 px (retour, actions secondaires) — fond clair par défaut,
/// ou translucide sur fond sombre (écrans de scan).
class BoutonRond extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  final bool surFondSombre;
  final double taille;

  const BoutonRond({
    super.key,
    required this.icone,
    required this.onTap,
    this.surFondSombre = false,
    this.taille = 34,
  });

  /// Chevron retour standard de la maquette.
  factory BoutonRond.retour(BuildContext context, {bool surFondSombre = false}) => BoutonRond(
        icone: Icons.arrow_back_ios_new_rounded,
        surFondSombre: surFondSombre,
        onTap: () => Navigator.of(context).maybePop(),
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surFondSombre ? Colors.white.withValues(alpha: 0.12) : AppColors.surfaceL1,
      shape: const CircleBorder(),
      elevation: surFondSombre ? 0 : 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: taille,
          height: taille,
          child: Icon(icone, size: taille * 0.47, color: surFondSombre ? Colors.white : AppColors.accentBleu),
        ),
      ),
    );
  }
}
