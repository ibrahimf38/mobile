import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/models/publicite_models.dart';
import '../../core/services/catalogue_service.dart';
import '../../core/services/publicite_service.dart';
import '../../state/panier_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/en_tete_onglet.dart';
import '../../widgets/product_card.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/state_views.dart';
import 'detail_boutique_screen.dart';
import 'fiche_produit_screen.dart';
import 'panier_screen.dart';

/// Accueil Market — recherche + chips catégorie + grille produits (2 col.).
/// Le backend ne propose ni recherche ni filtre serveur (GET /api/produits
/// renvoie tout le catalogue) : recherche et filtre catégorie sont donc faits
/// côté client sur la liste complète, cohérent avec la taille du catalogue de
/// démonstration.
class AccueilMarketScreen extends StatefulWidget {
  const AccueilMarketScreen({super.key});

  @override
  State<AccueilMarketScreen> createState() => _AccueilMarketScreenState();
}

class _AccueilMarketScreenState extends State<AccueilMarketScreen> {
  List<ProduitResponse>? _produits;
  String? _erreur;
  bool _chargement = true;
  String _recherche = '';
  String _categorieActive = 'Tout';
  // null = tri par défaut (ordre du catalogue) ; sinon un tri explicite
  // choisi via l'icône à côté de la recherche — même esprit que le vrai
  // MaliMall (bouton de tri, pas un filtre de prix).
  String? _triActif;

  List<PubliciteResponse> _publicites = [];
  final _bannerePageController = PageController();
  int _bannierePage = 0;
  Timer? _bannereMinuteur;

  @override
  void initState() {
    super.initState();
    _charger();
    _chargerPublicites();
  }

  @override
  void dispose() {
    _bannereMinuteur?.cancel();
    _bannerePageController.dispose();
    super.dispose();
  }

  /// Bannières réelles (validées par un admin), jamais une promo inventée
  /// ("-20%" etc.) — voir PubliciteService côté backend. Best-effort : une
  /// erreur ici ne doit jamais bloquer l'affichage du catalogue.
  Future<void> _chargerPublicites() async {
    try {
      final publicites = await context.read<PubliciteService>().actives();
      if (!mounted) return;
      setState(() => _publicites = publicites);
      _demarrerDefilementAuto();
    } catch (_) {
      // silencieux : la bannière est un bonus, pas le contenu principal de l'écran
    }
  }

