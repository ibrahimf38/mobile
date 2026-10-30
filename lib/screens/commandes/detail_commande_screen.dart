import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../core/services/commande_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/code_input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';

/// Rôle sous lequel le viewer consulte CETTE commande précise — fourni
/// explicitement par l'écran appelant (l'onglet Achats/Ventes/Livraisons
/// d'où on vient, ou le contexte de la confirmation de commande), jamais
/// deviné depuis la présence/absence de codeRetrait/codeLivraison dans la
/// réponse (qui ne fait QUE refléter ce que le backend a déjà décidé de
/// montrer à ce viewer — voir CommandeMapper côté backend).
enum ViewerRole { acheteur, vendeur, chauffeur }

/// Écran de détail adaptatif — un seul écran, trois rendus internes séparés
/// selon [ViewerRole] (voir le plan approuvé, section "Écran de détail de
/// commande adaptatif").
class DetailCommandeScreen extends StatefulWidget {
  final int commandeId;
  final ViewerRole viewerRole;

  const DetailCommandeScreen(
      {super.key,
      required this.commandeId,
      this.viewerRole = ViewerRole.acheteur});

  @override
  State<DetailCommandeScreen> createState() => _DetailCommandeScreenState();
}

class _DetailCommandeScreenState extends State<DetailCommandeScreen> {
  CommandeResponse? _commande;
  String? _erreur;
  bool _chargement = true;
  bool _actionEnCours = false;
  String? _erreurAction;
  final _codeRetraitCtrl = TextEditingController();
  final _codeLivraisonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _codeRetraitCtrl.dispose();
    _codeLivraisonCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final commande =
          await context.read<CommandeService>().obtenir(widget.commandeId);
      if (!mounted) return;
      setState(() => _commande = commande);
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

  Future<void> _confirmerRetrait() async {
    if (_codeRetraitCtrl.text.length != 6) {
      setState(
          () => _erreurAction = 'Le code doit contenir exactement 6 chiffres.');
      return;
    }
    setState(() {
      _actionEnCours = true;
      _erreurAction = null;
    });
    try {
      final commande = await context
          .read<CommandeService>()
          .scannerRetrait(widget.commandeId, _codeRetraitCtrl.text);
      if (!mounted) return;
      setState(() => _commande = commande);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreurAction = e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      setState(() => _erreurAction = e.message);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  /// L'acheteur saisit (ou scanne) le code présenté par le livreur.
  Future<void> _confirmerReception() async {
    final code = _codeLivraisonCtrl.text;
    if (code.length != 6) {
      setState(
          () => _erreurAction = 'Le code doit contenir exactement 6 chiffres.');
      return;
    }
    setState(() {
      _actionEnCours = true;
      _erreurAction = null;
    });
    try {
      final commande = await context
          .read<CommandeService>()
          .confirmerLivraison(widget.commandeId, code);
      if (!mounted) return;
      setState(() => _commande = commande);
      AppFeedback.success(context, 'Réception confirmée — merci !');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreurAction = e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      setState(() => _erreurAction = e.message);
    } finally {
      if (mounted) setState(() => _actionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Détail de la commande'),
      body: _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : RefreshIndicator(onRefresh: _charger, child: _corps()),
    );
  }

  Widget _corps() {
    final commande = _commande!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surfaceL1,
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(commande.boutiqueNom,
                          style: AppTextStyles.titleS())),
                  StatusBadge(statut: commande.statutAffiche),
                ],
              ),
              const SizedBox(height: 8),
              Text('Commande n°${commande.id}', style: AppTextStyles.caption()),
              const Divider(height: 24),
              ...commande.lignes.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${l.quantite} × ${l.produitNom}',
                              style: AppTextStyles.bodyDefault()),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _MontantEquivalent(montantMmc: l.sousTotal),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Produits', style: AppTextStyles.caption()),
                  Expanded(
                    child: _MontantEquivalent(
                      montantMmc: commande.montantTotalMmc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Livraison', style: AppTextStyles.caption()),
                  Expanded(
                    child: _MontantEquivalent(
                      montantMmc: commande.fraisLivraisonMmc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.bodyBold()),
                  Expanded(
                    child: _MontantEquivalent(
                      montantMmc: commande.montantTotalAvecLivraison,
                      couleur: AppColors.accentBleu,
                      fort: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SuiviLivraison(commande: commande),
        const SizedBox(height: 16),
        switch (widget.viewerRole) {
          ViewerRole.acheteur => _vueAcheteur(commande),
          ViewerRole.vendeur => _vueVendeur(commande),
          ViewerRole.chauffeur => _vueChauffeur(commande),
        },
      ],
    );
  }

  Widget _vueAcheteur(CommandeResponse commande) {
    if (commande.statut == StatutCommande.livree) {
      return _carteInfo(
          icone: Icons.check_circle,
          texte: 'Livré — merci pour votre commande.');
    }
    final colisEnChemin =
        commande.statutLivraison == StatutLivraison.recuperee ||
            commande.statutLivraison == StatutLivraison.enRoute;
    if (colisEnChemin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceL1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accentBleu, width: 1.5),
        ),
        child: Column(
          children: [
            Text('Confirmer la réception', style: AppTextStyles.titleS()),
            const SizedBox(height: 6),
            Text(
              'Votre livreur arrive. À la remise du colis, saisissez le code à 6 chiffres qu\'il vous présente.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(),
            ),
            const SizedBox(height: 14),
            CodeInputField(
                controller: _codeLivraisonCtrl, erreur: _erreurAction),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Confirmer la réception',
              enChargement: _actionEnCours,
              onPressed: _confirmerReception,
            ),
          ],
        ),
      );
    }
    return _carteInfo(
      icone: Icons.local_shipping_outlined,
      texte: commande.statutLivraison == null
          ? 'En attente qu\'un livreur prenne en charge votre commande.'
          : 'Votre livreur est en route vers le vendeur pour récupérer le colis.',
    );
  }

  Widget _vueVendeur(CommandeResponse commande) {
    if (commande.statutLivraison != null &&
        commande.statutLivraison != StatutLivraison.assignee) {
      return _carteInfo(
          icone: Icons.inventory_2_outlined,
          texte: 'Ce colis a déjà été récupéré par le livreur.');
    }
    if (commande.codeRetrait == null) {
      return _carteInfo(
        icone: Icons.hourglass_empty,
        texte: 'En attente qu\'un livreur prenne en charge cette commande.',
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceL1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBleu, width: 1.5),
      ),
      child: Column(
        children: [
          Text('Code de retrait', style: AppTextStyles.titleS()),
          const SizedBox(height: 6),
          Text(
            commande.codeRetrait!.split('').join(' '),
            style: AppTextStyles.headingXL(color: AppColors.accentBleu),
          ),
          const SizedBox(height: 10),
          Text(
            'Donnez ce code au livreur lorsqu\'il vient récupérer le colis.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(),
          ),
        ],
      ),
    );
  }

  Widget _vueChauffeur(CommandeResponse commande) {
    if (commande.statutLivraison == StatutLivraison.assignee) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surfaceL1,
            borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text('Saisissez le code donné par le vendeur',
                style: AppTextStyles.titleS(), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            CodeInputField(controller: _codeRetraitCtrl, erreur: _erreurAction),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Confirmer le retrait',
              enChargement: _actionEnCours,
              onPressed: _confirmerRetrait,
            ),
          ],
        ),
      );
    }
    if (commande.statut == StatutCommande.livree) {
      return _carteInfo(
          icone: Icons.check_circle, texte: 'Livraison terminée.');
    }
    // RECUPEREE / EN_ROUTE : le livreur présente le code de livraison à
    // l'acheteur, qui le saisit ou le scanne pour confirmer la réception.
    final code = commande.codeLivraison;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceL1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentBleu, width: 1.5),
      ),
      child: Column(
        children: [
          Text('Code de livraison', style: AppTextStyles.titleS()),
          const SizedBox(height: 6),
          Text(
            code == null ? '— — —' : code.split('').join(' '),
            style: AppTextStyles.headingXL(color: AppColors.accentBleu),
          ),
          const SizedBox(height: 10),
          Text(
            "Présentez ce code à l'acheteur à la remise du colis : il le saisit pour confirmer la réception.",
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(),
          ),
        ],
      ),
    );
  }

  Widget _carteInfo({required IconData icone, required String texte}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icone, color: AppColors.accentBleu),
          const SizedBox(width: 12),
          Expanded(child: Text(texte, style: AppTextStyles.bodyDefault())),
        ],
      ),
    );
  }
}

