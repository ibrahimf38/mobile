import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../core/services/commande_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/etoiles_notation.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/primary_button.dart';

/// Maquette 27 — après le scan du code de livraison par l'acheteur :
/// fonds débités, vendeur et livreur crédités, notation du livreur.
class LivraisonConfirmeeScreen extends StatefulWidget {
  final CommandeResponse commande;
  const LivraisonConfirmeeScreen({super.key, required this.commande});

  @override
  State<LivraisonConfirmeeScreen> createState() =>
      _LivraisonConfirmeeScreenState();
}

class _LivraisonConfirmeeScreenState extends State<LivraisonConfirmeeScreen> {
  int _note = 0;
  bool _envoi = false;

  Future<void> _terminer() async {
    final c = widget.commande;
    if (_note > 0 && c.noteLivreur == null) {
      setState(() => _envoi = true);
      try {
        await context.read<CommandeService>().noterLivreur(c.id, _note);
      } catch (e) {
        if (mounted) {
          AppFeedback.error(context, messageErreur(e));
        }
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 16),
          child: Column(
            children: [
              const PastilleSucces(),
              const SizedBox(height: 18),
              Text('Livraison confirmée !', style: AppTextStyles.headingL()),
              const SizedBox(height: 8),
              Text(
                'Les fonds bloqués ont été débités. Le vendeur et le livreur ont été crédités automatiquement.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                    .copyWith(height: 1.5),
              ),
              const SizedBox(height: 20),
              CarteListe(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    VignettePastel(graine: c.id),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.resumeArticles,
                              style: AppTextStyles.bodyBold(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            c.dateLivraison == null
                                ? c.boutiqueNom
                                : 'Livré à ${heureMinute(c.dateLivraison!)}',
                            style: AppTextStyles.caption(),
                          ),
                        ],
                      ),
                    ),
                    Text('${formatMmc(c.montantTotalAvecLivraison)} MMC',
                        style: AppTextStyles.bodyBold(
                            color: AppColors.accentBleu)),
                  ],
                ),
              ),
              if (c.chauffeurNom != null) ...[
                const SizedBox(height: 24),
                Text('Notez votre livreur', style: AppTextStyles.bodyBold()),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AvatarIcone(icone: Icons.two_wheeler),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.chauffeurNom!, style: AppTextStyles.bodyBold()),
                        Text(
                          [c.vehiculeLibelle, c.vehiculeImmatriculation]
                              .whereType<String>()
                              .join(' · '),
                          style: AppTextStyles.caption(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                EtoilesNotation(
                  note: c.noteLivreur ?? _note,
                  onChanged: c.noteLivreur == null
                      ? (n) => setState(() => _note = n)
                      : null,
                ),
              ],
              const Spacer(),
              PrimaryButton(
                  label: 'Terminer',
                  enChargement: _envoi,
                  onPressed: _terminer),
            ],
          ),
        ),
      ),
    );
  }
}
