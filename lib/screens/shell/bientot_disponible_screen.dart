import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/en_tete_onglet.dart';

/// Écran provisoire des onglets pas encore développés (version de
/// présentation). Remplacé par le vrai écran de l'onglet quand il sera prêt.
/// Si [avecDeconnexion] est vrai, propose un bouton de déconnexion pour
/// pouvoir rejouer l'écran de connexion pendant la démonstration.
class BientotDisponibleScreen extends StatelessWidget {
  final String titre;
  final IconData icone;
  final bool avecDeconnexion;

  const BientotDisponibleScreen({
    super.key,
    required this.titre,
    required this.icone,
    this.avecDeconnexion = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          EnTeteOnglet(titre: titre, tailleTitre: 20),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icone, size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('Bientôt disponible', style: AppTextStyles.bodyBoldL(color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                      'Ce module est en cours de développement.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyDefault(color: AppColors.textSecondary),
                    ),
                    if (avecDeconnexion) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => context.read<SessionProvider>().deconnecter(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Se déconnecter'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
