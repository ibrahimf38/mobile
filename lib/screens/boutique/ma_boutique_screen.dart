import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/localisation.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/models/commande_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/catalogue_service.dart';
import '../../core/services/commande_service.dart';
import '../../core/services/profil_service.dart';
import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/auth_card_scaffold.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/state_views.dart';
import 'ajouter_produit_screen.dart';
import 'commandes_boutique_screen.dart';
import 'mes_produits_screen.dart';
import 'publicites_screen.dart';
import 'statistiques_ventes_screen.dart';

/// "Ma boutique" — crée la boutique si le vendeur n'en a pas encore, sinon
/// affiche son en-tête + stats simples + liste de produits.
///
/// Pas d'endpoint dédié "ma boutique" côté backend : on retrouve la boutique
/// du vendeur courant en filtrant GET /api/boutiques sur `proprietaireId`
/// (id de la spécialisation Vendeur, exposé via `SessionProvider.vendeurId`
/// depuis /api/moi — voir le petit ajout backend qui l'expose).
class MaBoutiqueScreen extends StatefulWidget {
  const MaBoutiqueScreen({super.key});

  @override
  State<MaBoutiqueScreen> createState() => _MaBoutiqueScreenState();
}

class _MaBoutiqueScreenState extends State<MaBoutiqueScreen> {
  bool _chargement = true;
  String? _erreur;
  BoutiqueResponse? _boutique;
  List<ProduitResponse> _produits = [];
  int _nombreCommandes = 0;
  int _commandesEnAttente = 0;
  int _totalVentesMmc = 0;

  bool _uploadPhotoBoutiqueEnCours = false;
  bool _positionEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final session = context.read<SessionProvider>();
    if (session.vendeurId == null) {
      setState(() {
        _chargement = false;
        _erreur = null;
      });
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final catalogue = context.read<CatalogueService>();
      final boutiques = await catalogue.listerBoutiques();
      BoutiqueResponse? maBoutique;
      for (final b in boutiques) {
        if (b.proprietaireId == session.vendeurId) {
          maBoutique = b;
          break;
        }
      }
      if (maBoutique != null) {
        final produits = await catalogue.produitsDeLaBoutique(maBoutique.id);
        if (!mounted) return;
        final commandeService = context.read<CommandeService>();
        List<CommandeResponse> commandes = [];
        try {
          commandes = await commandeService.mesCommandes(role: 'vendeur');
        } catch (_) {
          // Stats optionnelles — une erreur ici ne doit pas empêcher d'afficher la boutique.
        }
        if (!mounted) return;
        setState(() {
          _boutique = maBoutique;
          _produits = produits;
          _nombreCommandes = commandes.length;
          _commandesEnAttente = commandes
              .where((c) =>
                  c.statut != StatutCommande.livree &&
                  c.statut != StatutCommande.annulee)
              .length;
          _totalVentesMmc = commandes
              .where((c) => c.statut == StatutCommande.livree)
              .fold(0, (total, c) => total + c.montantTotalMmc);
        });
      } else {
        if (!mounted) return;
        setState(() => _boutique = null);
      }
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

  Future<void> _changerPhotoBoutique() async {
    if (_boutique == null) return;
    final fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    setState(() => _uploadPhotoBoutiqueEnCours = true);
    try {
      final boutiqueMaj = await context
          .read<CatalogueService>()
          .televerserPhotoBoutique(_boutique!.id,
              octets: octets, nomFichier: fichier.name);
      if (!mounted) return;
      setState(() => _boutique = boutiqueMaj);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _uploadPhotoBoutiqueEnCours = false);
    }
  }

