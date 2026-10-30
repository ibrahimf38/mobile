import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/models/auth_models.dart';
import '../core/services/auth_service.dart';
import '../core/storage/token_storage.dart';

enum EtatSession { chargement, deconnecte, connecte }

/// Source de vérité pour la session courante — JWT, utilisateur, rôles.
///
/// Après l'ajout d'une spécialisation, le profil local est mis à jour tout de
/// suite et le backend recalcule les rôles depuis la base à chaque requête.
class SessionProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  SessionProvider({
    required ApiClient apiClient,
    required AuthService authService,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _authService = authService,
        _tokenStorage = tokenStorage {
    _apiClient.onNonAutorise = _surSessionExpiree;
  }

  EtatSession etat = EtatSession.chargement;
  MoiResponse? utilisateur;
  List<String> roles = [];
  String? erreur;

  /// true dès que l'onboarding a été vu une fois sur cet appareil — ne doit
  /// plus jamais redéclencher l'affichage du carrousel (voir _RacineNavigation
  /// dans app.dart).
  bool onboardingVu = false;

  bool get estConnecte => etat == EtatSession.connecte && utilisateur != null;
  bool get estVendeur => roles.contains('ROLE_VENDEUR');
  bool get estChauffeur => roles.contains('ROLE_CHAUFFEUR');
  bool get estAdmin => roles.contains('ROLE_ADMIN');
  int? get vendeurId => utilisateur?.vendeurId;
  int? get chauffeurId => utilisateur?.chauffeurId;

  /// À appeler une fois au démarrage de l'app (voir main.dart) : restaure la
  /// session depuis le token déjà stocké, si présent et encore valide.
  Future<void> initialiser() async {
    onboardingVu = await _tokenStorage.onboardingVu();
    final token = await _tokenStorage.lireToken();
    if (token == null) {
      etat = EtatSession.deconnecte;
      notifyListeners();
      return;
    }
    try {
      final moi = await _authService.moi();
      utilisateur = moi;
      roles = moi.roles;
      etat = EtatSession.connecte;
    } catch (_) {
      // Token expiré/invalide : on repart sur un état déconnecté propre,
      // sans bloquer le démarrage de l'app sur une erreur réseau transitoire.
      await _tokenStorage.effacerToken();
      etat = EtatSession.deconnecte;
    }
    notifyListeners();
  }

  Future<bool> connecter(
      {required String telephone, required String motDePasse}) async {
    erreur = null;
    try {
      final reponse = await _authService.connecter(
          telephone: telephone, motDePasse: motDePasse);
      await _apresAuthReussie(reponse);
      return true;
    } on ApiException catch (e) {
      erreur = e.message;
      notifyListeners();
      return false;
    } on ReseauException catch (e) {
      erreur = e.message;
      notifyListeners();
      return false;
    }
  }

  void activerRoleVendeur(int vendeurId) {
    final courant = utilisateur;
    if (courant == null) return;
    if (!roles.contains('ROLE_VENDEUR')) {
      roles = [...roles, 'ROLE_VENDEUR'];
    }
    utilisateur = courant.copierAvec(roles: roles, vendeurId: vendeurId);
    notifyListeners();
  }

  void activerRoleChauffeur(int chauffeurId) {
    final courant = utilisateur;
    if (courant == null) return;
    if (!roles.contains('ROLE_CHAUFFEUR')) {
      roles = [...roles, 'ROLE_CHAUFFEUR'];
    }
    utilisateur = courant.copierAvec(roles: roles, chauffeurId: chauffeurId);
    notifyListeners();
  }

  Future<bool> inscrire({
    required String nom,
    required String prenom,
    required String telephone,
    String? email,
    required String motDePasse,
  }) async {
    erreur = null;
    try {
      final reponse = await _authService.inscrire(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        motDePasse: motDePasse,
      );
      await _apresAuthReussie(reponse);
      return true;
    } on ApiException catch (e) {
      erreur = e.message;
      notifyListeners();
      return false;
    } on ReseauException catch (e) {
      erreur = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> _apresAuthReussie(AuthResponse reponse) async {
    await _tokenStorage.sauvegarderToken(reponse.token);
    final moi = await _authService.moi();
    utilisateur = moi;
    roles = moi.roles;
    etat = EtatSession.connecte;
    notifyListeners();
  }

  /// Met à jour localement la photo de profil après un envoi réussi via
  /// ProfilService.televerserPhoto — évite un aller-retour /api/moi complet
  /// juste pour une URL déjà connue de l'appelant.
  void mettreAJourPhotoProfil(String imageUrl) {
    if (utilisateur == null) return;
    utilisateur = utilisateur!.copierAvec(imageUrl: imageUrl);
    notifyListeners();
  }

  Future<void> deconnecter() async {
    await _tokenStorage.effacerToken();
    utilisateur = null;
    roles = [];
    etat = EtatSession.deconnecte;
    notifyListeners();
  }

  /// Appelé une seule fois, quand l'utilisateur termine le carrousel
  /// d'onboarding (bouton "Commencer") — ne le montre plus jamais ensuite.
  Future<void> marquerOnboardingVu() async {
    if (onboardingVu) return;
    onboardingVu = true;
    await _tokenStorage.marquerOnboardingVu();
    notifyListeners();
  }

  void _surSessionExpiree() {
    if (etat != EtatSession.connecte) return;
    // Best-effort : efface le token stocké sans bloquer sur un await (appelé
    // depuis un callback synchrone de l'ApiClient).
    _tokenStorage.effacerToken();
    utilisateur = null;
    roles = [];
    etat = EtatSession.deconnecte;
    notifyListeners();
  }
}
