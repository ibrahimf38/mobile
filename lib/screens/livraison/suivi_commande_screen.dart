import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/commande_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/carte_code_qr.dart';
import '../../widgets/carte_malimall.dart';
import '../../widgets/ecran_scan_code.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import 'livraison_confirmee_screen.dart';
import 'signaler_probleme_screen.dart';

/// Maquette 25 — suivi côté acheteur : article, livreur assigné, frise
/// verticale horodatée, puis scan du code de livraison que le livreur
/// affiche (maquette 26). Rafraîchi toutes les 10 s tant que non livrée.
class SuiviCommandeScreen extends StatefulWidget {
  final int commandeId;
  const SuiviCommandeScreen({super.key, required this.commandeId});

  @override
  State<SuiviCommandeScreen> createState() => _SuiviCommandeScreenState();
}

class _SuiviCommandeScreenState extends State<SuiviCommandeScreen> {
  CommandeResponse? _commande;
  String? _erreur;
  Timer? _timer;
  bool _annulationEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final c = _commande;
      if (c != null &&
          (c.statut == StatutCommande.livree ||
              c.statut == StatutCommande.annulee)) {
        return;
      }
      _charger(silencieux: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    try {
      final c =
          await context.read<CommandeService>().obtenir(widget.commandeId);
      if (!mounted) return;
      setState(() {
        _commande = c;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted || silencieux) return;
      setState(() => _erreur = messageErreur(e));
    }
  }

  Future<void> _scanner() async {
    final service = context.read<CommandeService>();
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(
      builder: (scanContext) => EcranScanCode(
        titre: 'Confirmer la réception',
        consigne: 'Scannez le QR du livreur',
        sousConsigne:
            "Demandez au livreur d'afficher son code de livraison et centrez-le dans le cadre.",
        avertissement:
            "Ne confirmez qu'une fois le colis physiquement remis entre vos mains.",
        onCode: (code) async {
          final c = await service.confirmerLivraison(widget.commandeId, code);
          if (!scanContext.mounted) return;
          await Navigator.of(scanContext).pushReplacement(
            MaterialPageRoute(
                builder: (_) => LivraisonConfirmeeScreen(commande: c)),
          );
        },
      ),
    ));
    await _charger(silencieux: true);
  }

  Future<void> _signaler() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              SignalerProblemeScreen(commandeId: widget.commandeId)),
    );
    await _charger(silencieux: true);
  }

  Future<void> _annuler() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette commande ?'),
        content: const Text(
          'Le montant réservé sera libéré et les articles remis en stock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder la commande'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler la commande'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    setState(() => _annulationEnCours = true);
    try {
      final commande =
          await context.read<CommandeService>().annuler(widget.commandeId);
      if (!mounted) return;
      setState(() => _commande = commande);
      AppFeedback.success(
        context,
        'Commande annulée. Les fonds sont libérés.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
      await _charger(silencieux: true);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
      await _charger(silencieux: true);
    } finally {
      if (mounted) setState(() => _annulationEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _commande;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Suivi de commande'),
      body: c == null
          ? (_erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : const LoadingView())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  _CarteArticle(commande: c),
                  if (c.retraitParClient) ...[
                    const SizedBox(height: 16),
                    if (c.codeRetrait != null &&
                        c.statut != StatutCommande.livree)
                      CarteCodeQr(
                        code: c.codeRetrait!,
                        legende:
                            'Présentez ce code au vendeur pour retirer votre commande.',
                      ),
                    const SizedBox(height: 20),
                    _FriseRetraitClient(commande: c),
                  ] else ...[
                    if (c.chauffeurNom != null) ...[
                      const SizedBox(height: 14),
                      _CarteLivreur(commande: c),
                    ],
                    if (c.chauffeurPosition != null) ...[
                      const SizedBox(height: 14),
                      _CarteSuiviDirect(commande: c),
                    ],
                    const SizedBox(height: 20),
                    _FriseVerticale(commande: c),
                  ],
                  if (c.signalee) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Un signalement est en cours : la commande est suspendue et vos fonds restent protégés.',
                        style: AppTextStyles.caption(color: AppColors.danger)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: c == null ? null : _barreActions(c),
    );
  }

  Widget? _barreActions(CommandeResponse c) {
    final termine =
        c.statut == StatutCommande.livree || c.statut == StatutCommande.annulee;
    if (termine) return null;
    // Retrait sur place : rien à scanner côté client — c'est le vendeur qui valide
    // le code que le client lui présente (voir CommandesBoutiqueScreen).
    final annulable = c.statut == StatutCommande.confirmee &&
        c.chauffeurId == null &&
        (c.retraitParClient || c.statutLivraison == null) &&
        !c.signalee;
    if (c.retraitParClient) {
      if (c.signalee && !annulable) return null;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (annulable)
                TextButton.icon(
                  onPressed: _annulationEnCours ? null : _annuler,
                  icon: _annulationEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler la commande'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.danger),
                ),
              if (!c.signalee)
                LienDiscret('Un problème avec ce retrait ?', onTap: _signaler),
            ],
          ),
        ),
      );
    }
    final colisEnRoute = c.statutLivraison == StatutLivraison.recuperee ||
        c.statutLivraison == StatutLivraison.enRoute;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (annulable)
              TextButton.icon(
                onPressed: _annulationEnCours ? null : _annuler,
                icon: _annulationEnCours
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Annuler la commande'),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              ),
            PrimaryButton(
              label: 'Scanner le code du livreur',
              icone: Icons.qr_code_scanner_rounded,
              onPressed: colisEnRoute && !c.signalee ? _scanner : null,
            ),
            if (!c.signalee)
              LienDiscret('Un problème avec cette livraison ?',
                  onTap: _signaler),
          ],
        ),
      ),
    );
  }
}

