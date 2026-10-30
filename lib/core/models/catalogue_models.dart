import 'position_gps.dart';

/// Miroir de `com.malimall.backend.dto.CatalogueDtos` (backend).
class BoutiqueResponse {
  final int id;
  final String nom;
  final String? description;
  final String? categorie;
  final bool certifiee;
  final int proprietaireId;
  final String? imageUrl;
  final String? quartier;

  /// Position GPS enregistrée par le vendeur (bouton "Ma boutique" —
  /// "Position GPS enregistrée — appuyez pour actualiser"), pour que les
  /// livreurs retrouvent la boutique au retrait.
  final PositionGps? position;

  const BoutiqueResponse({
    required this.id,
    required this.nom,
    required this.description,
    required this.categorie,
    required this.certifiee,
    required this.proprietaireId,
    required this.imageUrl,
    this.quartier,
    this.position,
  });

  factory BoutiqueResponse.fromJson(Map<String, dynamic> json) => BoutiqueResponse(
        id: json['id'] as int,
        nom: json['nom'] as String,
        description: json['description'] as String?,
        categorie: json['categorie'] as String?,
        certifiee: json['certifiee'] as bool,
        proprietaireId: json['proprietaireId'] as int,
        imageUrl: json['imageUrl'] as String?,
        quartier: json['quartier'] as String?,
        position: PositionGps.depuis(json['position']),
      );
}

class ProduitResponse {
  final int id;
  final int boutiqueId;
  final String nom;
  final String? description;
  final int prixMmc;
  final int stock;
  final String? categorie;
  final bool actif;
  final String? imageUrl;
  /// Nombre réel d'unités vendues (somme des lignes de commande) — jamais un
  /// compteur stocké, recalculé côté serveur à chaque lecture. Pas de badge
  /// "likes" : aucun système de favoris n'existe dans ce lot.
  final int quantiteVendue;
  final double poidsKg;
  final bool enPromotion;
  final int? promoPrixMmc;

  const ProduitResponse({
    required this.id,
    required this.boutiqueId,
    required this.nom,
    required this.description,
    required this.prixMmc,
    required this.stock,
    required this.categorie,
    required this.actif,
    required this.imageUrl,
    required this.quantiteVendue,
    this.poidsKg = 1,
    this.enPromotion = false,
    this.promoPrixMmc,
  });

  /// Prix à afficher/facturer : le prix promo si une promotion est active,
  /// sinon le prix normal — miroir de `Produit.prixEffectifMmc()` (backend).
  int get prixEffectifMmc => (enPromotion && promoPrixMmc != null) ? promoPrixMmc! : prixMmc;

  factory ProduitResponse.fromJson(Map<String, dynamic> json) => ProduitResponse(
        id: json['id'] as int,
        boutiqueId: json['boutiqueId'] as int,
        nom: json['nom'] as String,
        description: json['description'] as String?,
        prixMmc: json['prixMmc'] as int,
        stock: json['stock'] as int,
        categorie: json['categorie'] as String?,
        actif: json['actif'] as bool,
        imageUrl: json['imageUrl'] as String?,
        quantiteVendue: json['quantiteVendue'] as int? ?? 0,
        poidsKg: (json['poidsKg'] as num?)?.toDouble() ?? 1,
        enPromotion: json['enPromotion'] as bool? ?? false,
        promoPrixMmc: json['promoPrixMmc'] as int?,
      );
}
