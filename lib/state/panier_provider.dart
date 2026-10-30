import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/models/commande_models.dart';
import '../core/models/panier_models.dart';
import '../core/services/panier_service.dart';

/// État du panier courant. Rechargé explicitement (`charger()`) à l'ouverture
/// de l'écran Panier plutôt que tenu en cache perpétuel — plus simple et plus
/// sûr que d'essayer de répliquer côté client toute la logique de calcul du
/// backend (stock, prix courant...).
class PanierProvider extends ChangeNotifier {
  final PanierService _panierService;

  PanierProvider(this._panierService);

  PanierResponse? panier;
  bool enChargement = false;
  String? erreur;

  int get nombreArticles => panier?.lignes.fold<int>(0, (total, l) => total + l.quantite) ?? 0;

  Future<void> charger() async {
    enChargement = true;
    erreur = null;
    notifyListeners();
    try {
      panier = await _panierService.voir();
    } on ApiException catch (e) {
      erreur = e.message;
    } on ReseauException catch (e) {
      erreur = e.message;
    } finally {
      enChargement = false;
      notifyListeners();
    }
  }

  Future<bool> ajouterLigne({required int produitId, required int quantite}) async {
    erreur = null;
    try {
      panier = await _panierService.ajouterLigne(produitId: produitId, quantite: quantite);
      notifyListeners();
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

  Future<bool> retirerLigne(int ligneId) async {
    erreur = null;
    try {
      panier = await _panierService.retirerLigne(ligneId);
      notifyListeners();
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

  /// Checkout — peut créer PLUSIEURS commandes (une par boutique représentée
  /// dans le panier). L'appelant (écran Panier) doit gérer une liste, jamais
  /// supposer une seule commande créée.
  Future<List<CommandeResponse>?> valider({
    String? adresseLivraison,
    double? latitude,
    double? longitude,
    bool retraitParClient = false,
  }) async {
    erreur = null;
    try {
      final commandes = await _panierService.valider(
        adresseLivraison: adresseLivraison,
        latitude: latitude,
        longitude: longitude,
        retraitParClient: retraitParClient,
      );
      panier = null; // le panier est vidé côté backend une fois validé
      notifyListeners();
      return commandes;
    } on ApiException catch (e) {
      erreur = e.message;
      notifyListeners();
      return null;
    } on ReseauException catch (e) {
      erreur = e.message;
      notifyListeners();
      return null;
    }
  }
}
