import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Bouton plein "pilule" — le bouton d'action principal de toute la charte
/// (radius 100, ombre bleue portée, cf. la maquette Figma MaliMall §6).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool enChargement;
  final IconData? icone;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enChargement = false,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enChargement ? null : onPressed,
        child: enChargement
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icone != null) ...[
                    Icon(icone, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Variante "outline" rouge — utilisée pour la déconnexion (radius 100,
/// bordure 1.4px rouge, cf. spec).
class DangerOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const DangerOutlineButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: AppColors.danger)),
      ),
    );
  }
}
