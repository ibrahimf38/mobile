import '../api/api_client.dart';
import '../models/catalogue_models.dart';

/// Résultat de la suppression d'un produit — miroir de
/// `AdminDtos`/`ProduitController.supprimer` (backend) : `vraimentSupprime`
/// est faux quand le produit avait déjà été commandé (il est alors
/// simplement désactivé, pas effacé, pour préserver l'historique).
class SuppressionProduitResultat {
  final bool vraimentSupprime;
  const SuppressionProduitResultat(this.vraimentSupprime);
}

/// Miroir côté client de `BoutiqueController` + `ProduitController` (backend)
/// — regroupés ici comme côté backend `CatalogueDtos` regroupe déjà leurs DTO.
class CatalogueService {
  final ApiClient _client;

  CatalogueService(this._client);

  Future<List<ProduitResponse>> listerProduits() {
    return _client.get(
      '/api/produits',
      (json) => (json as List).map((e) => ProduitResponse.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<ProduitResponse> obtenirProduit(int id) {
    return _client.get('/api/produits/$id', (json) => ProduitResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<List<BoutiqueResponse>> listerBoutiques() {
    return _client.get(
      '/api/boutiques',
      (json) => (json as List).map((e) => BoutiqueResponse.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Future<BoutiqueResponse> obtenirBoutique(int id) {
    return _client.get('/api/boutiques/$id', (json) => BoutiqueResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<BoutiqueResponse> creerBoutique({
    required String nom,
    String? description,
    String? categorie,
    String? quartier,
  }) {
    return _client.post(
      '/api/boutiques',
      (json) => BoutiqueResponse.fromJson(json as Map<String, dynamic>),
      body: {'nom': nom, 'description': description, 'categorie': categorie, 'quartier': quartier},
    );
  }

  Future<List<ProduitResponse>> produitsDeLaBoutique(int boutiqueId) {
    return _client.get(
      '/api/boutiques/$boutiqueId/produits',
      (json) => (json as List).map((e) => ProduitResponse.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// [octets] : contenu du fichier (`XFile.readAsBytes()` côté écran) ;
  /// [nomFichier] : nom d'origine, sert seulement à déduire l'extension.
  Future<ProduitResponse> televerserPhotoProduit(int produitId, {required List<int> octets, required String nomFichier}) {
    return _client.postMultipart(
      '/api/produits/$produitId/photo',
      (json) => ProduitResponse.fromJson(json as Map<String, dynamic>),
      champFichier: 'fichier',
      octets: octets,
      nomFichier: nomFichier,
    );
  }

  Future<BoutiqueResponse> televerserPhotoBoutique(int boutiqueId, {required List<int> octets, required String nomFichier}) {
    return _client.postMultipart(
      '/api/boutiques/$boutiqueId/photo',
      (json) => BoutiqueResponse.fromJson(json as Map<String, dynamic>),
      champFichier: 'fichier',
      octets: octets,
      nomFichier: nomFichier,
    );
  }

  /// Enregistre/actualise la position GPS de la boutique — bouton "Position
  /// GPS enregistrée — appuyez pour actualiser" dans "Ma boutique".
  Future<BoutiqueResponse> envoyerPositionBoutique(int boutiqueId, double latitude, double longitude) {
    return _client.put(
      '/api/boutiques/$boutiqueId/position',
      (json) => BoutiqueResponse.fromJson(json as Map<String, dynamic>),
      body: {'latitude': latitude, 'longitude': longitude},
    );
  }

  Future<ProduitResponse> ajouterProduit(
    int boutiqueId, {
    required String nom,
    String? description,
    required int prixMmc,
    required int stock,
    String? categorie,
    double? poidsKg,
  }) {
    return _client.post(
      '/api/boutiques/$boutiqueId/produits',
      (json) => ProduitResponse.fromJson(json as Map<String, dynamic>),
      body: {
        'nom': nom,
        'description': description,
        'prixMmc': prixMmc,
        'stock': stock,
        'categorie': categorie,
        'poidsKg': poidsKg,
      },
    );
  }

  /// Réapprovisionnement — ajoute [quantite] unités au stock existant.
  Future<ProduitResponse> reapprovisionner(int produitId, {required int quantite}) {
    return _client.post(
      '/api/produits/$produitId/stock',
      (json) => ProduitResponse.fromJson(json as Map<String, dynamic>),
      body: {'quantite': quantite},
    );
  }

  /// Active une promotion : [prixMmc] doit être strictement inférieur au prix normal.
  Future<ProduitResponse> mettreEnPromotion(int produitId, {required int prixMmc, required int dureeJours}) {
    return _client.post(
      '/api/produits/$produitId/promotion',
      (json) => ProduitResponse.fromJson(json as Map<String, dynamic>),
      body: {'prixMmc': prixMmc, 'dureeJours': dureeJours},
    );
  }

  Future<ProduitResponse> retirerPromotion(int produitId) {
    return _client.delete(
      '/api/produits/$produitId/promotion',
      (json) => ProduitResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Supprime le produit — vraiment supprimé si jamais commandé, sinon
  /// simplement désactivé côté serveur (voir [SuppressionProduitResultat]).
  Future<SuppressionProduitResultat> supprimerProduit(int produitId) {
    return _client.delete(
      '/api/produits/$produitId',
      (json) => SuppressionProduitResultat((json as Map<String, dynamic>)['supprime'] as bool? ?? false),
    );
  }
}