  /// Bouton "Position GPS enregistrée — appuyez pour actualiser" : permet au
  /// vendeur de laisser sa position pour que les livreurs puissent venir
  /// récupérer un colis chez lui, s'ils acceptent la livraison.
  Future<void> _actualiserPosition() async {
    if (_boutique == null || _positionEnCours) return;
    setState(() => _positionEnCours = true);
    try {
      final position = await Localisation.positionActuelle();
      if (!mounted) return;
      if (position == null) {
        AppFeedback.warning(
          context,
          "Localisation indisponible : vérifiez que le GPS et l'autorisation d'accès à la position sont activés.",
        );
        return;
      }
      final boutiqueMaj = await context
          .read<CatalogueService>()
          .envoyerPositionBoutique(
              _boutique!.id, position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _boutique = boutiqueMaj);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _positionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final sansBoutique = !_chargement && _erreur == null && _boutique == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(
          titre: sansBoutique ? 'Créer ma boutique' : 'Ma boutique'),
      body: _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : _boutique == null
                  ? _CreerBoutiqueForm(
                      onCree: _charger,
                      activerVendeur: session.vendeurId == null,
                    )
                  : _vueBoutique(_boutique!),
      bottomNavigationBar: _boutique == null || _chargement
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                child: PrimaryButton(
                    label: '+ Ajouter un produit', onPressed: _ajouterProduit),
              ),
            ),
    );
  }

  Future<void> _ajouterProduit() async {
    final boutique = _boutique;
    if (boutique == null) return;
    final categorie = boutique.categorie;
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
            boutiqueId: boutique.id, categorieBoutique: categorie),
      ),
    );
    if (cree == true) _charger();
  }

  /// Maquette 11 — en-tête boutique, 3 statistiques, liste "Gérer".
  Widget _vueBoutique(BoutiqueResponse boutique) {
    final produitsEnLigne = _produits.where((p) => p.actif).length;
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: _uploadPhotoBoutiqueEnCours
                      ? null
                      : _changerPhotoBoutique,
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 56,
                    height: 56,
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentBleu.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _uploadPhotoBoutiqueEnCours
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accentBleu),
                          )
                        : (boutique.imageUrl != null &&
                                boutique.imageUrl!.isNotEmpty
                            ? ReseauImage(imageUrl: boutique.imageUrl)
                            : Text(
                                boutique.nom.isNotEmpty
                                    ? boutique.nom[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.headingXL(
                                        color: AppColors.accentBleu)
                                    .copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800),
                              )),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(boutique.nom,
                        style: AppTextStyles.titleS().copyWith(fontSize: 15.5)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          boutique.certifiee
                              ? Icons.star_rounded
                              : Icons.photo_camera_outlined,
                          size: 13,
                          color: AppColors.accentBleu,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          boutique.certifiee
                              ? 'Boutique certifiée'
                              : 'Touchez le logo pour le changer',
                          style: AppTextStyles.bodyMedium(
                                  color: AppColors.accentBleu)
                              .copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _statTile(formatMmc(_produits.length), 'Produits')),
              const SizedBox(width: 10),
              Expanded(
                  child: _statTile(formatMmc(_nombreCommandes), 'Commandes')),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _statTile(formatMmc(_totalVentesMmc), 'MMC de ventes')),
            ],
          ),
          const SizedBox(height: 14),
          _boutonPosition(boutique),
          const SizedBox(height: 20),
          const TitreSection('Gérer'),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(
                color: AppColors.surfaceL1,
                borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                _ligneGerer(
                  icone: Icons.shopping_bag_outlined,
                  titre: 'Mes produits',
                  sousTitre: '$produitsEnLigne en ligne',
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          MesProduitsScreen(boutiqueId: boutique.id),
                    ));
                    _charger();
                  },
                ),
                _ligneGerer(
                  icone: Icons.receipt_long_outlined,
                  titre: 'Commandes reçues',
                  sousTitre: '$_commandesEnAttente en attente',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CommandesBoutiqueScreen(),
                  )),
                ),
                _ligneGerer(
                  icone: Icons.bar_chart_rounded,
                  titre: 'Statistiques de ventes',
                  sousTitre: 'Voir les tendances',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        StatistiquesVentesScreen(boutiqueId: boutique.id),
                  )),
                ),
                _ligneGerer(
                  icone: Icons.campaign_outlined,
                  couleurIcone: AppColors.accentOrange,
                  titre: 'Publicité',
                  sousTitre: 'Mettre vos produits en avant',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PublicitesScreen(),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligneGerer({
    required IconData icone,
    required String titre,
    required String sousTitre,
    required VoidCallback onTap,
    Color couleurIcone = AppColors.accentBleu,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: AppColors.accentBleu.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icone, size: 14, color: couleurIcone),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: AppTextStyles.bodyMedium()),
                  const SizedBox(height: 2),
                  Text(sousTitre,
                      style: AppTextStyles.caption().copyWith(fontSize: 10)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.iconDisabled),
          ],
        ),
      ),
    );
  }

  /// Maquette "Ma boutique" — bouton position GPS : "Position GPS enregistrée
  /// — appuyez pour actualiser" une fois enregistrée, sinon invite à
  /// l'enregistrer. Permet aux livreurs de retrouver la boutique au retrait.
  Widget _boutonPosition(BoutiqueResponse boutique) {
    final enregistree = boutique.position != null;
    return InkWell(
      onTap: _positionEnCours ? null : _actualiserPosition,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enregistree
              ? AppColors.accentBleu.withValues(alpha: 0.08)
              : AppColors.surfaceL1,
          borderRadius: BorderRadius.circular(14),
          border: enregistree
              ? Border.all(color: AppColors.accentBleu.withValues(alpha: 0.25))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: _positionEnCours
                  ? const CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accentBleu)
                  : Icon(
                      enregistree
                          ? Icons.location_on_rounded
                          : Icons.location_off_outlined,
                      size: 18,
                      color: AppColors.accentBleu,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                enregistree
                    ? 'Position GPS enregistrée — appuyez pour actualiser'
                    : 'Aucune position GPS — appuyez pour enregistrer',
                style: AppTextStyles.bodyMedium(color: AppColors.accentBleu)
                    .copyWith(fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String chiffre, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(chiffre,
              style: AppTextStyles.titleS()
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 9),
          Text(label,
              style: AppTextStyles.captionSmall().copyWith(fontSize: 9)),
        ],
      ),
    );
  }
}

