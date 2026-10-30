import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/suivi_etapes.dart';
import '../commandes/commandes_liste_screen.dart';
import '../livraison/suivi_commande_screen.dart';
import '../shell/main_shell.dart';

/// Maquette 10 — confirmation après validation du panier. Le backend crée
/// une commande par boutique : l'écran gère donc une LISTE de commandes
/// (montant réservé cumulé, un bloc d'articles par commande).
///
/// Aucun code n'est affiché ici : le code de livraison n'existe pour
/// l'acheteur qu'une fois le colis récupéré (voir Suivi de commande).
class CommandeConfirmeeScreen extends StatelessWidget {
  final List<CommandeResponse> commandes;
  const CommandeConfirmeeScreen({super.key, required this.commandes});

  void _retourAccueil(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  /// Le texte diffère selon que TOUTES les commandes sont en retrait sur
  /// place, TOUTES avec livreur, ou un mélange des deux (panier réparti sur
  /// plusieurs boutiques avec des choix différents).
  String _sousTitre(List<CommandeResponse> commandes) {
    final toutesRetrait = commandes.every((c) => c.retraitParClient);
    final toutesLivraison = commandes.every((c) => !c.retraitParClient);
    final pluriel = commandes.length > 1;
    if (toutesRetrait) {
      return pluriel
          ? 'Les vendeurs ont été notifiés. Présentez votre code à chacun pour récupérer vos commandes.'
          : 'Le vendeur a été notifié. Présentez votre code sur place pour récupérer votre commande.';
    }
    if (toutesLivraison) {
      return pluriel
          ? 'Les vendeurs ont été notifiés. Nous cherchons des livreurs disponibles.'
          : 'Le vendeur a été notifié. Nous cherchons un livreur disponible.';
    }
    return 'Les vendeurs ont été notifiés — retrait sur place pour certaines commandes, livraison pour les autres.';
  }

  void _suivre(BuildContext context) {
    final navigateur = Navigator.of(context);
    navigateur.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
    navigateur.push(MaterialPageRoute(
      builder: (_) => commandes.length == 1
          ? SuiviCommandeScreen(commandeId: commandes.first.id)
          : const CommandesListeScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final totalReserve = commandes.fold<int>(0, (t, c) => t + c.montantTotalAvecLivraison);
    final lignes = [for (final c in commandes) ...c.lignes];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _retourAccueil(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _retourAccueil(context),
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(color: AppColors.surfaceL1, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.accentBleu),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(commandes.length > 1 ? 'Mes commandes' : 'Ma commande',
                        style: AppTextStyles.titleAppBar()),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(color: AppColors.accentBleu, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      commandes.length > 1 ? '${commandes.length} commandes confirmées !' : 'Commande confirmée !',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingM().copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _sousTitre(commandes),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyDefault(color: AppColors.textSecondary).copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    _CarteMontantReserve(total: totalReserve),
                    const SizedBox(height: 20),
                    const SuiviEtapes(),
                    const SizedBox(height: 20),
                    ...lignes.map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LigneArticle(ligne: l),
                        )),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: PrimaryButton(label: 'Suivre ma commande', onPressed: () => _suivre(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encadré pointillé "X MMC réservés".
class _CarteMontantReserve extends StatelessWidget {
  final int total;
  const _CarteMontantReserve({required this.total});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _BordurePointillee(couleur: AppColors.accentBleu, rayon: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.accentBleu.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, size: 17, color: AppColors.accentBleu),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${formatMmc(total)} MMC réservés · ≈ ${formatMmc(equivalentFcfa(total))} FCFA',
                      style: AppTextStyles.bodyBold(color: AppColors.accentBleu).copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    "Le montant reste bloqué sur votre portefeuille et ne sera débité qu'à la confirmation de la livraison.",
                    style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                        .copyWith(fontSize: 10.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneArticle extends StatelessWidget {
  final LigneCommandeResponse ligne;
  const _LigneArticle({required this.ligne});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE7DDFB), borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.shopping_bag_outlined, size: 19, color: AppColors.accentViolet),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ligne.produitNom,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium()),
                const SizedBox(height: 2),
                Text('Qté : ${ligne.quantite}',
                    style: AppTextStyles.bodyDefault(color: AppColors.textSecondary).copyWith(fontSize: 10.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${formatMmc(ligne.sousTotal)} MMC',
                  style: AppTextStyles.bodyBold(color: AppColors.accentBleu).copyWith(fontSize: 13)),
              Text('≈ ${formatMmc(equivalentFcfa(ligne.sousTotal))} FCFA',
                  style: AppTextStyles.captionSmall()),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bordure en pointillés arrondie (Flutter n'a pas de BorderStyle.dashed).
class _BordurePointillee extends CustomPainter {
  final Color couleur;
  final double rayon;
  _BordurePointillee({required this.couleur, required this.rayon});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final chemin = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(rayon)));
    for (final metrique in chemin.computeMetrics()) {
      var distance = 0.0;
      while (distance < metrique.length) {
        canvas.drawPath(metrique.extractPath(distance, distance + 4), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordurePointillee oldDelegate) =>
      oldDelegate.couleur != couleur || oldDelegate.rayon != rayon;
}
