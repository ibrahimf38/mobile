import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Champ de saisie du code retrait/livraison — numérique, 6 chiffres fixes,
/// style "encadré code" de la charte (radius 16, bordure pointillée bleue
/// dans la maquette ; ici bordure pleine, plus simple à obtenir nativement en
/// Flutter tout en restant fidèle aux couleurs).
///
/// Honnêteté fonctionnelle assumée (voir plan) : le backend ne vérifie qu'une
/// chaîne à 6 chiffres, il n'y a aucun scan de QR code réel — ce champ est
/// donc la véritable interaction, pas une décoration à côté d'une caméra.
class CodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? erreur;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const CodeInputField({
    super.key,
    required this.controller,
    this.erreur,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceL1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: erreur != null ? AppColors.danger : AppColors.accentBleu.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTextStyles.headingXL(color: AppColors.textPrimary).copyWith(letterSpacing: 10),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              filled: false,
              hintText: '000000',
            ),
          ),
        ),
        if (erreur != null) ...[
          const SizedBox(height: 6),
          Text(erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
        ],
      ],
    );
  }
}