  /// Défilement automatique du carrousel de publicités, une bannière par
  /// seconde, en boucle infinie — s'arrête tout seul s'il n'y a qu'une seule
  /// bannière (rien à faire défiler).
  void _demarrerDefilementAuto() {
    _bannereMinuteur?.cancel();
    if (_publicites.length <= 1) return;
    _bannereMinuteur = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_bannerePageController.hasClients) return;
      final suivante = (_bannierePage + 1) % _publicites.length;
      _bannerePageController.animateToPage(
        suivante,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final produits = await context.read<CatalogueService>().listerProduits();
      if (!mounted) return;
      setState(() => _produits = produits);
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

  List<String> get _categories {
    final set = <String>{'Tout'};
    for (final p in _produits ?? const <ProduitResponse>[]) {
      if (p.categorie != null && p.categorie!.isNotEmpty) set.add(p.categorie!);
    }
    return set.toList();
  }

  List<ProduitResponse> get _produitsFiltres {
    var resultat = (_produits ?? const <ProduitResponse>[]).where((p) {
      final matchCategorie =
          _categorieActive == 'Tout' || p.categorie == _categorieActive;
      final matchRecherche = _recherche.isEmpty ||
          p.nom.toLowerCase().contains(_recherche.toLowerCase());
      final matchPromo = _triActif != 'promotion' || p.enPromotion;
      return p.actif && matchCategorie && matchRecherche && matchPromo;
    }).toList();

    switch (_triActif) {
      case 'plusVendus':
        resultat.sort((a, b) => b.quantiteVendue.compareTo(a.quantiteVendue));
      case 'nouveautes':
        // Un id BIGSERIAL plus grand = un produit créé plus récemment.
        resultat.sort((a, b) => b.id.compareTo(a.id));
      case 'promotion':
        resultat.sort(
            (a, b) => (b.promoPrixMmc ?? 0).compareTo(a.promoPrixMmc ?? 0));
    }
    return resultat;
  }

  @override
  Widget build(BuildContext context) {
    final nombreArticles =
        context.watch<PanierProvider>().panier?.lignes.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _enTete(nombreArticles),
          Expanded(child: _corps()),
        ],
      ),
    );
  }

  /// En-tête de la maquette 05 : titre "Market" + panier + pastille logo.
  Widget _enTete(int nombreArticles) {
    return EnTeteOnglet(
      titre: 'Market',
      tailleTitre: 20,
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _BoutonRond(
              icone: Icons.shopping_cart_outlined,
              tooltip: 'Panier',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PanierScreen()),
              ),
            ),
            if (nombreArticles > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
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
    );
  }

  Widget _corps() {
    return _chargement
        ? const LoadingView()
        : _erreur != null
            ? ErrorView(message: _erreur!, onReessayer: _charger)
            : RefreshIndicator(
                onRefresh: _charger,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _banniereCarrousel()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) =>
                                    setState(() => _recherche = v),
                                style: AppTextStyles.bodyDefault(),
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un produit',
                                  filled: true,
                                  fillColor: AppColors.surfaceL1,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 11),
                                  prefixIcon: const Icon(Icons.search,
                                      size: 16, color: AppColors.textSecondary),
                                  prefixIconConstraints:
                                      const BoxConstraints(minWidth: 40),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.divider),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _BoutonTri(
                              triActif: _triActif,
                              onSelectionner: (mode) =>
                                  setState(() => _triActif = mode),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 61,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final categorie = _categories[i];
                            return ChipFiltre(
                              label: categorie,
                              actif: categorie == _categorieActive,
                              onTap: () =>
                                  setState(() => _categorieActive = categorie),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                      sliver: _produitsFiltres.isEmpty
                          ? const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: EmptyView(
                                    message:
                                        'Aucun produit ne correspond à votre recherche.'),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 13,
                                crossAxisSpacing: 13,
                                childAspectRatio: 0.64,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final produit = _produitsFiltres[i];
                                  return ProductCard(
                                    produit: produit,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => FicheProduitScreen(
                                              produitId: produit.id)),
                                    ),
                                  );
                                },
                                childCount: _produitsFiltres.length,
                              ),
                            ),
                    ),
                  ],
                ),
              );
  }

  /// Carrousel des publicités actives — la photo de la boutique annonceuse
  /// recouvre toute la bannière (jamais un simple médaillon dans un coin),
  /// avec un dégradé sombre en bas pour que le titre reste lisible ; titre +
  /// nom de boutique en overlay, tag "Publicité" honnête (jamais présenté
  /// comme une offre officielle MaliMall). Défile automatiquement toutes les
  /// secondes (voir _demarrerDefilementAuto) et un tap ouvre la fiche de la
  /// boutique annonceuse. Une seule bannière n'affiche pas les points de
  /// pagination.
  Widget _banniereCarrousel() {
    // Pas encore de publicité active : bannière d'accueil (jamais une promo
    // inventée) — pas de boutique à ouvrir, donc non cliquable.
    final elements = _publicites.isEmpty
        ? [
            (
              titre: 'Bienvenue sur Market',
              sousTitre: 'Payez en MMC, livré près de chez vous',
              image: null as String?,
              boutiqueId: null as int?
            )
          ]
        : _publicites
            .map((p) => (
                  titre: p.titre,
                  sousTitre: p.boutiqueNom,
                  image: p.imageUrl,
                  boutiqueId: p.boutiqueId as int?
                ))
            .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          SizedBox(
            height: 88,
            child: PageView.builder(
              controller: _bannerePageController,
              onPageChanged: (i) => setState(() => _bannierePage = i),
              itemCount: elements.length,
              itemBuilder: (context, i) {
                final e = elements[i];
                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: e.boutiqueId == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => DetailBoutiqueScreen(
                                      boutiqueId: e.boutiqueId!)),
                            ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: AppColors.accentBleu,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // La photo recouvre TOUTE la zone (Positioned.fill), pas
                          // un médaillon dans un coin — c'est la publicité payée
                          // par le vendeur, elle doit être vue en entier.
                          if (e.image != null && e.image!.isNotEmpty)
                            Positioned.fill(
                              child: ReseauImage(
                                  imageUrl: e.image,
                                  icone: Icons.storefront_outlined,
                                  tailleIcone: 30),
                            )
                          else ...[
                            Positioned(
                              right: -16,
                              top: -28,
                              child: _Cercle(
                                  taille: 90,
                                  couleur:
                                      Colors.white.withValues(alpha: 0.16)),
                            ),
                            Positioned(
                              right: 66,
                              bottom: -12,
                              child: _Cercle(
                                  taille: 40,
                                  couleur: AppColors.brandOrangeRaw
                                      .withValues(alpha: 0.35)),
                            ),
                          ],
                          // Dégradé sombre en bas pour que le texte reste lisible
                          // par-dessus n'importe quelle photo.
                          if (e.image != null && e.image!.isNotEmpty)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.0),
                                      Colors.black.withValues(alpha: 0.55)
                                    ],
                                    stops: const [0.35, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_publicites.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text('PUBLICITÉ',
                                        style: AppTextStyles.eyebrow(
                                            color: Colors.white
                                                .withValues(alpha: 0.7))),
                                  ),
                                Text(
                                  e.titre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyBoldL(
                                          color: Colors.white)
                                      .copyWith(fontSize: 14.5),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  e.sousTitre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyDefault(
                                          color: Colors.white
                                              .withValues(alpha: 0.8))
                                      .copyWith(fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (elements.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(elements.length, (i) {
                final actif = i == _bannierePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: actif ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: actif ? AppColors.accentBleu : AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cercle extends StatelessWidget {
  final double taille;
  final Color couleur;
  const _Cercle({required this.taille, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
    );
  }
}

/// Bouton de tri à côté de la recherche — même esprit que le vrai MaliMall
/// (menu de tri, pas un filtre de prix) : "Recommandés" (ordre par défaut),
/// "Les plus vendus" (quantiteVendue, calculée serveur), "Nouveautés" et
/// "En promotion" (nos deux critères réels, à la place de "plus likés" :
/// aucun système de favoris n'existe dans ce lot).
class _BoutonTri extends StatelessWidget {
  final String? triActif;
  final ValueChanged<String?> onSelectionner;
  const _BoutonTri({required this.triActif, required this.onSelectionner});

  @override
  Widget build(BuildContext context) {
    final actif = triActif != null;
    return PopupMenuButton<String?>(
      onSelected: onSelectionner,
      tooltip: 'Trier',
      icon: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actif ? AppColors.accentBleu : AppColors.surfaceL1,
          shape: BoxShape.circle,
          border:
              Border.all(color: actif ? Colors.transparent : AppColors.divider),
        ),
        child: Icon(Icons.tune_rounded,
            size: 18, color: actif ? Colors.white : AppColors.textPrimary),
      ),
      itemBuilder: (context) => [
        _item(null, 'Recommandés', Icons.auto_awesome_rounded),
        _item('plusVendus', 'Les plus vendus',
            Icons.local_fire_department_rounded),
        _item('nouveautes', 'Nouveautés', Icons.fiber_new_rounded),
        _item('promotion', 'En promotion', Icons.local_offer_rounded),
      ],
    );
  }

  PopupMenuItem<String?> _item(String? valeur, String label, IconData icone) {
    final selectionne = triActif == valeur;
    return PopupMenuItem(
      value: valeur,
      child: Row(
        children: [
          Icon(icone,
              size: 18,
              color:
                  selectionne ? AppColors.accentBleu : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.bodyDefault(
                      color: selectionne ? AppColors.accentBleu : null)
                  .copyWith(
                      fontWeight:
                          selectionne ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}

/// Bouton rond 38 px (fond clair + bordure) — même style que le filtre.
class _BoutonRond extends StatelessWidget {
  final IconData icone;
  final String tooltip;
  final VoidCallback onTap;
  const _BoutonRond(
      {required this.icone, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surfaceL1,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icone, size: 18, color: AppColors.textPrimary),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}
