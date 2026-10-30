import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/models/commande_models.dart';
import '../../core/services/catalogue_service.dart';
import '../../core/services/commande_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/state_views.dart';

/// Maquette 29 — statistiques de ventes du vendeur, calculées à partir de
/// ses vraies commandes (livrées) et de ses produits.
class StatistiquesVentesScreen extends StatefulWidget {
  final int boutiqueId;
  const StatistiquesVentesScreen({super.key, required this.boutiqueId});

  @override
  State<StatistiquesVentesScreen> createState() =>
      _StatistiquesVentesScreenState();
}

class _StatistiquesVentesScreenState extends State<StatistiquesVentesScreen> {
  List<CommandeResponse> _commandes = [];
  List<ProduitResponse> _produits = [];
  String? _erreur;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final commandeService = context.read<CommandeService>();
      final catalogue = context.read<CatalogueService>();
      final commandes = await commandeService.mesCommandes(role: 'vendeur');
      final produits = await catalogue.produitsDeLaBoutique(widget.boutiqueId);
      if (!mounted) return;
      setState(() {
        _commandes = commandes;
        _produits = produits;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  /// Chiffre d'affaires livré des 7 derniers jours, jour par jour.
  List<({String jour, int montant})> get _septJours {
    const noms = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final aujourdHui = DateTime.now();
    return List.generate(7, (i) {
      final jour = DateTime(aujourdHui.year, aujourdHui.month, aujourdHui.day)
          .subtract(Duration(days: 6 - i));
      final montant =
          _commandes.where((c) => c.statut == StatutCommande.livree).where((c) {
        final d = (c.dateLivraison ?? c.dateCommande).toLocal();
        return d.year == jour.year &&
            d.month == jour.month &&
            d.day == jour.day;
      }).fold<int>(0, (t, c) => t + c.montantTotalMmc);
      return (jour: noms[jour.weekday - 1], montant: montant);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Statistiques de ventes'),
      body: _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : RefreshIndicator(onRefresh: _charger, child: _corps()),
    );
  }

  Widget _corps() {
    final livrees =
        _commandes.where((c) => c.statut == StatutCommande.livree).toList();
    final ca = livrees.fold<int>(0, (t, c) => t + c.montantTotalMmc);
    final panierMoyen = livrees.isEmpty ? 0 : ca ~/ livrees.length;
    final top = [..._produits]
      ..sort((a, b) => b.quantiteVendue.compareTo(a.quantiteVendue));
    final jours = _septJours;
    final max = jours.fold<int>(0, (m, j) => j.montant > m ? j.montant : m);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.accentBleu,
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chiffre d\'affaires livré',
                  style: AppTextStyles.bodyDefault(
                          color: Colors.white.withValues(alpha: 0.75))
                      .copyWith(fontSize: 11.5)),
              const SizedBox(height: 4),
              Text('${formatMmc(ca)} MMC',
                  style: AppTextStyles.displayMontant(color: Colors.white)),
              const SizedBox(height: 2),
              Text('≈ ${formatMmc(ca * 5)} FCFA',
                  style: AppTextStyles.bodyDefault(
                      color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _tuile(formatMmc(_commandes.length), 'Commandes')),
            const SizedBox(width: 10),
            Expanded(child: _tuile(formatMmc(livrees.length), 'Livrées')),
            const SizedBox(width: 10),
            Expanded(child: _tuile(formatMmc(panierMoyen), 'MMC / commande')),
          ],
        ),
        const SizedBox(height: 20),
        const TitreSection('7 derniers jours'),
        const SizedBox(height: 9),
        Container(
          height: 158,
          padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
          decoration: BoxDecoration(
              color: AppColors.surfaceL1,
              borderRadius: BorderRadius.circular(15)),
          child: Stack(
            children: [
              // Lignes de fréquence (repères horizontaux) — facilitent la
              // lecture des valeurs, comme sur les graphiques admin.
              Positioned.fill(
                bottom: 20,
                child: Column(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                              height: 1,
                              color: AppColors.divider.withValues(alpha: 0.7)),
                        ),
                      ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final j in jours)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => AppFeedback.info(
                            context,
                            '${j.jour} : ${formatMmc(j.montant)} MMC',
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Valeur affichée en clair uniquement sur la barre la
                              // plus haute (étiquette sélective) — les autres se
                              // consultent d'un tap (voir onTap ci-dessus).
                              if (max > 0 && j.montant == max)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(formatMmc(j.montant),
                                      style: AppTextStyles.bodyBold()
                                          .copyWith(fontSize: 10.5)),
                                ),
                              Flexible(
                                child: FractionallySizedBox(
                                  alignment: Alignment.bottomCenter,
                                  heightFactor: max == 0
                                      ? 0.04
                                      : (j.montant / max).clamp(0.04, 1.0),
                                  child: Container(
                                    width: 18,
                                    decoration: BoxDecoration(
                                      color: j.montant > 0
                                          ? AppColors.accentBleu
                                          : AppColors.divider,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                        bottom: Radius.circular(3),
                                      ),
                                      boxShadow: j.montant > 0
                                          ? [
                                              BoxShadow(
                                                color: AppColors.accentBleu
                                                    .withValues(alpha: 0.28),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                  height: 1,
                                  color: AppColors.divider,
                                  margin: const EdgeInsets.only(bottom: 6)),
                              Text(j.jour, style: AppTextStyles.captionSmall()),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const TitreSection('Meilleures ventes'),
        const SizedBox(height: 9),
        if (top.every((p) => p.quantiteVendue == 0))
          Text('Pas encore de vente.',
              style: AppTextStyles.bodyDefault(color: AppColors.textSecondary))
        else
          ...top.where((p) => p.quantiteVendue > 0).take(5).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: CarteListe(
                  child: Row(
                    children: [
                      VignettePastel(graine: p.id, taille: 38),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(p.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium()),
                      ),
                      Text(
                          '${p.quantiteVendue} vendu${p.quantiteVendue > 1 ? 's' : ''}',
                          style: AppTextStyles.bodyBold(
                                  color: AppColors.accentBleu)
                              .copyWith(fontSize: 12.5)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _tuile(String chiffre, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(chiffre,
              style: AppTextStyles.titleS()
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionSmall().copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}
