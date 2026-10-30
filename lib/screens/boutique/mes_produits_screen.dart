import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/services/catalogue_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/state_views.dart';
import 'ajouter_produit_screen.dart';

/// Maquette 20 — liste des produits du vendeur (prix · vendus · stock),
/// menu "⋮" par produit, bouton "+ Ajouter un produit".
class MesProduitsScreen extends StatefulWidget {
  final int boutiqueId;
  const MesProduitsScreen({super.key, required this.boutiqueId});

  @override
  State<MesProduitsScreen> createState() => _MesProduitsScreenState();
}

class _MesProduitsScreenState extends State<MesProduitsScreen> {
  List<ProduitResponse>? _produits;
  BoutiqueResponse? _boutique;
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
      final catalogue = context.read<CatalogueService>();
      final boutique = await catalogue.obtenirBoutique(widget.boutiqueId);
      final produits = await catalogue.produitsDeLaBoutique(widget.boutiqueId);
      if (!mounted) return;
      setState(() {
        _boutique = boutique;
        _produits = produits;
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

  Future<void> _changerPhoto(ProduitResponse produit) async {
    final fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    try {
      await context.read<CatalogueService>().televerserPhotoProduit(produit.id,
          octets: octets, nomFichier: fichier.name);
      if (!mounted) return;
      AppFeedback.success(context, 'Photo mise à jour.');
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    }
  }

  Future<void> _reapprovisionner(ProduitResponse produit) async {
    final controleur = TextEditingController();
    final quantite = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Réapprovisionner'),
        content: TextField(
          controller: controleur,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Quantité à ajouter'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(
                dialogContext, int.tryParse(controleur.text.trim())),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (quantite == null || quantite <= 0) return;
    if (!mounted) return;
    try {
      await context
          .read<CatalogueService>()
          .reapprovisionner(produit.id, quantite: quantite);
      if (!mounted) return;
      AppFeedback.success(
        context,
        '$quantite unité${quantite > 1 ? 's' : ''} ajoutée${quantite > 1 ? 's' : ''}.',
      );
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    }
  }

  Future<void> _basculerPromotion(ProduitResponse produit) async {
    final catalogue = context.read<CatalogueService>();
    if (produit.enPromotion) {
      try {
        await catalogue.retirerPromotion(produit.id);
        if (!mounted) return;
        AppFeedback.success(context, 'Promotion retirée.');
        await _charger();
      } on ApiException catch (e) {
        if (!mounted) return;
        AppFeedback.error(context, e.message);
      } on ReseauException catch (e) {
        if (!mounted) return;
        AppFeedback.error(context, e.message);
      }
      return;
    }

    final controleurPrix = TextEditingController();
    final controleurDuree = TextEditingController(text: '7');
    final resultat = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mettre en promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controleurPrix,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                  labelText:
                      'Nouveau prix en MMC (actuel : ${produit.prixMmc})'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controleurDuree,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Durée de la promotion (jours)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              final prix = int.tryParse(controleurPrix.text.trim());
              final duree = int.tryParse(controleurDuree.text.trim());
              if (prix != null && duree != null) {
                Navigator.pop(dialogContext, {'prix': prix, 'duree': duree});
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    final prixPromo = resultat?['prix'];
    final dureeJours = resultat?['duree'];
    if (prixPromo == null ||
        dureeJours == null ||
        prixPromo <= 0 ||
        prixPromo >= produit.prixMmc ||
        dureeJours <= 0) {
      if (resultat != null) {
        AppFeedback.warning(
          context,
          'Vérifiez que le prix est inférieur au prix normal et que la durée est supérieure à zéro.',
        );
      }
      return;
    }
    try {
      await catalogue.mettreEnPromotion(produit.id,
          prixMmc: prixPromo, dureeJours: dureeJours);
      if (!mounted) return;
      AppFeedback.success(
        context,
        'Promotion activée pour $dureeJours jour${dureeJours > 1 ? 's' : ''}.',
      );
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    }
  }

  Future<void> _supprimer(ProduitResponse produit) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text('« ${produit.nom} » sera retiré de votre boutique.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    if (!mounted) return;
    try {
      final resultat =
          await context.read<CatalogueService>().supprimerProduit(produit.id);
      if (!mounted) return;
      AppFeedback.success(
        context,
        resultat.vraimentSupprime
            ? 'Produit supprimé.'
            : 'Ce produit a déjà été commandé : il est retiré du catalogue, mais conservé dans l’historique des commandes.',
      );
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    }
  }

  Future<void> _ajouter() async {
    final categorie = _boutique?.categorie;
    if (categorie == null || categorie.isEmpty) {
      AppFeedback.warning(
        context,
        'Définissez d’abord la catégorie de votre boutique pour pouvoir ajouter un produit.',
      );
      return;
    }
    final cree = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AjouterProduitScreen(
          boutiqueId: widget.boutiqueId,
          categorieBoutique: categorie,
        ),
      ),
    );
    if (cree == true) _charger();
  }

  Future<void> _afficherDetails(ProduitResponse produit) {
    final prix =
        produit.enPromotion ? produit.prixEffectifMmc : produit.prixMmc;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceL1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              if (produit.imageUrl != null && produit.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: ReseauImage(
                        imageUrl: produit.imageUrl, tailleIcone: 38),
                  ),
                ),
              const SizedBox(height: 16),
              Text(produit.nom, style: AppTextStyles.headingM()),
              const SizedBox(height: 6),
              Text(
                '${formatMmc(prix)} MMC${produit.enPromotion ? ' · En promotion' : ''}',
                style: AppTextStyles.bodyBoldL(color: AppColors.accentBleu),
              ),
              Text(
                '≈ ${formatMmc(equivalentFcfa(prix))} FCFA',
                style: AppTextStyles.caption(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _DetailProduitVendeur(
                  libellet: 'Stock disponible',
                  valeur:
                      '${produit.stock} unité${produit.stock == 1 ? '' : 's'}'),
              _DetailProduitVendeur(
                  libellet: 'Quantité vendue',
                  valeur:
                      '${produit.quantiteVendue} unité${produit.quantiteVendue == 1 ? '' : 's'}'),
              _DetailProduitVendeur(
                  libellet: 'Catégorie',
                  valeur: produit.categorie?.isNotEmpty == true
                      ? produit.categorie!
                      : 'Non définie'),
              _DetailProduitVendeur(
                  libellet: 'Poids', valeur: '${produit.poidsKg} kg'),
              _DetailProduitVendeur(
                  libellet: 'Disponibilité',
                  valeur: produit.actif ? 'En ligne' : 'Hors ligne'),
              if (produit.description?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Text('Description', style: AppTextStyles.bodyBold()),
                const SizedBox(height: 5),
                Text(produit.description!, style: AppTextStyles.bodyDefault()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Mes produits'),
      body: _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : (_produits ?? []).isEmpty
                  ? const EmptyView(
                      message: 'Aucun produit pour le moment.',
                      icone: Icons.inventory_2_outlined)
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                        itemCount: _produits!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _LigneProduit(
                          produit: _produits![i],
                          onTap: () => _afficherDetails(_produits![i]),
                          onChangerPhoto: () => _changerPhoto(_produits![i]),
                          onReapprovisionner: () =>
                              _reapprovisionner(_produits![i]),
                          onBasculerPromotion: () =>
                              _basculerPromotion(_produits![i]),
                          onSupprimer: () => _supprimer(_produits![i]),
                        ),
                      ),
                    ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child:
              PrimaryButton(label: '+ Ajouter un produit', onPressed: _ajouter),
        ),
      ),
    );
  }
}

