import '../api/api_client.dart';
import '../models/commande_models.dart';
import '../models/panier_models.dart';

/// Miroir côté client de `PanierController` (backend).
class PanierService {
  final ApiClient _client;

  PanierService(this._client);

  Future<PanierResponse> voir() {
    return _client.get('/api/panier', (json) => PanierResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<PanierResponse> ajouterLigne({required int produitId, required int quantite}) {
    return _client.post(
      '/api/panier/lignes',
      (json) => PanierResponse.fromJson(json as Map<String, dynamic>),
      body: {'produitId': produitId, 'quantite': quantite},
    );
  }

  Future<PanierResponse> retirerLigne(int ligneId) {
    return _client.delete('/api/panier/lignes/$ligneId', (json) => PanierResponse.fromJson(json as Map<String, dynamic>));
  }

  /// Checkout — peut renvoyer PLUSIEURS commandes si le panier contient des
  /// produits de boutiques différentes (une Commande = un panier validé pour
  /// une seule boutique, côté backend). Ne jamais supposer une seule commande.
  ///
  /// [retraitParClient] : le client vient chercher lui-même sa commande chez
  /// le vendeur (pas de livreur, pas de frais de livraison) — voir l'écran
  /// "Mon panier".
  Future<List<CommandeResponse>> valider({
    String? adresseLivraison,
    double? latitude,
    double? longitude,
    bool retraitParClient = false,
  }) {
    return _client.post(
      '/api/panier/valider',
      (json) => (json as List).map((e) => CommandeResponse.fromJson(e as Map<String, dynamic>)).toList(),
      body: {
        'adresseLivraison': adresseLivraison,
        'latitude': latitude,
        'longitude': longitude,
        'retraitParClient': retraitParClient,
      },
    );
  }
}
