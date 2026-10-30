import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/commande_models.dart';
import '../../core/services/commande_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/primary_button.dart';

/// Maquette 37 — ouvert par l'acheteur (suivi) ou le livreur (en route).
/// Tant qu'un signalement est ouvert, la confirmation de livraison est
/// bloquée côté backend : les fonds restent gelés. Renvoie `true` si envoyé.
class SignalerProblemeScreen extends StatefulWidget {
  final int commandeId;
  const SignalerProblemeScreen({super.key, required this.commandeId});

  @override
  State<SignalerProblemeScreen> createState() => _SignalerProblemeScreenState();
}

class _SignalerProblemeScreenState extends State<SignalerProblemeScreen> {
  MotifSignalement? _motif;
  final _description = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final motif = _motif;
    if (motif == null) {
      setState(() => _erreur = 'Choisissez ce qui se passe.');
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final texte = _description.text.trim();
      await context
          .read<CommandeService>()
          .signaler(widget.commandeId, motif, texte.isEmpty ? null : texte);
      if (!mounted) return;
      AppFeedback.success(context, 'Votre signalement a bien été envoyé.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Signaler un problème'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Text(
            "La commande reste protégée : tant qu'un signalement est en cours, aucun fonds n'est débloqué "
            'sans validation de notre équipe.',
            style: AppTextStyles.caption()
                .copyWith(fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 16),
          const TitreSection('Que se passe-t-il ?'),
          const SizedBox(height: 10),
          for (final m in MotifSignalement.values) ...[
            _OptionMotif(
                motif: m,
                choisi: _motif == m,
                onTap: () => setState(() => _motif = m)),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 6),
          const TitreSection('Décrivez la situation'),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.bodyDefault(),
            decoration: const InputDecoration(
              hintText:
                  'Le vendeur ne répondait pas à l\'arrivée du livreur, la boutique semblait fermée…',
            ),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 6),
            Text(_erreur!,
                style: AppTextStyles.bodyMedium(color: AppColors.danger)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Notre équipe examine chaque signalement avant tout déblocage.',
                textAlign: TextAlign.center,
                style: AppTextStyles.captionSmall(),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                  label: 'Envoyer le signalement',
                  enChargement: _envoi,
                  onPressed: _envoyer),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionMotif extends StatelessWidget {
  final MotifSignalement motif;
  final bool choisi;
  final VoidCallback onTap;
  const _OptionMotif(
      {required this.motif, required this.choisi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: choisi
          ? AppColors.accentBleu.withValues(alpha: 0.08)
          : AppColors.surfaceL1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: choisi ? AppColors.accentBleu : AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  motif.libelle,
                  style: AppTextStyles.bodyMedium(
                      color: choisi
                          ? AppColors.accentBleu
                          : AppColors.textPrimary),
                ),
              ),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: choisi ? AppColors.accentBleu : Colors.transparent,
                  border: Border.all(
                      color: choisi
                          ? AppColors.accentBleu
                          : AppColors.iconDisabled),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
