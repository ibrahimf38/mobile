import '../api/api_client.dart';
import '../models/publicite_models.dart';

/// Miroir côté client de `PubliciteController` (backend).
class PubliciteService {
  final ApiClient _client;

  PubliciteService(this._client);

  /// Bannières actives à afficher sur l'accueil Market — tout utilisateur connecté.
  Future<List<PubliciteResponse>> actives() {
    return _client.get(
      '/api/publicites/actives',
      (json) => (json as List).map((e) => PubliciteResponse.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Publicités du vendeur courant (tous statuts) — réservé ROLE_VENDEUR.
  Future<List<PubliciteResponse>> mesPublicites() {
    return _client.get(
      '/api/publicites/mes',
      (json) => (json as List).map((e) => PubliciteResponse.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Débite immédiatement le vendeur (voir PubliciteService côté backend) —
  /// 422 si solde insuffisant.
  Future<PubliciteResponse> demander({required int boutiqueId, required String titre, required int dureeJours}) {
    return _client.post(
      '/api/publicites',
      (json) => PubliciteResponse.fromJson(json as Map<String, dynamic>),
      body: {'boutiqueId': boutiqueId, 'titre': titre, 'dureeJours': dureeJours},
    );
  }

  Future<PubliciteResponse> televerserPhoto(int publiciteId, {required List<int> octets, required String nomFichier}) {
    return _client.postMultipart(
      '/api/publicites/$publiciteId/photo',
      (json) => PubliciteResponse.fromJson(json as Map<String, dynamic>),
      champFichier: 'fichier',
      octets: octets,
      nomFichier: nomFichier,
    );
  }
}
