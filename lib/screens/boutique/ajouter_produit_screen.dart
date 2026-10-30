import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/catalogue_models.dart';
import '../../core/models/catalogue_categories.dart';
import '../../core/services/catalogue_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/auth_card_scaffold.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/photo_picker_tile.dart';
import '../../widgets/primary_button.dart';

class AjouterProduitScreen extends StatefulWidget {
  final int boutiqueId;
  final String categorieBoutique;

  const AjouterProduitScreen(
      {super.key, required this.boutiqueId, required this.categorieBoutique});

  @override
  State<AjouterProduitScreen> createState() => _AjouterProduitScreenState();
}

class _AjouterProduitScreenState extends State<AjouterProduitScreen> {
  final _nomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _prixCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  late String _categorie;
  bool _enCours = false;
  String? _erreur;

  XFile? _photoChoisie;
  Uint8List? _photoApercu;

  /// Non nul dès que la création a réussi côté serveur — évite de recréer un
  /// deuxième produit si l'utilisateur retape "Enregistrer" après un échec
  /// de l'envoi de la photo (le retap ne réessaie alors que la photo).
  ProduitResponse? _produitCree;

  @override
  void initState() {
    super.initState();
    final categories = sousCategoriesPour(widget.categorieBoutique);
    _categorie = categories.isEmpty ? '' : categories.first;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _prixCtrl.dispose();
    _stockCtrl.dispose();
    _poidsCtrl.dispose();
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

  Future<void> _enregistrer() async {
    final prix = int.tryParse(_prixCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());
    final poidsTexte = _poidsCtrl.text.trim().replaceAll(',', '.');
    final poids = poidsTexte.isEmpty ? null : double.tryParse(poidsTexte);

    if (_nomCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Le nom du produit est obligatoire.');
      return;
    }
    if (_photoApercu == null) {
      setState(() => _erreur = 'Ajoutez une photo du produit pour le publier.');
      return;
    }
    if (prix == null || prix <= 0) {
      setState(() =>
          _erreur = 'Le prix doit être un nombre entier positif (en MMC).');
      return;
    }
    if (stock == null || stock < 0) {
      setState(() =>
          _erreur = 'Le stock doit être un nombre entier positif ou nul.');
      return;
    }

    if (poids == null || poids <= 0 || poids > 500) {
      setState(() => _erreur = 'Le poids est obligatoire et doit être positif (en kg).');
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final catalogue = context.read<CatalogueService>();
      // Ne recrée jamais le produit si un essai précédent a déjà réussi
      // (voir _produitCree) — un retap après un échec d'envoi de photo ne
      // rejoue alors que la photo, jamais POST /produits une deuxième fois.
      final produit = _produitCree ??
          await catalogue.ajouterProduit(
            widget.boutiqueId,
            nom: _nomCtrl.text.trim(),
            description: _descriptionCtrl.text.trim().isEmpty
                ? null
                : _descriptionCtrl.text.trim(),
            prixMmc: prix,
            stock: stock,
            categorie: _categorie,
            poidsKg: poids,
          );
      _produitCree = produit;
      if (_photoChoisie != null && _photoApercu != null) {
        await catalogue.televerserPhotoProduit(produit.id,
            octets: _photoApercu!, nomFichier: _photoChoisie!.name);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erreur = _produitCree != null
          ? "Produit enregistré, mais l'envoi de la photo a échoué (${e.message}). Réessayez, ou revenez en arrière : le produit est déjà créé."
          : e.message);
    } on ReseauException catch (e) {
      setState(() => _erreur = _produitCree != null
          ? "Produit enregistré, mais l'envoi de la photo a échoué (${e.message}). Réessayez, ou revenez en arrière : le produit est déjà créé."
          : e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prixSaisi = int.tryParse(_prixCtrl.text.trim());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Nouveau produit'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhotoPickerTile(
                apercu: _photoApercu, enCours: false, onChoisir: _choisirPhoto),
            const SizedBox(height: 4),
            Text(
              'Photo du produit · obligatoire',
              style: AppTextStyles.captionSmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const AuthFieldLabel('Nom du produit · obligatoire'),
            TextField(
              controller: _nomCtrl,
              style: AppTextStyles.bodyDefault(),
              decoration:
                  const InputDecoration(hintText: 'ex. Boubou brodé homme'),
            ),
            const SizedBox(height: 14),
            AuthFieldLabel(
                'Sous-catégorie de ${widget.categorieBoutique} · obligatoire'),
            SizedBox(
              height: 35,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sousCategoriesPour(widget.categorieBoutique).length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (context, i) {
                  final categories =
                      sousCategoriesPour(widget.categorieBoutique);
                  return ChipFiltre(
                    label: categories[i],
                    actif: _categorie == categories[i],
                    onTap: () => setState(() => _categorie = categories[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _champNombre('Prix MMC *', _prixCtrl, '1800')),
                const SizedBox(width: 10),
                Expanded(child: _champNombre('Stock *', _stockCtrl, '14')),
                const SizedBox(width: 10),
                Expanded(
                    child: _champNombre('Poids kg *', _poidsCtrl, '1',
                        decimal: true)),
              ],
            ),
            if (prixSaisi != null && prixSaisi > 0)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  'Prix indicatif : ≈ ${formatMmc(equivalentFcfa(prixSaisi))} FCFA',
                  style: AppTextStyles.captionSmall(
                      color: AppColors.accentBleu),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Le poids permet de proposer la livraison au bon véhicule (Scooter, Telimani ou TriCycle).',
              style: AppTextStyles.captionSmall(),
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Description · facultative'),
            TextField(
              controller: _descriptionCtrl,
              minLines: 3,
              maxLines: 5,
              style: AppTextStyles.bodyDefault(),
              decoration: const InputDecoration(
                  hintText: 'Boubou traditionnel brodé main, coton local…'),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!,
                  style: AppTextStyles.caption(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
          child: PrimaryButton(
              label: 'Publier le produit',
              enChargement: _enCours,
              onPressed: _enregistrer),
        ),
      ),
    );
  }

  Widget _champNombre(String label, TextEditingController ctrl, String hint,
      {bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(label),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          onChanged: ctrl == _prixCtrl ? (_) => setState(() {}) : null,
          style: AppTextStyles.bodyDefault(),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
