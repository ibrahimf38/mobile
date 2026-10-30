/// Miroir de `com.malimall.backend.entity.enums.StatutPublicite`.
///
/// IMPORTANT : EXPIREE n'est jamais stocké côté backend — il est calculé à
/// la lecture (voir `PubliciteMapper.toResponse`) dès que `dateExpiration`
/// est dépassée pour une publicité ACTIVE. Le client n'a donc jamais besoin
/// de recalculer cette transition lui-même.
enum StatutPublicite { enAttente, active, expiree, refusee }

StatutPublicite statutPubliciteDepuis(String valeur) {
  switch (valeur) {
    case 'EN_ATTENTE':
      return StatutPublicite.enAttente;
    case 'ACTIVE':
      return StatutPublicite.active;
    case 'EXPIREE':
      return StatutPublicite.expiree;
    case 'REFUSEE':
      return StatutPublicite.refusee;
    default:
      throw ArgumentError('StatutPublicite inconnu : $valeur');
  }
}

/// Miroir de `com.malimall.backend.dto.PubliciteDtos.PubliciteResponse`.
class PubliciteResponse {
  final int id;
  final int boutiqueId;
  final String boutiqueNom;
  final String titre;
  final String? imageUrl;
  final int dureeJours;
  final int prixPayeMmc;
  final StatutPublicite statut;
  final DateTime dateCreation;
  final DateTime? dateActivation;
  final DateTime? dateExpiration;

  const PubliciteResponse({
    required this.id,
    required this.boutiqueId,
    required this.boutiqueNom,
    required this.titre,
    required this.imageUrl,
    required this.dureeJours,
    required this.prixPayeMmc,
    required this.statut,
    required this.dateCreation,
    required this.dateActivation,
    required this.dateExpiration,
  });

  factory PubliciteResponse.fromJson(Map<String, dynamic> json) => PubliciteResponse(
        id: json['id'] as int,
        boutiqueId: json['boutiqueId'] as int,
        boutiqueNom: json['boutiqueNom'] as String,
        titre: json['titre'] as String,
        imageUrl: json['imageUrl'] as String?,
        dureeJours: json['dureeJours'] as int,
        prixPayeMmc: json['prixPayeMmc'] as int,
        statut: statutPubliciteDepuis(json['statut'] as String),
        dateCreation: DateTime.parse(json['dateCreation'] as String),
        dateActivation: json['dateActivation'] == null ? null : DateTime.parse(json['dateActivation'] as String),
        dateExpiration: json['dateExpiration'] == null ? null : DateTime.parse(json['dateExpiration'] as String),
      );
}
