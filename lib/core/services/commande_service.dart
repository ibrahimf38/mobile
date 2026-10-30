import '../api/api_client.dart';
import '../models/commande_models.dart';

/// Miroir côté client de `CommandeController` (backend).
class CommandeService {
  final ApiClient _client;

  CommandeService(this._client);

  Future<CommandeResponse> obtenir(int id) {
    return _client.get('/api/commandes/$id',
        (json) => CommandeResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<CommandeResponse> annuler(int id) {
    return _client.post(
      '/api/commandes/$id/annuler',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// role: 'acheteur' (défaut) | 'vendeur' | 'chauffeur'.
  Future<List<CommandeResponse>> mesCommandes({String role = 'acheteur'}) {
    return _client.get(
      '/api/commandes?role=$role',
      (json) => (json as List)
          .map((e) => CommandeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Livraisons pas encore prises en charge (statutLivraison == EN_ATTENTE_LIVREUR)
  /// — pour que le chauffeur les parcoure avant de s'auto-assigner.
  Future<List<CommandeResponse>> disponibles() {
    return _client.get(
      '/api/commandes/disponibles',
      (json) => (json as List)
          .map((e) => CommandeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<CommandeResponse> assignerChauffeur(int commandeId) {
    return _client.post(
      '/api/commandes/$commandeId/assigner-chauffeur',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CommandeResponse> scannerRetrait(int commandeId, String code) {
    return _client.post(
      '/api/commandes/$commandeId/scanner-retrait',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
      body: {'code': code},
    );
  }

  Future<CommandeResponse> signalerEnRoute(int commandeId) {
    return _client.post(
      '/api/commandes/$commandeId/en-route',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Note (1 à 5) donnée au livreur par l'acheteur, une fois livré.
  Future<CommandeResponse> noterLivreur(int commandeId, int note) {
    return _client.post(
      '/api/commandes/$commandeId/noter-livreur',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
      body: {'note': note},
    );
  }

  /// Signalement : bloque la confirmation (et les fonds) jusqu'à son traitement.
  Future<CommandeResponse> signaler(
      int commandeId, MotifSignalement motif, String? description) {
    return _client.post(
      '/api/commandes/$commandeId/signaler',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
      body: {'motif': motif.valeurBackend, 'description': description},
    );
  }

  Future<CommandeResponse> confirmerLivraison(int commandeId, String code) {
    return _client.post(
      '/api/commandes/$commandeId/confirmer-livraison',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
      body: {'code': code},
    );
  }

  /// Retrait sur place (Commande.retraitParClient) : le vendeur saisit le
  /// code que le client lui présente en venant chercher sa commande.
  Future<CommandeResponse> confirmerRetraitClient(int commandeId, String code) {
    return _client.post(
      '/api/commandes/$commandeId/confirmer-retrait-client',
      (json) => CommandeResponse.fromJson(json as Map<String, dynamic>),
      body: {'code': code},
    );
  }
}
