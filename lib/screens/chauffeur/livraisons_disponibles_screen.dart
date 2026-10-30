import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../core/models/livreur_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/commande_service.dart';
import '../../core/services/livreur_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import 'livraison_en_cours_screen.dart';

/// Maquette 30 — livraisons Market en attente d'un livreur. Chaque carte
/// indique le trajet, le poids et les frais gagnés ; une livraison trop
/// lourde pour le véhicule du livreur est grisée ("Non disponible"), le
/// backend refusant de toute façon l'assignation.
class LivraisonsDisponiblesScreen extends StatefulWidget {
  const LivraisonsDisponiblesScreen({super.key});

  @override
  State<LivraisonsDisponiblesScreen> createState() =>
      _LivraisonsDisponiblesScreenState();
}

class _LivraisonsDisponiblesScreenState
    extends State<LivraisonsDisponiblesScreen> {
  List<CommandeResponse>? _commandes;
  EspaceLivreurResponse? _livreur;
  String? _erreur;
  int? _enCours;
  final Set<int> _refusees = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final livreur = await context.read<LivreurService>().resume();
      if (!mounted) return;
      final commandes = await context.read<CommandeService>().disponibles();
      if (!mounted) return;
      setState(() {
        _livreur = livreur;
        _commandes = commandes;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    }
  }

  Future<void> _accepter(CommandeResponse c) async {
    setState(() => _enCours = c.id);
    try {
      await context.read<CommandeService>().assignerChauffeur(c.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LivraisonEnCoursScreen(commandeId: c.id)));
      if (mounted) await _charger();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, messageErreur(e));
      await _charger();
    } finally {
      if (mounted) setState(() => _enCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commandes =
        _commandes?.where((c) => !_refusees.contains(c.id)).toList();
    final l = _livreur;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Livraisons Market'),
      body: commandes == null
          ? (_erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : const LoadingView())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  if (l != null)
                    Text.rich(
                      TextSpan(
                        text: 'Votre véhicule : ',
                        children: [
                          TextSpan(
                              text: l.vehiculeLibelle,
                              style: AppTextStyles.caption(
                                      color: AppColors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                          TextSpan(text: ' — compatible ${l.capaciteLibelle}'),
                        ],
                      ),
                      style: AppTextStyles.caption()
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 12),
                  if (commandes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: EmptyView(
                          message:
                              'Aucune livraison en attente pour le moment.',
                          icone: Icons.inventory_2_outlined),
                    ),
                  for (final c in commandes) ...[
                    _CarteLivraison(
                      commande: c,
                      livreur: l,
                      enCours: _enCours == c.id,
                      onRefuser: () => setState(() => _refusees.add(c.id)),
                      onAccepter: _enCours == null ? () => _accepter(c) : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CarteLivraison extends StatelessWidget {
  final CommandeResponse commande;
  final EspaceLivreurResponse? livreur;
  final bool enCours;
  final VoidCallback onRefuser;
  final VoidCallback? onAccepter;

  const _CarteLivraison({
    required this.commande,
    required this.livreur,
    required this.enCours,
    required this.onRefuser,
    required this.onAccepter,
  });

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final compatible = livreur?.peutTransporter(c.poidsTotalKg) ?? true;
    final quartierAcheteur = quartierDansAdresse(c.adresseLivraison);
    final km = distanceKmEntre(c.boutiqueQuartier, quartierAcheteur);
    final trajet = [
      [c.boutiqueQuartier, quartierAcheteur].whereType<String>().join(' → '),
      if (km != null) '$km km',
    ].where((s) => s.isNotEmpty).join(' · ');
    final poids = c.poidsTotalKg == c.poidsTotalKg.roundToDouble()
        ? c.poidsTotalKg.toInt().toString()
        : c.poidsTotalKg.toStringAsFixed(1);

    return Opacity(
      opacity: compatible ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surfaceL1,
            borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VignettePastel(graine: c.boutiqueId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.boutiqueNom, style: AppTextStyles.bodyBold()),
                      const SizedBox(height: 3),
                      Text(trajet.isEmpty ? (c.adresseLivraison ?? '') : trajet,
                          style: AppTextStyles.caption()),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        '+${formatMmc(netApresCommission(c.fraisLivraisonMmc))}',
                        style: AppTextStyles.bodyBold(
                            color: AppColors.accentBleu)),
                    Text('MMC', style: AppTextStyles.captionSmall()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Etiquette('$poids kg'),
                _Etiquette(c.resumeArticles),
              ],
            ),
            const SizedBox(height: 12),
            if (!compatible) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nécessite un TriCycle (charge lourde ou volumineuse). '
                        'Non compatible avec votre ${livreur?.vehiculeLibelle ?? 'véhicule'}.',
                        style: AppTextStyles.caption(color: AppColors.danger)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.surfaceL2,
                    borderRadius: BorderRadius.circular(23)),
                child: Text('Non disponible',
                    style:
                        AppTextStyles.bodyBold(color: AppColors.textSecondary)),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: TextButton(
                        onPressed: onRefuser,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceL2,
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Refuser', style: AppTextStyles.bodyBold()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: PrimaryButton(
                        label: 'Accepter',
                        enChargement: enCours,
                        onPressed: onAccepter),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Etiquette extends StatelessWidget {
  final String texte;
  const _Etiquette(this.texte);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.surfaceL2, borderRadius: BorderRadius.circular(8)),
      child: Text(texte,
          style: AppTextStyles.captionSmall(color: AppColors.textPrimary)
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }
}