class _CarteArticle extends StatelessWidget {
  final CommandeResponse commande;
  const _CarteArticle({required this.commande});

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final (texte, couleur) = switch (c.statutAffiche) {
      StatutAffiche.enAttente => ('En attente', AppColors.statutEnAttente),
      StatutAffiche.enTransit => ('En livraison', AppColors.statutEnTransit),
      StatutAffiche.termine => ('Livrée', AppColors.statutTermineTexte),
      StatutAffiche.annule => ('Annulée', AppColors.statutAnnule),
    };
    return CarteListe(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VignettePastel(graine: c.id, icone: Icons.checkroom_outlined),
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
                        '${c.boutiqueNom} · ${formatMmc(c.montantTotalAvecLivraison)} MMC',
                        style: AppTextStyles.caption()),
                  ],
                ),
              ),
              Pastille(texte: texte, couleur: couleur),
            ],
          ),
          const Divider(height: 24),
          ...c.lignes.map((ligne) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${ligne.quantite} × ${ligne.produitNom}',
                        style: AppTextStyles.bodyDefault(),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${formatMmc(ligne.sousTotal)} MMC\n≈ ${formatMmc(equivalentFcfa(ligne.sousTotal))} FCFA',
                        textAlign: TextAlign.end,
                        style: AppTextStyles.caption(),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Text(
            'Total : ${formatMmc(c.montantTotalAvecLivraison)} MMC\n≈ ${formatMmc(equivalentFcfa(c.montantTotalAvecLivraison))} FCFA',
            style: AppTextStyles.bodyBold(color: AppColors.accentBleu),
          ),
        ],
      ),
    );
  }
}

class _CarteLivreur extends StatelessWidget {
  final CommandeResponse commande;
  const _CarteLivreur({required this.commande});

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final etat = switch (c.statutLivraison) {
      StatutLivraison.assignee => 'En route vers la boutique',
      StatutLivraison.recuperee ||
      StatutLivraison.enRoute =>
        'En route vers vous',
      StatutLivraison.livree => 'Colis remis',
      null => '',
    };
    return CarteListe(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const AvatarIcone(icone: Icons.two_wheeler),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c.chauffeurNom} — votre livreur',
                    style: AppTextStyles.bodyBold()),
                const SizedBox(height: 2),
                Text(
                  [c.vehiculeLibelle, c.vehiculeImmatriculation, etat]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ),
          BoutonTelephone(telephone: c.chauffeurTelephone),
        ],
      ),
    );
  }
}

class _Etape {
  final String titre;
  final String detail;
  final bool faite;
  final bool active;
  const _Etape(this.titre, this.detail,
      {this.faite = false, this.active = false});
}

class _FriseVerticale extends StatelessWidget {
  final CommandeResponse commande;
  const _FriseVerticale({required this.commande});

