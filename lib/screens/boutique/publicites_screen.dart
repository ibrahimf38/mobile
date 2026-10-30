import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/models/publicite_models.dart';
import '../../core/services/catalogue_service.dart';
import '../../core/services/publicite_service.dart';
import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/auth_card_scaffold.dart';
import '../../widgets/photo_picker_tile.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/state_views.dart';
import 'ma_boutique_screen.dart';

/// "Mes publicités" — liste (tous statuts) + création. Une publicité diffuse
/// une bannière sur l'accueil Market une fois validée par un admin (voir
/// PubliciteService côté backend) : ce lot ne construit aucune interface
/// admin dédiée, la validation se fait via Swagger (`/api/admin/publicites`)
/// — cohérent avec le périmètre académique de ce lot.
class PublicitesScreen extends StatefulWidget {
  const PublicitesScreen({super.key});

  @override
  State<PublicitesScreen> createState() => _PublicitesScreenState();
}

class _PublicitesScreenState extends State<PublicitesScreen> {
  bool _chargement = true;
  String? _erreur;
  BoutiqueResponse? _boutique;
  List<PubliciteResponse> _publicites = [];

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
      // Pas d'endpoint "ma boutique" dédié — même technique que MaBoutiqueScreen.
      // Services lus AVANT le premier await (pas de BuildContext après un gap async).
      final catalogueService = context.read<CatalogueService>();
      final publiciteService = context.read<PubliciteService>();
      final boutiques = await catalogueService.listerBoutiques();
      BoutiqueResponse? maBoutique;
      for (final b in boutiques) {
        if (b.proprietaireId == session.vendeurId) {
          maBoutique = b;
          break;
        }
      }
      if (maBoutique != null) {
        final publicites = await publiciteService.mesPublicites();
        if (!mounted) return;
        setState(() {
          _boutique = maBoutique;
          _publicites = publicites;
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

  Future<void> _nouvellePublicite() async {
    if (_boutique == null) return;
    final creee = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NouvellePubliciteScreen(boutiqueId: _boutique!.id)),
    );
    if (creee == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Publicité'),
      floatingActionButton: _boutique != null
          ? FloatingActionButton.extended(
              onPressed: _nouvellePublicite,
              backgroundColor: AppColors.accentBleu,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Nouvelle publicité'),
            )
          : null,
      body: _chargement
          ? const LoadingView()
          : _erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : session.vendeurId == null
                  ? _messageEtapeManquante(
                      icone: Icons.storefront_outlined,
                      titre: 'Vous n\'êtes pas encore vendeur',
                      texte: 'Activez le compte vendeur pour pouvoir diffuser une publicité.',
                    )
                  : _boutique == null
                      ? _messageEtapeManquante(
                          icone: Icons.storefront_outlined,
                          titre: 'Créez d\'abord votre boutique',
                          texte: 'Une publicité est toujours rattachée à une boutique.',
                          action: PrimaryButton(
                            label: 'Créer ma boutique',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MaBoutiqueScreen()),
                            ),
                          ),
                        )
                      : _listePublicites(),
    );
  }

  Widget _messageEtapeManquante({required IconData icone, required String titre, required String texte, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 44, color: AppColors.accentBleu),
            const SizedBox(height: 12),
            Text(titre, style: AppTextStyles.titleS(), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(texte, textAlign: TextAlign.center, style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 18), action],
          ],
        ),
      ),
    );
  }

  Widget _listePublicites() {
    return RefreshIndicator(
      onRefresh: _charger,
      child: _publicites.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 60),
                EmptyView(
                  message: 'Aucune publicité pour le moment. Créez-en une pour apparaître sur l\'accueil Market.',
                  icone: Icons.campaign_outlined,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _publicites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _cartePublicite(_publicites[i]),
            ),
    );
  }

  Widget _cartePublicite(PubliciteResponse p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ReseauImage(imageUrl: p.imageUrl, icone: Icons.campaign_outlined, tailleIcone: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p.titre, style: AppTextStyles.bodyMedium())),
                    _badgeStatut(p.statut),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${p.dureeJours} jours · ${p.prixPayeMmc} MMC', style: AppTextStyles.caption()),
                if (p.statut == StatutPublicite.active && p.dateExpiration != null) ...[
                  const SizedBox(height: 2),
                  Text('Expire le ${_dateFr(p.dateExpiration!)}', style: AppTextStyles.caption(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeStatut(StatutPublicite statut) {
    final (couleur, libelle) = switch (statut) {
      StatutPublicite.enAttente => (AppColors.statutEnAttente, 'En attente'),
      StatutPublicite.active => (AppColors.statutTermineTexte, 'Active'),
      StatutPublicite.expiree => (AppColors.textSecondary, 'Expirée'),
      StatutPublicite.refusee => (AppColors.danger, 'Refusée'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: couleur.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(libelle, style: AppTextStyles.captionSmall(color: couleur)),
    );
  }

  static const _moisFr = [
    'jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  String _dateFr(DateTime d) => '${d.day} ${_moisFr[d.month - 1]} ${d.year}';
}

/// Formulaire de création — débite le vendeur dès la soumission (voir
/// PubliciteService.demander côté backend, pas de gel préalable).
class NouvellePubliciteScreen extends StatefulWidget {
  final int boutiqueId;
  const NouvellePubliciteScreen({super.key, required this.boutiqueId});

  @override
  State<NouvellePubliciteScreen> createState() => _NouvellePubliciteScreenState();
}

class _NouvellePubliciteScreenState extends State<NouvellePubliciteScreen> {
  static const _prixParJourMmc = 20; // Miroir de PubliciteService.PRIX_PAR_JOUR_MMC côté backend.

  final _titreCtrl = TextEditingController();
  int _dureeJours = 7;
  bool _enCours = false;
  String? _erreur;

  XFile? _photoChoisie;
  Uint8List? _photoApercu;

  /// Comme dans AjouterProduitScreen/_CreerBoutiqueForm : si l'envoi de la
  /// photo échoue après une demande déjà débitée, on ne recrée pas une
  /// deuxième publicité au nouvel essai.
  PubliciteResponse? _publiciteCreee;

  @override
  void dispose() {
    _titreCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final fichier = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoChoisie = fichier;
      _photoApercu = octets;
    });
  }

  Future<void> _soumettre() async {
    if (_titreCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Le titre est obligatoire.');
      return;
    }
    if (_photoApercu == null) {
      setState(() => _erreur = 'Ajoutez une image pour votre publicité.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final service = context.read<PubliciteService>();
      final publicite = _publiciteCreee ??
          await service.demander(boutiqueId: widget.boutiqueId, titre: _titreCtrl.text.trim(), dureeJours: _dureeJours);
      _publiciteCreee = publicite;
      if (_photoChoisie != null && _photoApercu != null) {
        await service.televerserPhoto(publicite.id, octets: _photoApercu!, nomFichier: _photoChoisie!.name);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erreur = _publiciteCreee != null
          ? "Publicité créée (débit effectué), mais l'envoi de la photo a échoué (${e.message}). Réessayez : elle ne sera pas payée deux fois."
          : e.message);
    } on ReseauException catch (e) {
      setState(() => _erreur = _publiciteCreee != null
          ? "Publicité créée (débit effectué), mais l'envoi de la photo a échoué (${e.message}). Réessayez : elle ne sera pas payée deux fois."
          : e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prixTotal = _prixParJourMmc * _dureeJours;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Nouvelle publicité'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Votre publicité apparaît en bannière sur l\'accueil Market une fois validée par MaliMall.',
              style: AppTextStyles.bodyDefault(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            PhotoPickerTile(apercu: _photoApercu, onChoisir: _choisirPhoto),
            const SizedBox(height: 4),
            Text(
              'Image de la publicité · obligatoire',
              style: AppTextStyles.captionSmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const AuthFieldLabel('Titre de la publicité · obligatoire'),
            TextField(
              controller: _titreCtrl,
              decoration:
                  const InputDecoration(hintText: 'ex. Nouvelle collection'),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Durée de diffusion', style: AppTextStyles.bodyMedium()),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.accentBleu,
                            onPressed: _dureeJours > 1 ? () => setState(() => _dureeJours--) : null,
                          ),
                          SizedBox(
                            width: 46,
                            child: Text('$_dureeJours j', textAlign: TextAlign.center, style: AppTextStyles.bodyBold()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.accentBleu,
                            onPressed: _dureeJours < 30 ? () => setState(() => _dureeJours++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tarif', style: AppTextStyles.caption()),
                      Text(
                        '$_prixParJourMmc MMC / jour · ≈ ${formatMmc(equivalentFcfa(_prixParJourMmc))} FCFA',
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total débité', style: AppTextStyles.bodyMedium()),
                      Text(
                        '$prixTotal MMC · ≈ ${formatMmc(equivalentFcfa(prixTotal))} FCFA',
                        style: AppTextStyles.bodyBold(color: AppColors.accentBleu),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: 'Payer et soumettre à validation', enChargement: _enCours, onPressed: _soumettre),
          ],
        ),
      ),
    );
  }
}
