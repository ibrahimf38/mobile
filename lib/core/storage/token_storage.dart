import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste le JWT dans le stockage sécurisé du système (Keystore Android /
/// Keychain iOS) — jamais en `SharedPreferences` en clair.
///
/// Sert aussi à retenir si l'onboarding a déjà été vu : ce n'est pas une
/// donnée sensible, mais on réutilise ce stockage déjà présent plutôt que
/// d'ajouter une dépendance `shared_preferences` rien que pour ce booléen.
class TokenStorage {
  static const _cleToken = 'malimall_jwt';
  static const _cleOnboardingVu = 'malimall_onboarding_vu';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> sauvegarderToken(String token) => _storage.write(key: _cleToken, value: token);

  Future<String?> lireToken() => _storage.read(key: _cleToken);

  Future<void> effacerToken() => _storage.delete(key: _cleToken);

  /// true si l'utilisateur a déjà terminé le carrousel d'onboarding sur cet
  /// appareil (ne doit s'afficher qu'une seule fois, juste après
  /// l'installation — jamais à chaque lancement de l'app).
  Future<bool> onboardingVu() async => (await _storage.read(key: _cleOnboardingVu)) == '1';

  Future<void> marquerOnboardingVu() => _storage.write(key: _cleOnboardingVu, value: '1');
}