class _CreerBoutiqueForm extends StatefulWidget {
  final Future<void> Function() onCree;
  final bool activerVendeur;

  const _CreerBoutiqueForm({
    required this.onCree,
    required this.activerVendeur,
  });

  @override
  State<_CreerBoutiqueForm> createState() => _CreerBoutiqueFormState();
}

class _CreerBoutiqueFormState extends State<_CreerBoutiqueForm> {
  final _nomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _categorie = 'Mode';
  String? _quartier;
  bool _enCours = false;
  String? _erreur;

  XFile? _photoChoisie;
  Uint8List? _photoApercu;

  int? _boutiqueIdCreee;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoChoisie = fichier;
      _photoApercu = octets;
    });
  }

  Future<void> _creer() async {
    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Le nom de la boutique est obligatoire.');
      return;
    }
    if (_quartier == null) {
      setState(() => _erreur =
          'Indiquez le quartier de la boutique (point de retrait des livreurs).');
      return;
    }
    if (_photoApercu == null) {
      setState(() => _erreur = 'Ajoutez une photo de votre boutique.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final catalogue = context.read<CatalogueService>();
      var boutiqueId = _boutiqueIdCreee;
      if (boutiqueId == null && widget.activerVendeur) {
        final activation = await context.read<ProfilService>().devenirVendeur(
              nomBoutique: _nomCtrl.text.trim(),
              description: _descriptionCtrl.text.trim().isEmpty
                  ? null
                  : _descriptionCtrl.text.trim(),
              categorie: _categorie,
              quartier: _quartier!,
            );
        if (!mounted) return;
        boutiqueId = activation.boutiqueId;
        _boutiqueIdCreee = boutiqueId;
        context
            .read<SessionProvider>()
            .activerRoleVendeur(activation.vendeurId);
      } else if (boutiqueId == null) {
        final boutique = await catalogue.creerBoutique(
          nom: _nomCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          categorie: _categorie,
          quartier: _quartier,
        );
        boutiqueId = boutique.id;
        _boutiqueIdCreee = boutiqueId;
      }
      if (_photoChoisie != null && _photoApercu != null) {
        await catalogue.televerserPhotoBoutique(boutiqueId,
            octets: _photoApercu!, nomFichier: _photoChoisie!.name);
      }
      await widget.onCree();
    } on ApiException catch (e) {
      setState(() => _erreur = _boutiqueIdCreee != null
          ? "Boutique créée, mais l'envoi de la photo a échoué (${e.message}). Réessayez, ou revenez en arrière : la boutique est déjà créée."
          : e.message);
    } on ReseauException catch (e) {
      setState(() => _erreur = _boutiqueIdCreee != null
          ? "Boutique créée, mais l'envoi de la photo a échoué (${e.message}). Réessayez, ou revenez en arrière : la boutique est déjà créée."
          : e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  static const _categories = [
    'Mode',
    'Artisanat',
    'Bijoux',
    'Maison',
    'Beauté',
    'Électronique',
    'Alimentation'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 3, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ouvrez votre boutique sur Market et commencez à vendre vos produits aux acheteurs de MaliMall.',
                  style:
                      AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                          .copyWith(fontSize: 11.5, height: 1.55),
                ),
                const SizedBox(height: 8),
                Center(child: _logoPicker()),
                const SizedBox(height: 8),
                Text('Photo de la boutique · obligatoire',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption()
                        .copyWith(fontSize: 10.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                const AuthFieldLabel('Nom de la boutique · obligatoire'),
                TextField(
                  controller: _nomCtrl,
                  style: AppTextStyles.bodyDefault(),
                  decoration:
                      const InputDecoration(hintText: 'ex. Atelier Aïcha'),
                ),
                const SizedBox(height: 13),
                const AuthFieldLabel('Catégorie principale · obligatoire'),
                SizedBox(
                  height: 35,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, i) => ChipFiltre(
                      label: _categories[i],
                      actif: _categorie == _categories[i],
                      onTap: () => setState(() => _categorie = _categories[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const AuthFieldLabel(
                    'Quartier (point de retrait) · obligatoire'),
                SizedBox(
                  height: 35,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: quartiersConnus.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (context, i) => ChipFiltre(
                      label: quartiersConnus[i],
                      actif: _quartier == quartiersConnus[i],
                      onTap: () =>
                          setState(() => _quartier = quartiersConnus[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                const AuthFieldLabel('Description · facultative'),
                TextField(
                  controller: _descriptionCtrl,
                  minLines: 3,
                  maxLines: 5,
                  style: AppTextStyles.bodyDefault().copyWith(fontSize: 11.5),
                  decoration: const InputDecoration(
                      hintText: 'Présentez votre boutique en quelques mots…'),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 10),
                  Text(_erreur!,
                      style: AppTextStyles.caption(color: AppColors.danger)),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            child: PrimaryButton(
                label: 'Créer ma boutique',
                enChargement: _enCours,
                onPressed: _creer),
          ),
        ),
      ],
    );
  }

  /// Rond pointillé 88×96 (maquette 19) : appareil photo, puis aperçu.
  Widget _logoPicker() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _choisirPhoto,
        customBorder: const CircleBorder(),
        child: Container(
          width: 88,
          height: 88,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceL2,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider),
          ),
          child: _photoApercu != null
              ? Image.memory(_photoApercu!, fit: BoxFit.cover)
              : const Icon(Icons.photo_camera_outlined,
                  size: 22, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
