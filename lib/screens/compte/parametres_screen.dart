import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../auth/connexion_screen.dart';

/// Paramètres — inspiré de settings_screen.dart (vraie app MaliMall Flutter) :
/// mêmes sections (Général, Zone de danger). Les fonctionnalités qui
/// nécessiteraient un vrai réglage visuel de toute l'application (thème
/// clair/sombre) ne sont pas encore branchées ici — voir la note dans le
/// README mobile : le reskin complet est un chantier à part, pas encore fait
/// pour ce lot.
class ParametresScreen extends StatelessWidget {
  const ParametresScreen({super.key});

  Future<void> _confirmerDeconnexion(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content:
            const Text('Voulez-vous vraiment vous déconnecter de MaliMall ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Se déconnecter',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;
    await context.read<SessionProvider>().deconnecter();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ConnexionScreen()),
      (route) => false,
    );
  }

  void _bientotDisponible(BuildContext context) {
    AppFeedback.info(context, 'Cette fonctionnalité sera bientôt disponible.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Paramètres'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: [
          const _TitreSection('Général'),
          const SizedBox(height: 10),
          _panneau([
            _ligne(
              icone: Icons.lock_outline_rounded,
              label: 'Sécurité',
              onTap: () => _bientotDisponible(context),
            ),
            _ligne(
              icone: Icons.language_rounded,
              label: 'Langue',
              texteFin: 'Français',
              onTap: () => _bientotDisponible(context),
            ),
            _ligne(
              icone: Icons.help_outline_rounded,
              label: 'Aide et support',
              onTap: () => _bientotDisponible(context),
            ),
            _ligne(
              icone: Icons.info_outline_rounded,
              label: 'À propos de MaliMall',
              onTap: () => _bientotDisponible(context),
              dernier: true,
            ),
          ]),
          const SizedBox(height: 26),
          const _TitreSection('Zone de danger'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            ),
            child: _ligne(
              icone: Icons.logout_rounded,
              label: 'Se déconnecter',
              danger: true,
              dernier: true,
              onTap: () => _confirmerDeconnexion(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panneau(List<Widget> enfants) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(16)),
      child: Column(children: enfants),
    );
  }

  Widget _ligne({
    required IconData icone,
    required String label,
    required VoidCallback onTap,
    String? texteFin,
    bool dernier = false,
    bool danger = false,
  }) {
    final couleur = danger ? AppColors.danger : AppColors.textPrimary;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: (danger ? AppColors.danger : AppColors.accentBleu)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icone,
                      size: 16,
                      color: danger ? AppColors.danger : AppColors.accentBleu),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: AppTextStyles.bodyBold(color: couleur))),
                if (texteFin != null) ...[
                  Text(texteFin, style: AppTextStyles.caption()),
                  const SizedBox(width: 6),
                ],
                if (!danger)
                  const Icon(Icons.chevron_right,
                      color: AppColors.iconDisabled),
              ],
            ),
          ),
        ),
        if (!dernier)
          const Divider(height: 1, indent: 58, color: AppColors.divider),
      ],
    );
  }
}

class _TitreSection extends StatelessWidget {
  final String texte;
  const _TitreSection(this.texte);

  @override
  Widget build(BuildContext context) {
    return Text(
      texte.toUpperCase(),
      style: AppTextStyles.caption().copyWith(
          fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.52),
    );
  }
}
