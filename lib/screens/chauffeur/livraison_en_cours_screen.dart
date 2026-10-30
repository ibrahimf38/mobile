import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/localisation.dart';
import '../../core/models/commande_models.dart';
import '../../core/models/livreur_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/commande_service.dart';
import '../../core/services/livreur_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/bouton_rond.dart';
import '../../widgets/carte_code_qr.dart';
import '../../widgets/carte_malimall.dart';
import '../../widgets/ecran_scan_code.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import '../livraison/signaler_probleme_screen.dart';

/// Maquettes 31 et 33 — livraison en cours côté livreur, un seul écran qui
/// suit l'état de la commande : en route vers le vendeur (scan du code de
/// retrait, maquette 32), puis vers l'acheteur (affichage du code de
/// livraison, maquette 34), jusqu'à "Livraison terminée" (maquette 35).
class LivraisonEnCoursScreen extends StatefulWidget {
  final int commandeId;
  const LivraisonEnCoursScreen({super.key, required this.commandeId});

  @override
  State<LivraisonEnCoursScreen> createState() => _LivraisonEnCoursScreenState();
}

class _LivraisonEnCoursScreenState extends State<LivraisonEnCoursScreen> {
  CommandeResponse? _commande;
  String? _erreur;
  LatLng? _moi;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _charger();
    // L'acheteur et le vendeur suivent le livreur en direct.
    context.read<PartagePosition>().demarrer();
    _localiser();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _localiser());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _localiser() async {
    final p = await Localisation.positionActuelle();
    if (mounted && p != null) setState(() => _moi = p);
  }

  Future<void> _charger() async {
    try {
      final c =
          await context.read<CommandeService>().obtenir(widget.commandeId);
      if (!mounted) return;
      setState(() {
        _commande = c;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    }
  }

  Future<void> _scannerRetrait() async {
    final service = context.read<CommandeService>();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (scanContext) => EcranScanCode(
        titre: 'Retrait chez le vendeur',
        consigne: 'Scannez le code du vendeur',
        sousConsigne:
            "Demandez au vendeur d'afficher le code de retrait de la commande et centrez-le dans le cadre.",
        avertissement:
            'Vérifiez le colis avant de scanner : le scan confirme que vous l\'avez récupéré.',
        onCode: (code) async {
          await service.scannerRetrait(widget.commandeId, code);
          if (scanContext.mounted) Navigator.of(scanContext).pop();
        },
      ),
    ));
    await _charger();
  }

  Future<void> _signalerEnRoute() async {
    try {
      await context.read<CommandeService>().signalerEnRoute(widget.commandeId);
      await _charger();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, messageErreur(e));
    }
  }

  Future<void> _afficherCode() async {
    final c = _commande!;
    final livree = await Navigator.of(context).push<CommandeResponse>(
      MaterialPageRoute(builder: (_) => CodeLivraisonScreen(commande: c)),
    );
    if (!mounted) return;
    if (livree != null) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => LivraisonTermineeScreen(commande: livree)),
      );
    } else {
      await _charger();
    }
  }

  Future<void> _signaler() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              SignalerProblemeScreen(commandeId: widget.commandeId)),
    );
    await _charger();
  }

  @override
  Widget build(BuildContext context) {
    final c = _commande;
    if (c == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeaderBar(titre: 'Livraison'),
        body: _erreur != null
            ? ErrorView(message: _erreur!, onReessayer: _charger)
            : const LoadingView(),
      );
    }

    final versAcheteur = c.dateRetrait != null ||
        c.statutLivraison == StatutLivraison.recuperee ||
        c.statutLivraison == StatutLivraison.enRoute;
    final quartierAcheteur = quartierDansAdresse(c.adresseLivraison);
    // Position exacte enregistrée par le vendeur si disponible (bouton "Ma
    // boutique" — voir BoutiqueService.mettreAJourPosition), sinon simple
    // centre du quartier comme avant.
    final posVendeur = c.boutiquePosition != null
        ? LatLng(c.boutiquePosition!.latitude, c.boutiquePosition!.longitude)
        : coordQuartier(c.boutiqueQuartier) ?? centreBamako;
    // Point exact choisi par l'acheteur si disponible, sinon le centre de son quartier.
    final posAcheteur =
        c.livraisonLatitude != null && c.livraisonLongitude != null
            ? LatLng(c.livraisonLatitude!, c.livraisonLongitude!)
            : coordQuartier(quartierAcheteur) ?? centreBamako;
    final cible = versAcheteur ? posAcheteur : posVendeur;
    // Distance depuis ma position GPS réelle ; à défaut, entre boutique et acheteur.
    final moi = _moi;
    final km = moi != null
        ? distanceKmGps(moi, cible)
        : (versAcheteur ? distanceKmGps(posVendeur, posAcheteur) : null);

    final String titre;
    final String sousTitre;
    final String bouton;
    final String lien;
    final IconData icone;
    if (versAcheteur) {
      titre = c.acheteurNom ?? 'Acheteur';
      sousTitre = [quartierAcheteur ?? c.adresseLivraison, c.resumeArticles]
          .whereType<String>()
          .join(' · ');
      bouton = c.statutLivraison == StatutLivraison.recuperee
          ? 'Signaler mon départ vers l’acheteur'
          : 'Afficher mon code de livraison';
      lien = 'Acheteur injoignable ?';
      icone = Icons.person_outline;
    } else {
      titre = c.boutiqueNom;
      sousTitre = [
        c.boutiqueQuartier,
        c.resumeArticles,
        '${_poids(c.poidsTotalKg)} kg'
      ].whereType<String>().join(' · ');
      bouton = 'Je suis arrivé — scanner le code';
      lien = 'Vendeur injoignable ou boutique fermée ?';
      icone = Icons.storefront_outlined;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CarteMaliMall(
              marges: const EdgeInsets.only(top: 110, bottom: 200),
              reperes: [
                RepereCarte(
                  id: 'vendeur',
                  position: posVendeur,
                  teinte: BitmapDescriptor.hueOrange,
                  titre: c.boutiqueNom,
                  detail: c.boutiqueQuartier,
                ),
                if (versAcheteur)
                  RepereCarte(
                    id: 'acheteur',
                    position: posAcheteur,
                    teinte: BitmapDescriptor.hueRed,
                    titre: c.acheteurNom ?? 'Acheteur',
                    detail: c.adresseLivraison,
                  ),
              ],
              trajet: moi != null
                  ? (moi, cible)
                  : (versAcheteur ? (posVendeur, posAcheteur) : null),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BoutonRond.retour(context),
                      const Spacer(),
                      PiluleCarte(
                        '${versAcheteur ? "Vers l'acheteur" : 'Vers le vendeur'}${km == null ? '' : ' · $km km'}',
                      ),
                    ],
                  ),
                  if (versAcheteur) ...[
                    const SizedBox(height: 14),
                    const PiluleCarte(
                      'Colis à bord',
                      fond: AppColors.statutTermineFond,
                      couleurTexte: Colors.white,
                      icone: Icons.inventory_2_outlined,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PanneauBasCarte(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AvatarIcone(icone: icone),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titre, style: AppTextStyles.bodyBold()),
                            const SizedBox(height: 2),
                            Text(sousTitre,
                                style: AppTextStyles.caption()
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (km != null) PiluleInfo('~${minutesEstimees(km)} min'),
                    ],
                  ),
                  if (versAcheteur && c.adresseLivraison != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(c.adresseLivraison!,
                                style: AppTextStyles.caption())),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  if (c.signalee)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Signalement en cours : notre équipe reprend la main sur cette livraison.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(color: AppColors.danger)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  PrimaryButton(
                    label: bouton,
                    onPressed: c.signalee
                        ? null
                        : (versAcheteur
                            ? c.statutLivraison == StatutLivraison.recuperee
                                ? _signalerEnRoute
                                : _afficherCode
                            : _scannerRetrait),
                  ),
                  if (!c.signalee) LienDiscret(lien, onTap: _signaler),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _poids(double kg) =>
    kg == kg.roundToDouble() ? kg.toInt().toString() : kg.toStringAsFixed(1);

/// Maquette 34 — le livreur montre son code de livraison ; l'écran vérifie
/// toutes les 5 s si l'acheteur l'a scanné, puis renvoie la commande livrée.
class CodeLivraisonScreen extends StatefulWidget {
  final CommandeResponse commande;
  const CodeLivraisonScreen({super.key, required this.commande});

  @override
  State<CodeLivraisonScreen> createState() => _CodeLivraisonScreenState();
}

class _CodeLivraisonScreenState extends State<CodeLivraisonScreen> {
  Timer? _timer;
  bool _verification = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _verifier(silencieux: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifier({bool silencieux = false}) async {
    if (_verification) return;
    _verification = true;
    try {
      final c =
          await context.read<CommandeService>().obtenir(widget.commande.id);
      if (!mounted) return;
      if (c.statut == StatutCommande.livree) {
        _timer?.cancel();
        Navigator.of(context).pop(c);
      } else if (!silencieux) {
        AppFeedback.warning(
          context,
          "L'acheteur n'a pas encore scanné le code de réception.",
        );
      }
    } catch (e) {
      if (mounted && !silencieux) {
        AppFeedback.error(context, messageErreur(e));
      }
    } finally {
      _verification = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final code = c.codeLivraison;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Remise du colis'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
        children: [
          Text.rich(
            TextSpan(
              text: 'Montrez ce code à ',
              children: [
                TextSpan(
                    text: c.acheteurNom ?? "l'acheteur",
                    style: AppTextStyles.bodyBold()),
                const TextSpan(
                    text:
                        " pour qu'il le scanne et confirme la réception du colis."),
              ],
            ),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                .copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          if (code != null)
            CarteCodeQr(
                code: code,
                legende:
                    'Code de livraison — ce code est nouveau, différent du retrait')
          else
            const ErrorView(
                message: 'Code de livraison indisponible pour le moment.'),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: AppColors.accentOrange, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text("En attente du scan de l'acheteur…",
                  style: AppTextStyles.caption(color: AppColors.accentOrange)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
          child: PrimaryButton(
              label: "Livraison confirmée par l'acheteur",
              onPressed: () => _verifier()),
        ),
      ),
    );
  }
}

/// Maquette 35 — frais de livraison crédités et chiffres clés du livreur.
class LivraisonTermineeScreen extends StatefulWidget {
  final CommandeResponse commande;
  const LivraisonTermineeScreen({super.key, required this.commande});

  @override
  State<LivraisonTermineeScreen> createState() =>
      _LivraisonTermineeScreenState();
}

class _LivraisonTermineeScreenState extends State<LivraisonTermineeScreen> {
  EspaceLivreurResponse? _resume;

  @override
  void initState() {
    super.initState();
    context.read<LivreurService>().resume().then((r) {
      if (mounted) setState(() => _resume = r);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.commande;
    final r = _resume;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 16),
          child: Column(
            children: [
              const PastilleSucces(),
              const SizedBox(height: 18),
              Text('Livraison terminée !', style: AppTextStyles.headingL()),
              const SizedBox(height: 6),
              Text(
                '${c.resumeArticles} · remis à ${c.acheteurNom ?? "l'acheteur"}',
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.bodyDefault(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                    color: AppColors.accentBleu,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Text(
                        '+${formatMmc(netApresCommission(c.fraisLivraisonMmc))} MMC',
                        style:
                            AppTextStyles.displayMontant(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      'Frais de livraison (après commission de 8 %) crédités sur votre portefeuille',
                      style: AppTextStyles.caption(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (r != null)
                Row(
                  children: [
                    TuileChiffre(
                        valeur: '${r.coursesEtLivraisonsTerminees}',
                        libelle: 'Courses'),
                    const SizedBox(width: 10),
                    TuileChiffre(
                        valeur: r.noteMoyenne.toStringAsFixed(1),
                        libelle: 'Note moy.'),
                    const SizedBox(width: 10),
                    TuileChiffre(
                        valeur: formatMmc(r.gainsMmc), libelle: 'MMC gagnés'),
                  ],
                ),
              const Spacer(),
              PrimaryButton(
                  label: "Retour à l'espace livreur",
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }
}