class _LigneProduit extends StatelessWidget {
  final ProduitResponse produit;
  final VoidCallback onTap;
  final VoidCallback onChangerPhoto;
  final VoidCallback onReapprovisionner;
  final VoidCallback onBasculerPromotion;
  final VoidCallback onSupprimer;
  const _LigneProduit({
    required this.produit,
    required this.onTap,
    required this.onChangerPhoto,
    required this.onReapprovisionner,
    required this.onBasculerPromotion,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final rupture = produit.stock <= 0;
    final details = [
      if (produit.enPromotion)
        '${formatMmc(produit.prixEffectifMmc)} MMC (promo)'
      else
        '${formatMmc(produit.prixMmc)} MMC',
      '${produit.quantiteVendue} vendu${produit.quantiteVendue > 1 ? 's' : ''}',
      if (!rupture) '${produit.stock} en stock',
    ].join(' · ');

    return CarteListe(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: produit.imageUrl != null && produit.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: ReseauImage(
                        imageUrl: produit.imageUrl, tailleIcone: 17),
                  )
                : VignettePastel(graine: produit.id),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(produit.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(details,
                        style: AppTextStyles.caption().copyWith(
                            fontSize: 10, fontWeight: FontWeight.w400)),
                    if (rupture)
                      const Pastille(
                          texte: 'Rupture de stock',
                          couleur: AppColors.accentOrange),
                    if (produit.enPromotion)
                      const Pastille(
                          texte: 'En promo', couleur: AppColors.danger),
                    if (!produit.actif)
                      const Pastille(
                          texte: 'Hors ligne',
                          couleur: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (v) {
              if (v == 'photo') onChangerPhoto();
              if (v == 'stock') onReapprovisionner();
              if (v == 'promo') onBasculerPromotion();
              if (v == 'supprimer') onSupprimer();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'photo', child: Text('Changer la photo')),
              const PopupMenuItem(
                  value: 'stock', child: Text('Réapprovisionner')),
              PopupMenuItem(
                  value: 'promo',
                  child: Text(produit.enPromotion
                      ? 'Retirer la promotion'
                      : 'Mettre en promotion')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'supprimer',
                child: Text('Supprimer',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: AppColors.surfaceL2,
                  borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.more_vert_rounded,
                  size: 18, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailProduitVendeur extends StatelessWidget {
  final String libellet;
  final String valeur;

  const _DetailProduitVendeur({required this.libellet, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(libellet, style: AppTextStyles.caption())),
          const SizedBox(width: 12),
          Flexible(
            child: Text(valeur,
                textAlign: TextAlign.end, style: AppTextStyles.bodyMedium()),
          ),
        ],
      ),
    );
  }
}
