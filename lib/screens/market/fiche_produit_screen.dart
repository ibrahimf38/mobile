import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/services/catalogue_service.dart';
import '../../state/panier_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/state_views.dart';
import 'detail_boutique_screen.dart';
import 'panier_screen.dart';

class FicheProduitScreen extends StatefulWidget {
  final int produitId;
  const FicheProduitScreen({super.key, required this.produitId});

  @override
  State<FicheProduitScreen> createState() => _FicheProduitScreenState();
}

class _FicheProduitScreenState extends State<FicheProduitScreen> {
  ProduitResponse? _produit;
  BoutiqueResponse? _boutique;
  List<ProduitResponse> _similaires = [];
  String? _erreur;
  bool _chargement = true;
  int _quantite = 1;
  bool _ajoutEnCours = false;

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
      final service = context.read<CatalogueService>();
      final produit = await service.obtenirProduit(widget.produitId);
      final boutique = await service.obtenirBoutique(produit.boutiqueId);
      // Produits similaires : même catégorie, jamais le produit actuel — pour
      // donner envie de continuer à explorer sans revenir en arrière (même
      // logique que la vraie app MaliMall Flutter, product_detail_screen.dart).
      var similaires = <ProduitResponse>[];
      if (produit.categorie != null && produit.categorie!.isNotEmpty) {
        final tous = await service.listerProduits();
        similaires = tous
            .where((p) =>
                p.id != produit.id &&
                p.categorie == produit.categorie &&
                p.actif)
            .take(10)
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _produit = produit;
        _boutique = boutique;
        _similaires = similaires;
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

  Future<void> _ajouterAuPanier() async {
    final produit = _produit;
    if (produit == null) return;
    setState(() => _ajoutEnCours = true);
    final panier = context.read<PanierProvider>();
    final ok =
        await panier.ajouterLigne(produitId: produit.id, quantite: _quantite);
    if (!mounted) return;
    setState(() => _ajoutEnCours = false);
    if (ok) {
      // "Commander" (maquette 09) : le produit part au panier, où l'acheteur
      // valide sa commande (une commande par boutique).
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PanierScreen()));
    } else {
      AppFeedback.error(
        context,
        panier.erreur ?? "Impossible d'ajouter ce produit au panier.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _barreHaut(),
            Expanded(
              child: _chargement
                  ? const LoadingView()
                  : _erreur != null
                      ? ErrorView(message: _erreur!, onReessayer: _charger)
                      : _corps(),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          (_chargement || _erreur != null) ? null : _barreBasse(),
    );
  }

  Widget _barreHaut() {
    final nombreArticles = context.watch<PanierProvider>().nombreArticles;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BoutonRond(
              icone: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop()),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _BoutonRond(
                icone: Icons.shopping_cart_outlined,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PanierScreen())),
              ),
              if (nombreArticles > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$nombreArticles',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionSmall(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _corps() {
    final produit = _produit!;
    final boutique = _boutique;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ReseauImage(
                imageUrl: produit.imageUrl,
                icone: Icons.shopping_bag_outlined,
                tailleIcone: 54,
                couleurFond: const Color(0xFFE7DDFB),
                couleurIcone: AppColors.accentViolet,
              ),
            ),
          ),
          if (boutique != null) ...[
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          DetailBoutiqueScreen(boutiqueId: boutique.id)),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentBleu.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          boutique.nom.isNotEmpty
                              ? boutique.nom[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.bodyBold(
                                  color: AppColors.accentBleu)
                              .copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          boutique.nom,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyDefault(
                              color: AppColors.textSecondary),
                        ),
                      ),
                      if (boutique.certifiee) ...[
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.fromLTRB(9, 5, 11, 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentBleu,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Certifiée',
                                style: AppTextStyles.captionSmall(
                                        color: Colors.white)
                                    .copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.iconDisabled),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(produit.nom,
              style: AppTextStyles.headingXL()
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w600)),
          if (produit.quantiteVendue > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    size: 13, color: Color(0xFFE65100)),
                const SizedBox(width: 5),
                Text(
                  '${produit.quantiteVendue} vendu${produit.quantiteVendue > 1 ? 's' : ''}',
                  style:
                      AppTextStyles.bodyMedium(color: const Color(0xFFE65100))
                          .copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (produit.enPromotion)
                Text(
                  formatMmc(produit.prixMmc),
                  style:
                      AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                          .copyWith(decoration: TextDecoration.lineThrough),
                ),
              Text(
                '${formatMmc(produit.prixEffectifMmc)} MMC',
                style: AppTextStyles.headingXL(
                    color: produit.enPromotion
                        ? AppColors.danger
                        : AppColors.accentBleu),
              ),
              Text(
                  '≈ ${formatMmc(equivalentFcfa(produit.prixEffectifMmc))} FCFA',
                  style: AppTextStyles.bodyDefault(
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            produit.stock > 0
                ? '${produit.stock} en stock'
                : 'Rupture de stock',
            style: AppTextStyles.bodyDefault(
                    color: produit.stock > 0
                        ? AppColors.textSecondary
                        : AppColors.danger)
                .copyWith(fontSize: 11.5),
          ),
          if (produit.description != null &&
              produit.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              produit.description!,
              style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                  .copyWith(fontSize: 11.5, height: 1.6),
            ),
          ],
          if (_similaires.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text('Produits similaires', style: AppTextStyles.headingM()),
            const SizedBox(height: 12),
            SizedBox(
              // La carte réduit la hauteur de sa photo si le texte grossit
              // avec la taille de police du téléphone.
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _similaires.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => SizedBox(
                  width: 130,
                  child: ProductCard(
                    produit: _similaires[i],
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) =>
                              FicheProduitScreen(produitId: _similaires[i].id)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barreBasse() {
    final produit = _produit!;
    final stockEpuise = produit.stock <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceL1,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _stepper(produit),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total',
                      style: AppTextStyles.bodyDefault(
                              color: AppColors.textSecondary)
                          .copyWith(fontSize: 9)),
                  Text(
                    '${formatMmc(produit.prixEffectifMmc * _quantite)} MMC',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBoldL(color: AppColors.accentBleu),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: PrimaryButton(
                label: stockEpuise ? 'Épuisé' : 'Commander',
                enChargement: _ajoutEnCours,
                onPressed: stockEpuise ? null : _ajouterAuPanier,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(ProduitResponse produit) {
    Widget bouton(String signe, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 25,
            height: 27,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.surfaceL1,
                borderRadius: BorderRadius.circular(8)),
            child: Text(signe,
                style: AppTextStyles.bodyBoldL(
                    color: onTap == null
                        ? AppColors.iconDisabled
                        : AppColors.accentBleu)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surfaceL2, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          bouton('−', _quantite > 1 ? () => setState(() => _quantite--) : null),
          SizedBox(
            width: 24,
            child: Text('$_quantite',
                textAlign: TextAlign.center, style: AppTextStyles.bodyBold()),
          ),
          bouton(
              '+',
              _quantite < produit.stock
                  ? () => setState(() => _quantite++)
                  : null),
        ],
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  const _BoutonRond({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
            color: AppColors.surfaceL1, shape: BoxShape.circle),
        child: Icon(icone, size: 16, color: AppColors.accentBleu),
      ),
    );
  }
}
