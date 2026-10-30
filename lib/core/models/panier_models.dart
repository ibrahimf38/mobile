/// Miroir de `com.malimall.backend.dto.PanierDtos` (backend).
class LigneResponse {
  final int id;
  final int produitId;
  final String produitNom;
  final int boutiqueId;
  final String boutiqueNom;
  final int quantite;
  final int prixUnitaireMmc;
  final int sousTotal;

  const LigneResponse({
    required this.id,
    required this.produitId,
    required this.produitNom,
    required this.boutiqueId,
    required this.boutiqueNom,
    required this.quantite,
    required this.prixUnitaireMmc,
    required this.sousTotal,
  });

  factory LigneResponse.fromJson(Map<String, dynamic> json) => LigneResponse(
        id: json['id'] as int,
        produitId: json['produitId'] as int,
        produitNom: json['produitNom'] as String,
        boutiqueId: json['boutiqueId'] as int,
        boutiqueNom: json['boutiqueNom'] as String,
        quantite: json['quantite'] as int,
        prixUnitaireMmc: json['prixUnitaireMmc'] as int,
        sousTotal: json['sousTotal'] as int,
      );
}

class PanierResponse {
  final int id;
  final List<LigneResponse> lignes;
  final int totalMmc;

  const PanierResponse({required this.id, required this.lignes, required this.totalMmc});

  factory PanierResponse.fromJson(Map<String, dynamic> json) => PanierResponse(
        id: json['id'] as int,
        lignes: (json['lignes'] as List).map((e) => LigneResponse.fromJson(e as Map<String, dynamic>)).toList(),
        totalMmc: json['totalMmc'] as int,
      );

  bool get estVide => lignes.isEmpty;
}
