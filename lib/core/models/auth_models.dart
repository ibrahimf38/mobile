/// Miroir de `com.malimall.backend.dto.AuthDtos` (backend).
class AuthResponse {
  final String token;
  final int utilisateurId;
  final List<String> roles;

  const AuthResponse(
      {required this.token, required this.utilisateurId, required this.roles});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token'] as String,
        utilisateurId: json['utilisateurId'] as int,
        roles: (json['roles'] as List).map((e) => e as String).toList(),
      );
}

class MoiResponse {
  final int id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final List<String> roles;

  /// Id de la spécialisation Vendeur/Chauffeur de cet utilisateur, si elle
  /// existe — ajouté côté backend (Étape 0 bis) pour que le client puisse
  /// retrouver "sa" boutique / ses propres livraisons sans avoir à mémoriser
  /// ces id localement au moment de devenir-vendeur/devenir-chauffeur.
  final int? vendeurId;
  final int? chauffeurId;

  /// Photo de profil (Supabase Storage) — null tant qu'aucune n'a été téléversée.
  final String? imageUrl;

  /// Reflète `Utilisateur.statutVerification == VERIFIE` côté backend — jamais
  /// vrai pour l'instant (aucun flux de vérification n'existe encore dans ce
  /// lot), exposé tel quel plutôt que simulé pour rester honnête sur l'état réel.
  final bool verifie;
  final DateTime dateCreation;

  const MoiResponse({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.email,
    required this.roles,
    required this.vendeurId,
    required this.chauffeurId,
    required this.imageUrl,
    required this.verifie,
    required this.dateCreation,
  });

  factory MoiResponse.fromJson(Map<String, dynamic> json) => MoiResponse(
        id: json['id'] as int,
        nom: json['nom'] as String,
        prenom: json['prenom'] as String,
        telephone: json['telephone'] as String,
        email: json['email'] as String?,
        roles: (json['roles'] as List).map((e) => e as String).toList(),
        vendeurId: json['vendeurId'] as int?,
        chauffeurId: json['chauffeurId'] as int?,
        imageUrl: json['imageUrl'] as String?,
        verifie: json['verifie'] as bool? ?? false,
        dateCreation: DateTime.parse(json['dateCreation'] as String),
      );

  String get nomComplet => '$prenom $nom';

  MoiResponse copierAvec({
    String? imageUrl,
    List<String>? roles,
    int? vendeurId,
    int? chauffeurId,
  }) =>
      MoiResponse(
        id: id,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email,
        roles: roles ?? this.roles,
        vendeurId: vendeurId ?? this.vendeurId,
        chauffeurId: chauffeurId ?? this.chauffeurId,
        imageUrl: imageUrl ?? this.imageUrl,
        verifie: verifie,
        dateCreation: dateCreation,
      );
}
