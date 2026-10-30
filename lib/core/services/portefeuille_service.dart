import '../api/api_client.dart';
import '../models/portefeuille_models.dart';

/// Miroir côté client de `PortefeuilleController` (backend).
class PortefeuilleService {
  final ApiClient _client;

  PortefeuilleService(this._client);

  Future<PortefeuilleResponse> solde() {
    return _client.get('/api/portefeuille', (json) => PortefeuilleResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<List<EcritureResponse>> historique() {
    return _client.get(
      '/api/portefeuille/historique',
      (json) => (json as List).map((e) => EcritureResponse.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Recharge via un opérateur mobile money — [operateur] et
  /// [telephoneOperateur] ne servent qu'à l'écran de confirmation
  /// (simulation locale, voir OperateurArgent) : aucun appel réel à
  /// l'opérateur n'est fait, seul le portefeuille MaliMall est mis à jour.
  Future<PortefeuilleResponse> recharger({
    required int montantMmc,
    required String operateur,
    required String telephoneOperateur,
  }) {
    return _client.post(
      '/api/portefeuille/recharge',
      (json) => PortefeuilleResponse.fromJson(json as Map<String, dynamic>),
      body: {'montantMmc': montantMmc, 'operateur': operateur, 'telephoneOperateur': telephoneOperateur},
    );
  }

  Future<PortefeuilleResponse> retirer({
    required int montantMmc,
    required String operateur,
    required String telephoneOperateur,
  }) {
    return _client.post(
      '/api/portefeuille/retrait',
      (json) => PortefeuilleResponse.fromJson(json as Map<String, dynamic>),
      body: {'montantMmc': montantMmc, 'operateur': operateur, 'telephoneOperateur': telephoneOperateur},
    );
  }

  Future<TransfertResultat> transferer({required int montantMmc, required String telephoneDestinataire}) {
    return _client.post(
      '/api/portefeuille/transfert',
      (json) => TransfertResultat.fromJson(json as Map<String, dynamic>),
      body: {'montantMmc': montantMmc, 'telephoneDestinataire': telephoneDestinataire},
    );
  }
}
