import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/services/catalogue_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/state_views.dart';
import 'fiche_produit_screen.dart';

/// Fiche boutique publique — inspirée de shop_catalog_screen.dart (vraie
/// app MaliMall Flutter) : bandeau boutique (logo, nom, catégorie, badge
/// "Certifiée") puis la grille de tous ses produits publiés. Accessible en
/// tapant sur le nom de la boutique depuis la fiche produit.
class DetailBoutiqueScreen extends StatefulWidget {
  final int boutiqueId;
  const DetailBoutiqueScreen({super.key, required this.boutiqueId});

  @override
  State<DetailBoutiqueScreen> createState() => _DetailBoutiqueScreenState();
}

class _DetailBoutiqueScreenState extends State<DetailBoutiqueScreen> {
  BoutiqueResponse? _boutique;
  List<ProduitResponse>? _produits;
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
      final service = context.read<CatalogueService>();
      final boutique = await service.obtenirBoutique(widget.boutiqueId);
      final produits = await service.produitsDeLaBoutique(widget.boutiqueId);
      if (!mounted) return;
      setState(() {
        _boutique = boutique;
        _produits = produits.where((p) => p.actif).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(titre: _boutique?.nom ?? 'Boutique'),
      body: _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : RefreshIndicator(onRefresh: _charger, child: _corps()),
    );
  }

  Widget _corps() {
    final boutique = _boutique!;
    final produits = _produits ?? [];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          sliver: SliverToBoxAdapter(child: _enTeteBoutique(boutique)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          sliver: produits.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyView(
                        message: "Cette boutique n'a pas encore de produit.",
                        icone: Icons.storefront_outlined),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.64,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => ProductCard(
                      produit: produits[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                FicheProduitScreen(produitId: produits[i].id)),
                      ),
                    ),
                    childCount: produits.length,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _enTeteBoutique(BoutiqueResponse boutique) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: boutique.imageUrl != null && boutique.imageUrl!.isNotEmpty
                  ? ReseauImage(imageUrl: boutique.imageUrl, tailleIcone: 22)
                  : Container(
                      color: AppColors.accentBleu.withValues(alpha: 0.12),
                      alignment: Alignment.center,
                      child: Text(
                        boutique.nom.isNotEmpty
                            ? boutique.nom[0].toUpperCase()
                            : '?',
                        style:
                            AppTextStyles.headingM(color: AppColors.accentBleu),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(boutique.nom,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headingM()),
                    ),
                    if (boutique.certifiee) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(9, 5, 11, 6),
                        decoration: BoxDecoration(
                            color: AppColors.accentBleu,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('Certifiée',
                                style: AppTextStyles.captionSmall(
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                if (boutique.categorie != null &&
                    boutique.categorie!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(boutique.categorie!, style: AppTextStyles.caption()),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${(_produits ?? []).length} produit${(_produits ?? []).length > 1 ? 's' : ''}',
                      style: AppTextStyles.caption().copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
