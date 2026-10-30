import '../api/api_client.dart';
import '../models/livreur_models.dart';

/// Miroir côté client de `EspaceLivreurController` (backend).
class LivreurService {
  final ApiClient _client;

  LivreurService(this._client);

  Future<EspaceLivreurResponse> resume() {
    return _client.get('/api/moi/chauffeur', (json) => EspaceLivreurResponse.fromJson(json as Map<String, dynamic>));
  }

  /// Partage la position GPS du livreur (PUT /api/moi/chauffeur/position).
  Future<void> envoyerPosition(double latitude, double longitude) {
    return _client.put(
      '/api/moi/chauffeur/position',
      (_) {},
      body: {'latitude': latitude, 'longitude': longitude},
    );
  }

  Future<EspaceLivreurResponse> changerDisponibilite(bool disponible) {
    return _client.patch(
      '/api/moi/chauffeur/disponibilite',
      (json) => EspaceLivreurResponse.fromJson(json as Map<String, dynamic>),
      body: {'disponible': disponible},
    );
  }
}
