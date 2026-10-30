import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/quartiers.dart';
import '../theme/colors.dart';

/// Repère posé sur la carte.
class RepereCarte {
  final String id;
  final LatLng position;

  /// Teinte du marqueur Google (BitmapDescriptor.hueAzure, hueOrange…).
  final double teinte;
  final String titre;
  final String? detail;

  const RepereCarte({
    required this.id,
    required this.position,
    required this.teinte,
    required this.titre,
    this.detail,
  });
}

/// Carte Google Maps de l'app : repères, trajet éventuel et point bleu de
/// l'utilisateur. La caméra englobe automatiquement tous les repères, et se
/// recadre quand ils bougent (position du livreur en direct).
class CarteMaliMall extends StatefulWidget {
  final List<RepereCarte> reperes;

  /// Trajet tracé entre deux points (ligne directe, en pointillés) — utilisé
  /// seulement quand [itineraire] n'est pas fourni (Directions API non
  /// disponible côté serveur, voir DirectionsService).
  final (LatLng, LatLng)? trajet;

  /// Tracé routier réel (décodé depuis EstimationCourse/CourseResponse.itineraire
  /// via decodeGooglePolyline) — dessiné en trait plein le long des rues,
  /// à la place de la ligne droite de [trajet], quand disponible.
  final List<LatLng>? itineraire;
  final bool afficherMaPosition;

  /// Marges pour que les repères ne passent pas sous les panneaux posés sur la carte.
  final EdgeInsets marges;

  /// Appelé quand l'utilisateur touche une zone de la carte — permet de
  /// choisir un point (ex. destination MotoTaxi) directement dessus plutôt
  /// que via une liste, comme dans le vrai MaliMall (request_ride_screen.dart).
  final ValueChanged<LatLng>? onTap;

  const CarteMaliMall({
    super.key,
    this.reperes = const [],
    this.trajet,
    this.itineraire,
    this.afficherMaPosition = true,
    this.marges = EdgeInsets.zero,
    this.onTap,
  });

  @override
  State<CarteMaliMall> createState() => _CarteMaliMallState();
}

class _CarteMaliMallState extends State<CarteMaliMall> {
  GoogleMapController? _controleur;

  List<LatLng> get _points => [
        for (final r in widget.reperes) r.position,
        if (widget.itineraire != null && widget.itineraire!.isNotEmpty)
          ...widget.itineraire!
        else if (widget.trajet != null)
          ...[widget.trajet!.$1, widget.trajet!.$2],
      ];

  @override
  void didUpdateWidget(covariant CarteMaliMall ancien) {
    super.didUpdateWidget(ancien);
    final avant = [for (final r in ancien.reperes) r.position];
    final apres = [for (final r in widget.reperes) r.position];
    if (avant.length != apres.length || !List.generate(avant.length, (i) => avant[i] == apres[i]).every((e) => e)) {
      _cadrer();
    }
  }

  @override
  void dispose() {
    _controleur?.dispose();
    super.dispose();
  }

  Future<void> _cadrer() async {
    final c = _controleur;
    final points = _points;
    if (c == null || points.isEmpty) return;
    if (points.length == 1) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14.5));
      return;
    }
    var sud = points.first.latitude, nord = sud, ouest = points.first.longitude, est = ouest;
    for (final p in points) {
      sud = math.min(sud, p.latitude);
      nord = math.max(nord, p.latitude);
      ouest = math.min(ouest, p.longitude);
      est = math.max(est, p.longitude);
    }
    await c.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(sud, ouest), northeast: LatLng(nord, est)),
      70,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: points.isEmpty ? centreBamako : points.first, zoom: 13),
      padding: widget.marges,
      myLocationEnabled: widget.afficherMaPosition,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onTap: widget.onTap,
      onMapCreated: (c) {
        _controleur = c;
        // Laisse la carte prendre sa taille avant de cadrer.
        Future.delayed(const Duration(milliseconds: 300), _cadrer);
      },
      markers: {
        for (final r in widget.reperes)
          Marker(
            markerId: MarkerId(r.id),
            position: r.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(r.teinte),
            infoWindow: InfoWindow(title: r.titre, snippet: r.detail),
          ),
      },
      polylines: {
        if (widget.itineraire != null && widget.itineraire!.length >= 2)
          // Tracé routier réel (Directions API, voir DirectionsService) — trait
          // plein, comme le vrai MaliMall (request_ride_screen.dart).
          Polyline(
            polylineId: const PolylineId('itineraire'),
            points: widget.itineraire!,
            color: AppColors.accentBleu,
            width: 4,
          )
        else if (widget.trajet != null)
          // Repli ligne droite (Directions API non disponible côté serveur) —
          // pointillés pour signaler que ce n'est pas le tracé exact des rues.
          Polyline(
            polylineId: const PolylineId('trajet'),
            points: [widget.trajet!.$1, widget.trajet!.$2],
            color: AppColors.accentBleu,
            width: 4,
            patterns: [PatternItem.dash(18), PatternItem.gap(10)],
          ),
      },
    );
  }
}