class _MontantEquivalent extends StatelessWidget {
  final int montantMmc;
  final Color? couleur;
  final bool fort;

  const _MontantEquivalent({
    required this.montantMmc,
    this.couleur,
    this.fort = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${formatMmc(montantMmc)} MMC',
            textAlign: TextAlign.end,
            style: fort
                ? AppTextStyles.bodyBold(
                    color: couleur ?? AppColors.textPrimary)
                : AppTextStyles.bodyMedium(color: couleur),
          ),
          Text(
            '≈ ${formatMmc(equivalentFcfa(montantMmc))} FCFA',
            textAlign: TextAlign.end,
            style: AppTextStyles.caption(color: AppColors.textSecondary),
          ),
        ],
      );
}

class _SuiviLivraison extends StatelessWidget {
  final CommandeResponse commande;
  const _SuiviLivraison({required this.commande});

  static const _etapes = ['Confirmée', 'Récupérée', 'En route', 'Livrée'];

  int get _etapeCourante {
    if (commande.statut == StatutCommande.annulee) return -1;
    switch (commande.statutLivraison) {
      case null:
        return 0;
      case StatutLivraison.assignee:
        return 0;
      case StatutLivraison.recuperee:
        return 1;
      case StatutLivraison.enRoute:
        return 2;
      case StatutLivraison.livree:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_etapeCourante < 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: List.generate(_etapes.length, (i) {
          final fait = i <= _etapeCourante;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                            height: 2,
                            color: i <= _etapeCourante
                                ? AppColors.accentBleu
                                : AppColors.divider),
                      ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: fait ? AppColors.accentBleu : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: fait
                          ? const Icon(Icons.check,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                    if (i < _etapes.length - 1)
                      Expanded(
                        child: Container(
                            height: 2,
                            color: i < _etapeCourante
                                ? AppColors.accentBleu
                                : AppColors.divider),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _etapes[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionSmall(
                      color: fait
                          ? AppColors.accentBleu
                          : AppColors.textSecondary),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
