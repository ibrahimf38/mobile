import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'services/livreur_service.dart';

/// Accès à la position GPS du téléphone (permission demandée au besoin).
class Localisation {
  Localisation._();

  /// true si le service de localisation est actif et la permission accordée
  /// (la demande à l'utilisateur si elle ne l'a pas encore été).
  static Future<bool> autorisee() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  /// Position actuelle, ou null si la localisation est refusée / indisponible.
  static Future<LatLng?> positionActuelle() async {
    try {
      if (!await autorisee()) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Variante « deux API GPS » : renvoie d'abord la dernière position connue
  /// du téléphone (API réseau/cache — quasi instantanée, utile pour centrer
  /// la carte tout de suite au lieu d'un écran vide pendant l'acquisition
  /// GPS), puis affine avec la position GPS précise dès qu'elle arrive via
  /// [onPositionPrecise]. Comparer les deux dans l'app permet de juger si la
  /// dernière position connue suffit ou si mieux vaut toujours attendre le
  /// GPS précis.
  static Future<LatLng?> positionRapide({ValueChanged<LatLng>? onPositionPrecise}) async {
    if (!await autorisee()) return null;

    // 1) API "réseau/cache" — Geolocator.getLastKnownPosition() : ne
    // réveille pas la puce GPS, quasi instantanée, mais peut être ancienne
    // ou absente (jamais localisé auparavant sur cet appareil).
    LatLng? rapide;
    try {
      final derniere = await Geolocator.getLastKnownPosition();
      if (derniere != null) rapide = LatLng(derniere.latitude, derniere.longitude);
    } catch (_) {
      // Ignoré : on retombe simplement sur l'attente du GPS précis ci-dessous.
    }

    // 2) API GPS précise, en tâche de fond — remonte le résultat par
    // callback pour recentrer la carte sans bloquer l'affichage initial.
    if (onPositionPrecise != null) {
      positionActuelle().then((p) {
        if (p != null) onPositionPrecise(p);
      });
    }

    return rapide ?? await positionActuelle();
  }
}

/// Partage la position du livreur avec le backend tant qu'il est en ligne :
/// suit le GPS (tous les 20 m) et renvoie la dernière position au moins
/// toutes les 30 s, pour que clients et vendeurs le voient en direct.
class PartagePosition {
  final LivreurService _service;
  StreamSubscription<Position>? _flux;
  Timer? _minuteur;
  LatLng? _derniere;
  DateTime _dernierEnvoi = DateTime.fromMillisecondsSinceEpoch(0);

  PartagePosition(this._service);

  bool get actif => _flux != null;

  Future<void> demarrer() async {
    if (actif || !await Localisation.autorisee()) return;
    _flux = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 20),
    ).listen((p) {
      _derniere = LatLng(p.latitude, p.longitude);
      if (DateTime.now().difference(_dernierEnvoi) > const Duration(seconds: 10)) _envoyer();
    }, onError: (_) {});
    _minuteur = Timer.periodic(const Duration(seconds: 30), (_) => _envoyer());
    final actuelle = await Localisation.positionActuelle();
    if (actuelle != null) {
      _derniere = actuelle;
      await _envoyer();
    }
  }

  Future<void> _envoyer() async {
    final p = _derniere;
    if (p == null) return;
    _dernierEnvoi = DateTime.now();
    try {
      await _service.envoyerPosition(p.latitude, p.longitude);
    } catch (_) {
      // Réessayé au prochain point GPS ou au prochain tick.
    }
  }

  void arreter() {
    _flux?.cancel();
    _flux = null;
    _minuteur?.cancel();
    _minuteur = null;
  }
}
