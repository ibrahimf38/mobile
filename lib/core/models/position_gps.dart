/// Position GPS renvoyée par le backend (PositionDto) : dernière position
/// partagée par un chauffeur, avec l'heure de mise à jour.
class PositionGps {
  final double latitude;
  final double longitude;
  final DateTime maj;

  const PositionGps({required this.latitude, required this.longitude, required this.maj});

  static PositionGps? depuis(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return PositionGps(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      maj: DateTime.parse(json['maj'] as String),
    );
  }
}
