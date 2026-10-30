import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/localisation.dart';
import '../../core/models/panier_models.dart';
import '../../core/quartiers.dart';
import '../../state/panier_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import 'commande_confirmee_screen.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  bool _validationEnCours = false;
  String? _quartier;
  final _precision = TextEditingController();

  /// true : le client viendra chercher lui-même sa commande chez le vendeur
  /// (pas de livreur, pas de frais de livraison) — voir CGU "Retrait en boutique".
  bool _retraitEnBoutique = false;

  /// Point exact partagé par l'acheteur (bouton "Ma position"), facultatif.
  LatLng? _pointGps;
  bool _localisation = false;

  Future<void> _utiliserMaPosition() async {
    setState(() => _localisation = true);
    final p = await Localisation.positionActuelle();
    if (!mounted) return;
    setState(() {
      _localisation = false;
      if (p != null) {
        _pointGps = p;
        _quartier = quartierLePlusProche(p);
      }
    });
    if (p == null) {
      AppFeedback.warning(
        context,
        'Position indisponible : activez la localisation ou choisissez manuellement votre quartier.',
      );
    }
  }

  @override
  void dispose() {
    _precision.dispose();
    super.dispose();
  }

  /// "Hamdallaye, rue 12 porte 40" — le quartier sert au livreur (trajet,
  /// distance), la précision à trouver la porte.
  String? get _adresse {
    final q = _quartier;
    if (q == null) return null;
    final p = _precision.text.trim();
    return p.isEmpty ? q : '$q, $p';
  }

  Future<void> _choisirQuartier() async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceL1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('Quartier de livraison',
                  style: AppTextStyles.headingM()),
            ),
            for (final q in quartiersConnus)
              ListTile(
                  title: Text(q, style: AppTextStyles.bodyDefault()),
                  onTap: () => Navigator.of(ctx).pop(q)),
          ],
        ),
      ),
    );
    if (choix != null) {
      setState(() {
        _quartier = choix;
        _pointGps = null; // quartier choisi à la main : plus de point exact
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<PanierProvider>().charger());
  }

  Future<void> _valider() async {
    if (!_retraitEnBoutique && _adresse == null) {
      AppFeedback.warning(
        context,
        'Choisissez le quartier de livraison avant de valider la commande.',
      );
      return;
    }
    setState(() => _validationEnCours = true);
    final panierProvider = context.read<PanierProvider>();
    final commandes = await panierProvider.valider(
      adresseLivraison: _retraitEnBoutique ? null : _adresse,
      latitude: _retraitEnBoutique ? null : _pointGps?.latitude,
      longitude: _retraitEnBoutique ? null : _pointGps?.longitude,
      retraitParClient: _retraitEnBoutique,
    );
    if (!mounted) return;
    setState(() => _validationEnCours = false);
    if (commandes != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => CommandeConfirmeeScreen(commandes: commandes)),
      );
    } else {
      AppFeedback.error(
        context,
        panierProvider.erreur ?? 'Impossible de valider la commande.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final panierProvider = context.watch<PanierProvider>();
    final panier = panierProvider.panier;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Mon panier'),
      body: panierProvider.enChargement
          ? const LoadingView()
          : panierProvider.erreur != null && panier == null
              ? ErrorView(
                  message: panierProvider.erreur!,
                  onReessayer: panierProvider.charger)
              : (panier == null || panier.estVide)
                  ? const EmptyView(
                      message: 'Votre panier est vide.',
                      icone: Icons.shopping_cart_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: panier.lignes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _LigneCard(
                        ligne: panier.lignes[i],
                        onSupprimer: () => context
                            .read<PanierProvider>()
                            .retirerLigne(panier.lignes[i].id),
                      ),
                    ),
      bottomNavigationBar: (panier == null || panier.estVide)
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              decoration: const BoxDecoration(
                color: AppColors.surfaceL1,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Choix du mode de remise : livraison à domicile (par défaut) ou
                    // retrait par le client lui-même chez le vendeur.
                    Row(
                      children: [
                        Expanded(
                          child: _ChoixModeRemise(
                            icone: Icons.delivery_dining_outlined,
                            label: 'Livraison',
                            actif: !_retraitEnBoutique,
                            onTap: () =>
                                setState(() => _retraitEnBoutique = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ChoixModeRemise(
                            icone: Icons.storefront_outlined,
                            label: 'Je récupère en boutique',
                            actif: _retraitEnBoutique,
                            onTap: () =>
                                setState(() => _retraitEnBoutique = true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_retraitEnBoutique) ...[
                      Material(
                        color: AppColors.surfaceL2,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _choisirQuartier,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.place_outlined,
                                    size: 16, color: AppColors.accentBleu),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _quartier ?? 'Quartier de livraison',
                                    style: _quartier == null
                                        ? AppTextStyles.bodyDefault(
                                            color: AppColors.textSecondary)
                                        : AppTextStyles.bodyMedium(),
                                  ),
                                ),
                                const Icon(Icons.expand_more,
                                    size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _localisation ? null : _utiliserMaPosition,
                          icon: Icon(
                            _pointGps != null
                                ? Icons.check_circle
                                : Icons.my_location,
                            size: 16,
                            color: _pointGps != null
                                ? AppColors.statutTermineTexte
                                : AppColors.accentBleu,
                          ),
                          label: Text(
                            _localisation
                                ? 'Localisation…'
                                : _pointGps != null
                                    ? 'Position exacte partagée avec le livreur'
                                    : 'Utiliser ma position actuelle',
                            style: AppTextStyles.caption(
                              color: _pointGps != null
                                  ? AppColors.statutTermineTexte
                                  : AppColors.accentBleu,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _precision,
                        style: AppTextStyles.bodyDefault(),
                        decoration: const InputDecoration(
                          hintText:
                              'Précision : rue, porte, repère (facultatif)',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: AppColors.surfaceL2,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: AppColors.accentBleu),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Vous récupérerez la commande vous-même chez le vendeur, avec un code à présenter — pas de frais de livraison.',
                                style: AppTextStyles.caption(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child:
                              Text('Total', style: AppTextStyles.bodyMedium()),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${formatMmc(panier.totalMmc)} MMC',
                              style: AppTextStyles.headingM(
                                  color: AppColors.accentBleu),
                            ),
                            Text(
                              '≈ ${formatMmc(equivalentFcfa(panier.totalMmc))} FCFA',
                              style: AppTextStyles.captionSmall(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _retraitEnBoutique
                          ? 'Aucun frais de livraison : vous récupérez la commande vous-même.'
                          : 'Les frais de livraison sont calculés par commande, après validation.',
                      style: AppTextStyles.caption(),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Valider la commande',
                      enChargement: _validationEnCours,
                      onPressed: _valider,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Chip "Livraison" / "Je récupère en boutique" du panier — voir _valider.
class _ChoixModeRemise extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool actif;
  final VoidCallback onTap;

  const _ChoixModeRemise({
    required this.icone,
    required this.label,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: actif
          ? AppColors.accentBleu.withValues(alpha: 0.1)
          : AppColors.surfaceL2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: actif ? AppColors.accentBleu : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone,
                  size: 15,
                  color:
                      actif ? AppColors.accentBleu : AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(
                          color: actif
                              ? AppColors.accentBleu
                              : AppColors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneCard extends StatelessWidget {
  final LigneResponse ligne;
  final VoidCallback onSupprimer;

  const _LigneCard({required this.ligne, required this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppColors.surfaceL2,
                borderRadius: BorderRadius.circular(11)),
            child: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.accentBleu, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ligne.produitNom, style: AppTextStyles.bodyMedium()),
                const SizedBox(height: 2),
                Text(ligne.boutiqueNom, style: AppTextStyles.caption()),
                const SizedBox(height: 2),
                Text(
                  '${ligne.quantite} × ${formatMmc(ligne.prixUnitaireMmc)} MMC · ≈ ${formatMmc(equivalentFcfa(ligne.prixUnitaireMmc))} FCFA / unité',
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatMmc(ligne.sousTotal)} MMC\n≈ ${formatMmc(equivalentFcfa(ligne.sousTotal))} FCFA',
                textAlign: TextAlign.end,
                style: AppTextStyles.bodyBold(),
              ),
              IconButton(
                iconSize: 18,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: onSupprimer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
