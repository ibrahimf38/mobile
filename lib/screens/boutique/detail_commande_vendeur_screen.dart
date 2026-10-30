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
import '../../widgets/carte_code_qr.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/state_views.dart';

/// Maquette 28 — côté vendeur : article, livreur assigné et QR du code de
/// retrait que le livreur scanne pour emporter le colis. Le backend ne
/// renvoie le code de retrait qu'au vendeur, et seulement avant le retrait.
class DetailCommandeVendeurScreen extends StatefulWidget {
  final int commandeId;
  const DetailCommandeVendeurScreen({super.key, required this.commandeId});

  @override
  State<DetailCommandeVendeurScreen> createState() => _DetailCommandeVendeurScreenState();
}

/// "Colis remis", "~4 min" (d'après sa position partagée) ou "En route".
String _etatLivreur(CommandeResponse c) {
  if (c.dateRetrait != null) return 'Colis remis';
  final pos = c.chauffeurPosition;
  final boutique = coordQuartier(c.boutiqueQuartier);
  if (pos == null || boutique == null) return 'En route';
  final km = distanceKmGps(LatLng(pos.latitude, pos.longitude), boutique);
  return km < 0.3 ? 'Arrivé' : '~${minutesEstimees(km)} min';
}

class _DetailCommandeVendeurScreenState extends State<DetailCommandeVendeurScreen> {
  CommandeResponse? _commande;
  String? _erreur;
  Timer? _timer;

  final _codeCtrl = TextEditingController();
  bool _validationEnCours = false;
  String? _erreurCode;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_commande?.dateRetrait == null) _charger(silencieux: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// Retrait sur place : le vendeur saisit le code à 6 chiffres que le client
  /// lui présente en venant chercher sa commande.
  Future<void> _validerRetraitClient() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _erreurCode = 'Le code fait 6 chiffres.');
      return;
    }
    setState(() {
      _validationEnCours = true;
      _erreurCode = null;
    });
    try {
      final c = await context.read<CommandeService>().confirmerRetraitClient(widget.commandeId, code);
      if (!mounted) return;
      setState(() => _commande = c);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreurCode = messageErreur(e));
    } finally {
      if (mounted) setState(() => _validationEnCours = false);
    }
  }

  Future<void> _charger({bool silencieux = false}) async {
    try {
      final c = await context.read<CommandeService>().obtenir(widget.commandeId);
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

  @override
  Widget build(BuildContext context) {
    final c = _commande;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(titre: 'Commande #${widget.commandeId}'),
      body: c == null
          ? (_erreur != null ? ErrorView(message: _erreur!, onReessayer: _charger) : const LoadingView())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  CarteListe(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        VignettePastel(graine: c.id + 1, icone: Icons.inventory_2_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.resumeArticles, style: AppTextStyles.bodyBold(), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${c.acheteurNom ?? 'Client'} · Qté ${c.lignes.fold<int>(0, (s, l) => s + l.quantite)}',
                                style: AppTextStyles.caption(),
                              ),
                            ],
                          ),
                        ),
                        Text('${formatMmc(c.montantTotalMmc)} MMC', style: AppTextStyles.bodyBold(color: AppColors.accentBleu)),
                      ],
                    ),
                  ),
                  if (c.retraitParClient) ...[
                    const SizedBox(height: 18),
                    const TitreSection('Retrait par le client'),
                    const SizedBox(height: 10),
                    _CarteRetraitClient(
                      commande: c,
                      codeCtrl: _codeCtrl,
                      enCours: _validationEnCours,
                      erreur: _erreurCode,
                      onValider: _validerRetraitClient,
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    const TitreSection('Livreur assigné'),
                    const SizedBox(height: 10),
                    CarteListe(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const AvatarIcone(icone: Icons.two_wheeler),
                          const SizedBox(width: 12),
                          Expanded(
                            child: c.chauffeurNom == null
                                ? Text("En attente d'un livreur…", style: AppTextStyles.bodyMedium(color: AppColors.textSecondary))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.chauffeurNom!, style: AppTextStyles.bodyBold()),
                                      Text(
                                        [c.vehiculeLibelle, c.vehiculeImmatriculation].whereType<String>().join(' · '),
                                        style: AppTextStyles.caption(),
                                      ),
                                    ],
                                  ),
                          ),
                          if (c.chauffeurNom != null)
                            PiluleInfo(_etatLivreur(c), couleur: AppColors.accentBleu),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const TitreSection('Remise du colis'),
                    const SizedBox(height: 8),
                    if (c.codeRetrait != null) ...[
                      Text(
                        'Quand le livreur se présente, montrez-lui ce code de retrait pour qu\'il puisse le scanner '
                        'et emporter le colis.',
                        style: AppTextStyles.caption().copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      CarteCodeQr(code: c.codeRetrait!, legende: 'Code de retrait — si le scan échoue'),
                    ] else
                      CarteListe(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.statutTermineFond),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.dateRetrait != null
                                    ? 'Colis remis au livreur à ${heureMinute(c.dateRetrait!)}.'
                                    : 'Le code de retrait n\'est plus nécessaire.',
                                style: AppTextStyles.bodyMedium(),
                              ),
                            ),
                          ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: c == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 14),
                child: Text(
                  c.retraitParClient
                      ? "Ne validez le retrait qu'une fois le client identifié et le colis remis en main propre."
                      : "Le code n'est utile qu'à la venue du livreur. Ne le partagez à personne d'autre.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionSmall().copyWith(height: 1.6),
                ),
              ),
            ),
    );
  }
}

/// Le client vient chercher lui-même sa commande (pas de livreur) : le
/// vendeur saisit le code à 6 chiffres qu'il présente pour confirmer la
/// remise — voir CommandeController#confirmerRetraitClient.
class _CarteRetraitClient extends StatelessWidget {
  final CommandeResponse commande;
  final TextEditingController codeCtrl;
  final bool enCours;
  final String? erreur;
  final VoidCallback onValider;

  const _CarteRetraitClient({
    required this.commande,
    required this.codeCtrl,
    required this.enCours,
    required this.erreur,
    required this.onValider,
  });

  @override
  Widget build(BuildContext context) {
    final c = commande;
    if (c.statut == StatutCommande.livree) {
      return CarteListe(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.statutTermineFond),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                c.dateLivraison != null
                    ? 'Commande remise au client à ${heureMinute(c.dateLivraison!)}.'
                    : 'Commande remise au client.',
                style: AppTextStyles.bodyMedium(),
              ),
            ),
          ],
        ),
      );
    }
    return CarteListe(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Le client viendra chercher sa commande sur place, sans livreur. Demandez-lui son "
            "code de retrait à 6 chiffres et saisissez-le ci-dessous pour confirmer la remise.",
            style: AppTextStyles.caption().copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingM().copyWith(letterSpacing: 4),
            decoration: const InputDecoration(counterText: '', hintText: '000000', isDense: true),
          ),
          if (erreur != null) ...[
            const SizedBox(height: 4),
            Text(erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: enCours ? null : onValider,
              child: enCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Valider le retrait'),
            ),
          ),
        ],
      ),
    );
  }
}
