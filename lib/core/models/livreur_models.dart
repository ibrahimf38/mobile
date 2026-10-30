/// Miroir de `LivreurDtos.EspaceLivreurResponse` (backend).
class EspaceLivreurResponse {
  final int chauffeurId;
  final bool disponible;
  final String? vehiculeType;
  final String? immatriculation;

  /// null = pas de limite de poids (TriCycle).
  final int? capaciteMaxKg;
  final bool transportePassagers;
  final double noteMoyenne;
  final int coursesEtLivraisonsTerminees;
  final int gainsMmc;
  final int livraisonsEnAttente;
  final int coursesEnAttente;

  const EspaceLivreurResponse({
    required this.chauffeurId,
    required this.disponible,
    required this.vehiculeType,
    required this.immatriculation,
    required this.capaciteMaxKg,
    required this.transportePassagers,
    required this.noteMoyenne,
    required this.coursesEtLivraisonsTerminees,
    required this.gainsMmc,
    required this.livraisonsEnAttente,
    required this.coursesEnAttente,
  });

  factory EspaceLivreurResponse.fromJson(Map<String, dynamic> json) => EspaceLivreurResponse(
        chauffeurId: json['chauffeurId'] as int,
        disponible: json['disponible'] as bool,
        vehiculeType: json['vehiculeType'] as String?,
        immatriculation: json['immatriculation'] as String?,
        capaciteMaxKg: json['capaciteMaxKg'] as int?,
        transportePassagers: json['transportePassagers'] as bool? ?? false,
        noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 5,
        coursesEtLivraisonsTerminees: (json['coursesEtLivraisonsTerminees'] as num?)?.toInt() ?? 0,
        gainsMmc: (json['gainsMmc'] as num?)?.toInt() ?? 0,
        livraisonsEnAttente: (json['livraisonsEnAttente'] as num?)?.toInt() ?? 0,
        coursesEnAttente: (json['coursesEnAttente'] as num?)?.toInt() ?? 0,
      );

  /// "Telimani", "Scooter", "Tricycle".
  String get vehiculeLibelle {
    final t = vehiculeType;
    if (t == null || t.isEmpty) return 'Véhicule';
    return t == 'TRICYCLE' ? 'TriCycle' : t[0] + t.substring(1).toLowerCase();
  }

  /// "passagers ou colis ≤ 20 kg", "colis ≤ 10 kg", "colis lourds".
  String get capaciteLibelle {
    final c = capaciteMaxKg;
    final colis = c == null ? 'colis lourds et volumineux' : 'colis ≤ $c kg';
    return transportePassagers ? 'passagers ou $colis' : colis;
  }

  bool peutTransporter(double poidsKg) => capaciteMaxKg == null || poidsKg <= capaciteMaxKg!;
}
