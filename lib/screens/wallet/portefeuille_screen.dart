import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/portefeuille_models.dart';
import '../../core/services/portefeuille_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/en_tete_onglet.dart';
import '../../widgets/state_views.dart';
import 'envoyer_screen.dart';
import 'recharge_screen.dart';
import 'retrait_screen.dart';

class PortefeuilleScreen extends StatefulWidget {
  const PortefeuilleScreen({super.key});

  @override
  State<PortefeuilleScreen> createState() => _PortefeuilleScreenState();
}

class _PortefeuilleScreenState extends State<PortefeuilleScreen> {
  PortefeuilleResponse? _portefeuille;
  List<EcritureResponse>? _historique;
  String? _erreur;
  bool _chargement = true;
  bool _soldeVisible = true;

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
      final service = context.read<PortefeuilleService>();
      final solde = await service.solde();
      final historique = await service.historique();
      if (!mounted) return;
      setState(() {
        _portefeuille = solde;
        _historique = historique..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
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

  Future<void> _ouvrir(Widget ecran) async {
    final succes = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ecran));
    if (succes == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const EnTeteOnglet(titre: 'Mon portefeuille'),
          Expanded(child: _corps()),
        ],
      ),
    );
  }

  Widget _corps() {
    return _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    children: [
                      _carteSolde(_portefeuille!),
                      const SizedBox(height: 16),
                      _boutonsAction(),
                      const SizedBox(height: 18),
                      Text('Historique', style: AppTextStyles.bodyBold()),
                      const SizedBox(height: 10),
                      if ((_historique ?? []).isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: EmptyView(message: 'Aucune opération pour le moment.', icone: Icons.receipt_long_outlined),
                        )
                      else
                        ..._historique!.map((e) => _LigneHistorique(ecriture: e)),
                    ],
                  ),
                );
  }

  Widget _decorCircle(double taille, double opacite) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brandOrangeRaw.withValues(alpha: opacite)),
    );
  }

  Widget _carteSolde(PortefeuilleResponse portefeuille) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.accentBleu, borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(top: -52, right: -52, child: _decorCircle(120, 0.22)),
          Positioned(bottom: -52, right: 18, child: _decorCircle(64, 0.16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 22),
                  InkWell(
                    onTap: () => setState(() => _soldeVisible = !_soldeVisible),
                    borderRadius: BorderRadius.circular(20),
                    child: Icon(
                      _soldeVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.white.withValues(alpha: 0.75),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Solde disponible',
                  style: AppTextStyles.bodyDefault(color: Colors.white.withValues(alpha: 0.75)).copyWith(fontSize: 11.5)),
              const SizedBox(height: 4),
              Text(
                _soldeVisible ? '${formatMmc(portefeuille.soldeDisponible)} MMC' : '•••• MMC',
                style: AppTextStyles.displayMontant(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                _soldeVisible ? '≈ ${formatMmc(equivalentFcfa(portefeuille.soldeDisponible))} FCFA' : '≈ •••• FCFA',
                style: AppTextStyles.bodyDefault(color: Colors.white.withValues(alpha: 0.7)),
              ),
              if (portefeuille.soldeGeleMmc > 0) ...[
                const SizedBox(height: 8),
                Text(
                  _soldeVisible
                      ? '${formatMmc(portefeuille.soldeGeleMmc)} MMC gelés (commandes en cours)'
                      : '•••• MMC gelés',
                  style: AppTextStyles.captionSmall(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '•••• MALIMALL WALLET',
                style: AppTextStyles.bodyDefault(color: Colors.white.withValues(alpha: 0.35))
                    .copyWith(fontSize: 10, letterSpacing: 1.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boutonsAction() {
    return Row(
      children: [
        Expanded(
          child: _boutonAction(
            couleur: AppColors.walletDepot,
            icone: Icons.arrow_downward_rounded,
            label: 'Dépôt',
            onTap: () => _ouvrir(const RechargeScreen()),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _boutonAction(
            couleur: AppColors.walletRetrait,
            icone: Icons.arrow_upward_rounded,
            label: 'Retrait',
            onTap: () => _ouvrir(RetraitScreen(soldeDisponible: _portefeuille!.soldeDisponible)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _boutonAction(
            couleur: AppColors.walletEnvoyer,
            icone: Icons.send_outlined,
            label: 'Envoyer',
            onTap: () => _ouvrir(EnvoyerScreen(soldeDisponible: _portefeuille!.soldeDisponible)),
          ),
        ),
      ],
    );
  }

  Widget _boutonAction({
    required Color couleur,
    required IconData icone,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: couleur,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icone, color: Colors.white, size: 17),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(fontSize: 10.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneHistorique extends StatelessWidget {
  final EcritureResponse ecriture;
  const _LigneHistorique({required this.ecriture});

  String get _libelle {
    switch (ecriture.typeOperation) {
      case TypeOperation.recharge:
        return 'Recharge';
      case TypeOperation.retrait:
        return 'Retrait';
      case TypeOperation.achat:
        return 'Achat';
      case TypeOperation.vente:
        return 'Vente';
      case TypeOperation.fraisLivraison:
        return 'Frais de livraison';
      case TypeOperation.commission:
        return 'Commission plateforme';
      case TypeOperation.coursePaiement:
        return 'Course MotoTaxi';
      case TypeOperation.courseRevenu:
        return 'Revenu course';
      case TypeOperation.publicite:
        return 'Publicité';
      case TypeOperation.transfertEnvoye:
        return 'MMC envoyés';
      case TypeOperation.transfertRecu:
        return 'MMC reçus';
    }
  }

  IconData get _icone {
    switch (ecriture.typeOperation) {
      case TypeOperation.recharge:
        return Icons.arrow_downward_rounded;
      case TypeOperation.retrait:
        return Icons.arrow_upward_rounded;
      case TypeOperation.achat:
        return Icons.shopping_bag_outlined;
      case TypeOperation.vente:
        return Icons.sell_outlined;
      case TypeOperation.fraisLivraison:
        return Icons.local_shipping_outlined;
      case TypeOperation.commission:
        return Icons.percent_rounded;
      case TypeOperation.coursePaiement:
      case TypeOperation.courseRevenu:
        return Icons.two_wheeler;
      case TypeOperation.publicite:
        return Icons.campaign_outlined;
      case TypeOperation.transfertEnvoye:
      case TypeOperation.transfertRecu:
        return Icons.send_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final credit = estCredit(ecriture.typeOperation);
    // Maquette 08 : crédits en bleu, débits en violet.
    final couleur = credit ? AppColors.accentBleu : AppColors.accentViolet;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(ecriture.dateCreation.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: credit ? 0.12 : 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icone, size: 16, color: couleur),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_libelle, style: AppTextStyles.bodyMedium()),
                const SizedBox(height: 6),
                Text(date, style: AppTextStyles.caption().copyWith(fontSize: 10.5, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Text(
            '${credit ? '+' : '-'}${formatMmc(ecriture.montantMmc)} MMC',
            style: AppTextStyles.bodyBold(color: couleur).copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