  List<_Etape> _etapes() {
    final c = commande;
    final livree = c.statut == StatutCommande.livree;
    final assigne = c.dateAssignation != null || c.chauffeurNom != null;
    final recupere = c.dateRetrait != null || livree;
    String h(DateTime? d) => d == null ? '' : ' · ${heureMinute(d)}';
    return [
      _Etape('Commande confirmée', 'Fonds réservés${h(c.dateCommande)}',
          faite: true),
      _Etape(
        'Livreur assigné',
        assigne
            ? '${c.chauffeurNom ?? 'Le livreur'} a accepté la livraison${h(c.dateAssignation)}'
            : 'Recherche d\'un livreur…',
        faite: assigne,
        active: !assigne,
      ),
      _Etape(
        'Colis récupéré chez le vendeur',
        recupere
            ? 'Scanné chez ${c.boutiqueNom}${h(c.dateRetrait)}'
            : 'Le livreur se rend chez ${c.boutiqueNom}',
        faite: recupere,
        active: assigne && !recupere,
      ),
      _Etape(
        'Livreur en route',
        'Scannez son code pour confirmer la réception',
        faite: livree,
        active: recupere && !livree,
      ),
      _Etape(
        'Livraison confirmée',
        livree ? 'Reçu${h(c.dateLivraison)}' : 'En attente de votre scan',
        faite: livree,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final etapes = _etapes();
    return Column(
      children: List.generate(etapes.length, (i) {
        final e = etapes[i];
        final suivanteFaite = i < etapes.length - 1 && etapes[i + 1].faite;
        final grise = !e.faite && !e.active;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            e.faite ? AppColors.accentBleu : Colors.transparent,
                        border: e.active
                            ? Border.all(color: AppColors.accentBleu, width: 2)
                            : null,
                      ),
                      child: e.faite
                          ? const Icon(Icons.check_rounded,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    if (i < etapes.length - 1)
                      Expanded(
                        child: Container(
                            width: 2,
                            color: suivanteFaite ||
                                    (e.faite && etapes[i + 1].active)
                                ? AppColors.accentBleu
                                : Colors.transparent),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.titre,
                        style: AppTextStyles.bodyBold(
                            color: grise
                                ? AppColors.textSecondary
                                : AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(e.detail,
                          style: AppTextStyles.caption().copyWith(
                              fontWeight: grise ? null : FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Frise à 2 étapes pour une commande en retrait sur place (pas de livreur) :
/// confirmée -> récupérée par le client chez le vendeur.
class _FriseRetraitClient extends StatelessWidget {
  final CommandeResponse commande;
  const _FriseRetraitClient({required this.commande});

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final livree = c.statut == StatutCommande.livree;
    String h(DateTime? d) => d == null ? '' : ' · ${heureMinute(d)}';
    final etapes = [
      _Etape('Commande confirmée', 'Fonds réservés${h(c.dateCommande)}',
          faite: true),
      _Etape(
        'Prête pour le retrait',
        livree
            ? 'Récupérée chez ${c.boutiqueNom}${h(c.dateLivraison)}'
            : 'Rendez-vous chez ${c.boutiqueNom}${c.boutiqueQuartier != null ? ' (${c.boutiqueQuartier})' : ''} avec votre code',
        faite: livree,
        active: !livree,
      ),
    ];
    return Column(
      children: List.generate(etapes.length, (i) {
        final e = etapes[i];
        final grise = !e.faite && !e.active;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            e.faite ? AppColors.accentBleu : Colors.transparent,
                        border: e.active
                            ? Border.all(color: AppColors.accentBleu, width: 2)
                            : null,
                      ),
                      child: e.faite
                          ? const Icon(Icons.check_rounded,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    if (i < etapes.length - 1)
                      Expanded(
                          child: Container(
                              width: 2,
                              color: e.faite
                                  ? AppColors.accentBleu
                                  : Colors.transparent)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.titre,
                        style: AppTextStyles.bodyBold(
                            color: grise
                                ? AppColors.textSecondary
                                : AppColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(e.detail,
                          style: AppTextStyles.caption().copyWith(
                              fontWeight: grise ? null : FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Carte du livreur en direct (sa dernière position partagée), de la
/// boutique et du point de livraison.
class _CarteSuiviDirect extends StatelessWidget {
  final CommandeResponse commande;
  const _CarteSuiviDirect({required this.commande});

  @override
  Widget build(BuildContext context) {
    final c = commande;
    final pos = c.chauffeurPosition!;
    final livreur = LatLng(pos.latitude, pos.longitude);
    final boutique = coordQuartier(c.boutiqueQuartier);
    final livraison =
        c.livraisonLatitude != null && c.livraisonLongitude != null
            ? LatLng(c.livraisonLatitude!, c.livraisonLongitude!)
            : coordQuartier(quartierDansAdresse(c.adresseLivraison));
    final colisRecupere = c.dateRetrait != null;
    final cible = colisRecupere ? livraison : boutique;
    final km = cible == null ? null : distanceKmGps(livreur, cible);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 190,
            child: CarteMaliMall(
              afficherMaPosition: false,
              reperes: [
                RepereCarte(
                  id: 'livreur',
                  position: livreur,
                  teinte: BitmapDescriptor.hueAzure,
                  titre: c.chauffeurNom ?? 'Livreur',
                  detail: 'Mis à jour à ${heureMinute(pos.maj)}',
                ),
                if (boutique != null && !colisRecupere)
                  RepereCarte(
                      id: 'boutique',
                      position: boutique,
                      teinte: BitmapDescriptor.hueOrange,
                      titre: c.boutiqueNom),
                if (livraison != null)
                  RepereCarte(
                      id: 'livraison',
                      position: livraison,
                      teinte: BitmapDescriptor.hueRed,
                      titre: 'Livraison'),
              ],
              trajet: cible == null ? null : (livreur, cible),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          [
            'Position du livreur à ${heureMinute(pos.maj)}',
            if (km != null)
              colisRecupere
                  ? 'à ~$km km de chez vous'
                  : 'à ~$km km de la boutique',
          ].join(' · '),
          style: AppTextStyles.captionSmall(),
        ),
      ],
    );
  }
}
