import '../api/api_client.dart';
import '../models/profil_models.dart';

/// Miroir côté client de `ProfilController` (backend) : ajout de
/// spécialisations (vendeur/chauffeur) à l'utilisateur courant.
///
/// Après l'ajout d'une spécialisation, l'écran appelant met à jour le profil
/// local dans SessionProvider pour conserver la session courante.
class ProfilService {
  final ApiClient _client;

  ProfilService(this._client);

  Future<ActivationVendeurResponse> devenirVendeur({
    required String nomBoutique,
    required String? description,
    required String categorie,
    required String quartier,
  }) {
    return _client.post(
      '/api/moi/devenir-vendeur',
      (json) =>
          ActivationVendeurResponse.fromJson(json as Map<String, dynamic>),
      body: {
        'nom': nomBoutique,
        'description': description,
        'categorie': categorie,
        'quartier': quartier,
      },
    );
  }

  Future<int> devenirChauffeur({
    required TypeVehicule typeVehicule,
    required String immatriculation,
    String? numeroPermis,
  }) {
    return _client.post(
      '/api/moi/devenir-chauffeur',
      (json) => (json as Map<String, dynamic>)['chauffeurId'] as int,
      body: {
        'typeVehicule': typeVehicule.valeurBackend,
        'immatriculation': immatriculation,
        'numeroPermis': numeroPermis,
      },
    );
  }

  /// Renvoie la nouvelle imageUrl — c'est à l'appelant (SessionProvider) de
  /// mettre à jour l'utilisateur courant, ce service ne connaît pas la session.
  Future<String> televerserPhoto(
      {required List<int> octets, required String nomFichier}) {
    return _client.postMultipart(
      '/api/moi/photo',
      (json) => (json as Map<String, dynamic>)['imageUrl'] as String,
      champFichier: 'fichier',
      octets: octets,
      nomFichier: nomFichier,
    );
  }
}

class ActivationVendeurResponse {
  final int vendeurId;
  final int boutiqueId;

  const ActivationVendeurResponse({
    required this.vendeurId,
    required this.boutiqueId,
  });

  factory ActivationVendeurResponse.fromJson(Map<String, dynamic> json) =>
      ActivationVendeurResponse(
        vendeurId: json['vendeurId'] as int,
        boutiqueId: json['boutiqueId'] as int,
      );
}
