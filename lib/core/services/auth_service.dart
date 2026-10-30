import '../api/api_client.dart';
import '../models/auth_models.dart';

/// Miroir côté client de `AuthController` (backend) : inscription, connexion,
/// profil courant.
class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<AuthResponse> inscrire({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    required String motDePasse,
  }) {
    return _client.post(
      '/api/auth/inscription',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      body: {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'email': email,
        'motDePasse': motDePasse,
      },
    );
  }

  Future<AuthResponse> connecter({required String telephone, required String motDePasse}) {
    return _client.post(
      '/api/auth/connexion',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      body: {'telephone': telephone, 'motDePasse': motDePasse},
    );
  }

  Future<MoiResponse> moi() {
    return _client.get('/api/moi', (json) => MoiResponse.fromJson(json as Map<String, dynamic>));
  }
}
