import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'primary_button.dart';

/// Petits états réutilisés par la quasi-totalité des écrans qui chargent des
/// données depuis l'API — évite de dupliquer le triptyque chargement/erreur/
/// vide dans chaque écran.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppColors.accentBleu));
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onReessayer;

  const ErrorView({super.key, required this.message, this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyDefault()),
            if (onReessayer != null) ...[
              const SizedBox(height: 16),
              SizedBox(width: 160, child: PrimaryButton(label: 'Réessayer', onPressed: onReessayer)),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String message;
  final IconData icone;

  const EmptyView({super.key, required this.message, this.icone = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: AppColors.iconDisabled, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
