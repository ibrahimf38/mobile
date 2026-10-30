import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../core/services/commande_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/state_views.dart';
import 'detail_commande_vendeur_screen.dart';

enum _Filtre { toutes, enAttente, retrait, livrees }

/// Libellé + couleur du statut d'une commande côté vendeur (maquette 13).
({String texte, Color couleur, Color? couleurTexte}) statutVendeur(CommandeResponse c) {
  if (c.statut == StatutCommande.annulee) return (texte: 'Annulée', couleur: AppColors.danger, couleurTexte: null);
  if (c.statut == StatutCommande.livree || c.statutLivraison == StatutLivraison.livree) {
    return (
      texte: c.retraitParClient ? 'Remise au client' : 'Livrée',
      couleur: AppColors.statutTermineFond,
      couleurTexte: AppColors.statutTermineTexte,
    );
  }
  if (c.retraitParClient) return (texte: 'Retrait client', couleur: AppColors.accentOrange, couleurTexte: null);
  switch (c.statutLivraison) {
    case null:
      return (texte: "En attente d'un livreur", couleur: AppColors.accentOrange, couleurTexte: null);
    case StatutLivraison.assignee:
      return (texte: 'Livreur en route', couleur: AppColors.accentBleu, couleurTexte: null);
    case StatutLivraison.recuperee:
    case StatutLivraison.enRoute:
    case StatutLivraison.livree:
      return (texte: 'En livraison', couleur: AppColors.accentBleu, couleurTexte: null);
  }
}

/// Maquette 13 — commandes reçues par la boutique, filtrables.
class CommandesBoutiqueScreen extends StatefulWidget {
  const CommandesBoutiqueScreen({super.key});

  @override
  State<CommandesBoutiqueScreen> createState() => _CommandesBoutiqueScreenState();
}

class _CommandesBoutiqueScreenState extends State<CommandesBoutiqueScreen> {
  List<CommandeResponse>? _commandes;
  String? _erreur;
  bool _chargement = true;
  _Filtre _filtre = _Filtre.toutes;

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
      final commandes = await context.read<CommandeService>().mesCommandes(role: 'vendeur');
      if (!mounted) return;
      setState(() => _commandes = commandes..sort((a, b) => b.dateCommande.compareTo(a.dateCommande)));
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

  bool _correspond(CommandeResponse c) {
    final livree = c.statut == StatutCommande.livree;
    switch (_filtre) {
      case _Filtre.toutes:
        return true;
      case _Filtre.enAttente:
        return !livree && c.statut != StatutCommande.annulee && c.statutLivraison == null;
      case _Filtre.retrait:
        return !livree && c.statutLivraison == StatutLivraison.assignee;
      case _Filtre.livrees:
        return livree;
    }
  }

  @override
  Widget build(BuildContext context) {
    const filtres = {
      _Filtre.toutes: 'Toutes',
      _Filtre.enAttente: 'En attente',
      _Filtre.retrait: 'Retrait',
      _Filtre.livrees: 'Livrées',
    };
    final visibles = (_commandes ?? []).where(_correspond).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Commandes'),
      body: Column(
        children: [
          SizedBox(
            height: 49,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              children: [
                for (final e in filtres.entries) ...[
                  ChipFiltre(label: e.value, actif: _filtre == e.key, onTap: () => setState(() => _filtre = e.key)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: _chargement
                ? const LoadingView()
                : _erreur != null
                    ? ErrorView(message: _erreur!, onReessayer: _charger)
                    : visibles.isEmpty
                        ? const EmptyView(message: 'Aucune commande ici pour le moment.', icone: Icons.receipt_long_outlined)
                        : RefreshIndicator(
                            onRefresh: _charger,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: visibles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) => LigneCommandeVendeur(
                                commande: visibles[i],
                                onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => DetailCommandeVendeurScreen(commandeId: visibles[i].id),
                                  ));
                                  _charger();
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class LigneCommandeVendeur extends StatelessWidget {
  final CommandeResponse commande;
  final VoidCallback onTap;
  const LigneCommandeVendeur({super.key, required this.commande, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statut = statutVendeur(commande);
    final premier = commande.lignes.isNotEmpty ? commande.lignes.first.produitNom : 'Commande';
    final autres = commande.lignes.length - 1;
    final actionRequise = commande.statutLivraison == StatutLivraison.assignee && commande.statut != StatutCommande.livree;
    final attenteRetraitClient = commande.retraitParClient && commande.statut != StatutCommande.livree
        && commande.statut != StatutCommande.annulee;

    return CarteListe(
      onTap: onTap,
      child: Row(
        children: [
          VignettePastel(graine: commande.lignes.isNotEmpty ? commande.lignes.first.produitId : commande.id),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(autres > 0 ? '$premier +$autres' : premier,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyMedium().copyWith(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('N°${commande.id} · ${formatMmc(commande.montantTotalMmc)} MMC',
                        style: AppTextStyles.caption().copyWith(fontSize: 10, fontWeight: FontWeight.w400)),
                    Pastille(texte: statut.texte, couleur: statut.couleur, couleurTexte: statut.couleurTexte),
                  ],
                ),
                if (actionRequise) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.two_wheeler, size: 12, color: AppColors.accentBleu),
                      const SizedBox(width: 6),
                      Text('Préparez le colis et le code de retrait',
                          style: AppTextStyles.bodyMedium(color: AppColors.accentBleu).copyWith(fontSize: 10)),
                    ],
                  ),
                ],
                if (attenteRetraitClient) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 12, color: AppColors.accentBleu),
                      const SizedBox(width: 6),
                      Text('Le client viendra la chercher — validez son code à son arrivée',
                          style: AppTextStyles.bodyMedium(color: AppColors.accentBleu).copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textPrimary),
        ],
      ),
    );
  }
}
