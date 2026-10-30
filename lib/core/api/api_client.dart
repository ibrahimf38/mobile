import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Extension MIME -> content-type accepté par SupabaseStorageService côté
/// backend (jpeg/png/webp uniquement — voir la même liste côté serveur).
String _typeMimeImage(String cheminFichier) {
  final chemin = cheminFichier.toLowerCase();
  if (chemin.endsWith('.png')) return 'image/png';
  if (chemin.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

/// Point d'entrée HTTP unique vers le backend Spring Boot — aucun écran ni
/// service ne doit appeler `package:http` directement, tout passe par ici
/// (injection du JWT, décodage JSON, conversion de l'enveloppe d'erreur en
/// [ApiException], interception globale du 401).
class ApiClient {
  /// URL de base du backend.
  ///
  /// IMPORTANT — à adapter selon où l'app tourne (une seule constante à
  /// changer, volontairement pas de `--dart-define` pour rester simple) :
  /// - Émulateur Android          : `http://10.0.2.2:8080`
  ///   (10.0.2.2 est l'alias que l'émulateur Android donne à "localhost" de
  ///   la machine hôte — "localhost" depuis l'émulateur désignerait
  ///   l'émulateur lui-même, pas votre PC).
  /// - Simulateur iOS             : `http://localhost:8080`
  ///   (le simulateur iOS partage le réseau de la machine hôte).
  /// - Téléphone physique (USB/WiFi) : `http://<IP-locale-de-votre-PC>:8080`
  ///   (ex. `http://192.168.1.42:8080` — trouvable via `ipconfig`/`ifconfig` ;
  ///   le téléphone et le PC doivent être sur le même réseau WiFi, et le
  ///   backend doit écouter sur `0.0.0.0`, pas seulement `127.0.0.1`).
  static const String baseUrl = 'https://malimalllite.onrender.com';

  final TokenStorage _tokenStorage;

  /// Callback optionnel déclenché dès qu'un appel renvoie 401 (JWT expiré ou
  /// absent) — branché par [SessionProvider] pour effacer la session et
  /// rediriger vers l'écran Connexion, sans que chaque service ait à s'en
  /// soucier individuellement.
  void Function()? onNonAutorise;

  ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage;

  Future<Map<String, String>> _headers({bool avecJson = true}) async {
    final headers = <String, String>{};
    if (avecJson) headers['Content-Type'] = 'application/json';
    final token = await _tokenStorage.lireToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<T> get<T>(String chemin, T Function(dynamic json) fromJson) async {
    final headers = await _headers();
    return _executer(() => http.get(Uri.parse('$baseUrl$chemin'), headers: headers), fromJson);
  }

  Future<T> post<T>(String chemin, T Function(dynamic json) fromJson, {Object? body}) async {
    final headers = await _headers();
    return _executer(
      () => http.post(
        Uri.parse('$baseUrl$chemin'),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      fromJson,
    );
  }

  Future<T> patch<T>(String chemin, T Function(dynamic json) fromJson, {Object? body}) async {
    final headers = await _headers();
    return _executer(
      () => http.patch(
        Uri.parse('$baseUrl$chemin'),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      fromJson,
    );
  }

  Future<T> put<T>(String chemin, T Function(dynamic json) fromJson, {Object? body}) async {
    final headers = await _headers();
    return _executer(
      () => http.put(
        Uri.parse('$baseUrl$chemin'),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      fromJson,
    );
  }

  Future<T> delete<T>(String chemin, T Function(dynamic json) fromJson) async {
    final headers = await _headers();
    return _executer(() => http.delete(Uri.parse('$baseUrl$chemin'), headers: headers), fromJson);
  }

  /// Envoie une photo en `multipart/form-data` — utilisé pour
  /// POST /api/produits/{id}/photo et POST /api/boutiques/{id}/photo.
  /// Prend les octets bruts (via `XFile.readAsBytes()` côté appelant) plutôt
  /// qu'un chemin de fichier : fonctionne pareil sur émulateur, téléphone et
  /// web sans dépendre de `dart:io File`.
  Future<T> postMultipart<T>(
    String chemin,
    T Function(dynamic json) fromJson, {
    required String champFichier,
    required List<int> octets,
    required String nomFichier,
  }) async {
    final token = await _tokenStorage.lireToken();
    return _executer(() async {
      final requete = http.MultipartRequest('POST', Uri.parse('$baseUrl$chemin'));
      if (token != null) requete.headers['Authorization'] = 'Bearer $token';
      requete.files.add(http.MultipartFile.fromBytes(
        champFichier,
        octets,
        filename: nomFichier,
        contentType: MediaType.parse(_typeMimeImage(nomFichier)),
      ));
      final reponseStreamee = await requete.send().timeout(const Duration(seconds: 20));
      return http.Response.fromStream(reponseStreamee);
    }, fromJson);
  }

  Future<T> _executer<T>(Future<http.Response> Function() appel, T Function(dynamic json) fromJson) async {
    http.Response reponse;
    try {
      reponse = await appel().timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const ReseauException(
          "Impossible de joindre le serveur. Vérifiez que le backend est démarré et que l'URL configurée dans api_client.dart est correcte.");
    } on HttpException {
      throw const ReseauException('Erreur réseau inattendue.');
    } catch (e) {
      throw ReseauException('Erreur réseau inattendue : $e');
    }

    final corpsBrut = reponse.body.isEmpty ? null : reponse.body;
    dynamic corpsJson;
    if (corpsBrut != null) {
      try {
        corpsJson = jsonDecode(corpsBrut);
      } catch (_) {
        corpsJson = null;
      }
    }

    if (reponse.statusCode >= 200 && reponse.statusCode < 300) {
      return fromJson(corpsJson);
    }

    if (reponse.statusCode == 401) {
      onNonAutorise?.call();
    }

    final message = (corpsJson is Map && corpsJson['message'] != null)
        ? corpsJson['message'].toString()
        : 'Une erreur est survenue (${reponse.statusCode}).';
    final erreur = (corpsJson is Map && corpsJson['erreur'] != null)
        ? corpsJson['erreur'].toString()
        : reponse.reasonPhrase ?? '';

    throw ApiException(statusCode: reponse.statusCode, erreur: erreur, message: message);
  }
}

/// Helper pour les endpoints qui ne renvoient rien d'exploitable (ex. 204,
/// ou un corps qu'on ignore volontairement).
Object? ignorerCorps(dynamic json) => null;
