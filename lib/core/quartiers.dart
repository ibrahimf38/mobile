import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Centre des quartiers de Bamako gérés par l'app — mêmes coordonnées que
/// côté backend (QuartiersBamako), qui s'en sert pour calculer distance et
/// prix. Sur la carte, un quartier sert de repère quand on n'a pas de
/// position GPS plus précise.
const Map<String, (double lat, double lon)> _coordonnees = {
  'ACI 2000': (12.6280, -8.0200),
  'Badalabougou': (12.6250, -7.9950),
  'Baco Djicoroni': (12.6000, -8.0150),
  'Centre-ville': (12.6400, -7.9990),
  'Djicoroni Para': (12.6380, -8.0520),
  'Faladié': (12.6000, -7.9600),
  'Hamdallaye': (12.6420, -8.0290),
  'Hippodrome': (12.6520, -7.9960),
  'Kalaban Coura': (12.5780, -8.0000),
  'Lafiabougou': (12.6450, -8.0450),
  'Magnambougou': (12.6070, -7.9500),
  'Médina Coura': (12.6560, -7.9870),
  'Missira': (12.6600, -7.9960),
  'Niaréla': (12.6510, -7.9830),
  'Sabalibougou': (12.5930, -7.9740),
  'Sotuba': (12.6600, -7.9230),
  'Torokorobougou': (12.6120, -7.9880),
};

/// Centre de Bamako (caméra par défaut de la carte).
const LatLng centreBamako = LatLng(12.6392, -8.0029);

List<String> get quartiersConnus => _coordonnees.keys.toList();

/// Coordonnées du centre d'un quartier, null s'il est inconnu.
LatLng? coordQuartier(String? quartier) {
  final c = _coordonnees[quartier];
  return c == null ? null : LatLng(c.$1, c.$2);
}

/// Quartier dont le centre est le plus proche d'une position GPS.
String quartierLePlusProche(LatLng p) {
  String meilleur = _coordonnees.keys.first;
  var min = double.infinity;
  _coordonnees.forEach((nom, c) {
    final d = _haversineKm(p.latitude, p.longitude, c.$1, c.$2);
    if (d < min) {
      min = d;
      meilleur = nom;
    }
  });
  return meilleur;
}

/// Distance routière estimée entre deux points GPS (vol d'oiseau × 1,3).
double distanceKmGps(LatLng a, LatLng b) {
  final km = _haversineKm(a.latitude, a.longitude, b.latitude, b.longitude) * 1.3;
  return (km * 10).round() / 10;
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const rayonTerre = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * rayonTerre * math.asin(math.sqrt(h));
}

/// Distance routière estimée entre deux quartiers (km), même calcul que le
/// backend (QuartiersBamako) : distance à vol d'oiseau × 1,3. null si l'un
/// des deux quartiers n'est pas connu.
double? distanceKmEntre(String? a, String? b) {
  final ca = coordQuartier(a);
  final cb = coordQuartier(b);
  if (ca == null || cb == null) return null;
  return distanceKmGps(ca, cb);
}

/// Durée indicative à moto en ville (~25 km/h), au moins 2 min.
int minutesEstimees(double km) => math.max(2, (km / 25 * 60).round());

/// Premier quartier connu cité dans une adresse libre ("Hamdallaye, rue 12").
String? quartierDansAdresse(String? adresse) {
  if (adresse == null) return null;
  final bas = adresse.toLowerCase();
  for (final q in _coordonnees.keys) {
    if (bas.contains(q.toLowerCase())) return q;
  }
  return null;
}

/// Décode un polyline encodé Google (format utilisé par Directions API) en
/// liste de points — même algorithme et même usage que dans le vrai
/// MaliMall (request_ride_screen.dart, decodeGooglePolyline) : le backend
/// (DirectionsService) renvoie ce texte tel quel dans EstimationCourse et
/// CourseResponse.itineraire quand Directions API est configurée côté
/// serveur, sinon ce champ est null et la carte trace une simple ligne
/// droite entre les deux quartiers (voir CarteMaliMall.trajet).
List<LatLng> decodeGooglePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;
  while (index < encoded.length) {
    int shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
