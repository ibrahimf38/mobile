import 'package:flutter/material.dart';

import 'position_gps.dart';

/// Miroir de `CourseDtos` (backend) — module MotoTaxi.
enum StatutCourse { demandee, acceptee, enCours, arrivee, terminee, annulee }

/// Catégorie de véhicule demandée pour une course — détermine le tarif par
/// palier (voir QuartiersBamako côté backend) et les chauffeurs à qui la
/// demande est visible (un chauffeur ne voit que les demandes de sa propre
/// catégorie).
enum TypeVehicule { scooter, telimani, tricycle }

extension TypeVehiculeX on TypeVehicule {
  /// Valeur envoyée au backend (miroir de l'enum Java).
  String get code => switch (this) {
        TypeVehicule.scooter => 'SCOOTER',
        TypeVehicule.telimani => 'TELIMANI',
        TypeVehicule.tricycle => 'TRICYCLE',
      };

  String get libelle => switch (this) {
        TypeVehicule.scooter => 'Scooter',
        TypeVehicule.telimani => 'Telimani',
        TypeVehicule.tricycle => 'TriCycle',
      };

  IconData get icone => switch (this) {
        TypeVehicule.scooter => Icons.moped_outlined,
        TypeVehicule.telimani => Icons.two_wheeler,
        TypeVehicule.tricycle => Icons.electric_rickshaw_outlined,
      };

  /// Tarif par palier affiché avant estimation précise (voir QuartiersBamako).
  String get tarifIndicatif => switch (this) {
        TypeVehicule.tricycle => 'à partir de 500 MMC',
        TypeVehicule.scooter || TypeVehicule.telimani => 'à partir de 200 MMC',
      };
}

TypeVehicule typeVehiculeDepuis(String v) {
  switch (v) {
    case 'SCOOTER':
      return TypeVehicule.scooter;
    case 'TELIMANI':
      return TypeVehicule.telimani;
    case 'TRICYCLE':
      return TypeVehicule.tricycle;
    default:
      throw ArgumentError('TypeVehicule inconnu : $v');
  }
}

StatutCourse statutCourseDepuis(String v) {
  switch (v) {
    case 'DEMANDEE':
      return StatutCourse.demandee;
    case 'ACCEPTEE':
      return StatutCourse.acceptee;
    case 'EN_COURS':
      return StatutCourse.enCours;
    case 'ARRIVEE':
      return StatutCourse.arrivee;
    case 'TERMINEE':
      return StatutCourse.terminee;
    case 'ANNULEE':
      return StatutCourse.annulee;
    default:
      throw ArgumentError('StatutCourse inconnu : $v');
  }
}

class EstimationCourse {
  final String depart;
  final String destination;
  final double distanceKm;
  final int prixMmc;
  final TypeVehicule typeVehicule;

  /// Tracé routier réel (polyline Google encodé), renvoyé par le backend
  /// quand Directions API y est configurée (DirectionsService) — sinon
  /// null, et la carte trace une ligne droite entre départ et destination.
  final String? itineraire;

  const EstimationCourse({
    required this.depart,
    required this.destination,
    required this.distanceKm,
    required this.prixMmc,
    required this.typeVehicule,
    this.itineraire,
  });

  factory EstimationCourse.fromJson(Map<String, dynamic> json) =>
      EstimationCourse(
        depart: json['depart'] as String,
        destination: json['destination'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        prixMmc: json['prixMmc'] as int,
        typeVehicule: typeVehiculeDepuis(json['typeVehicule'] as String),
        itineraire: json['itineraire'] as String?,
      );
}

class ChauffeurDisponible {
  final int chauffeurId;
  final String nom;
  final String? vehiculeType;
  final double noteMoyenne;

  /// null si le chauffeur n'a pas partagé sa position depuis 10 minutes.
  final PositionGps? position;

  const ChauffeurDisponible({
    required this.chauffeurId,
    required this.nom,
    required this.vehiculeType,
    required this.noteMoyenne,
    this.position,
  });

  factory ChauffeurDisponible.fromJson(Map<String, dynamic> json) =>
      ChauffeurDisponible(
        chauffeurId: json['chauffeurId'] as int,
        nom: json['nom'] as String,
        vehiculeType: json['vehiculeType'] as String?,
        noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 5,
        position: PositionGps.depuis(json['position']),
      );
}

class CourseResponse {
  final int id;
  final String depart;
  final String destination;
  final double distanceKm;
  final int prixMmc;
  final StatutCourse statut;
  final String clientNom;
  final String? clientTelephone;
  final int? chauffeurId;
  final String? chauffeurNom;
  final String? chauffeurTelephone;
  final double? chauffeurNote;

  /// Catégorie demandée par le client à la création — connue avant même
  /// qu'un chauffeur accepte (contrairement à [vehiculeType] ci-dessous).
  final TypeVehicule typeVehiculeDemande;
  final String? vehiculeType;
  final String? vehiculeImmatriculation;
  final int? note;
  final DateTime dateDemande;
  final DateTime? dateAcceptation;
  final DateTime? dateFin;

  /// Position en direct du chauffeur pendant la course.
  final PositionGps? chauffeurPosition;

  /// Tracé routier réel (polyline Google encodé) — voir EstimationCourse.itineraire.
  final String? itineraire;

  const CourseResponse({
    required this.id,
    required this.depart,
    required this.destination,
    required this.distanceKm,
    required this.prixMmc,
    required this.statut,
    required this.clientNom,
    required this.clientTelephone,
    required this.chauffeurId,
    required this.chauffeurNom,
    required this.chauffeurTelephone,
    required this.chauffeurNote,
    required this.typeVehiculeDemande,
    required this.vehiculeType,
    required this.vehiculeImmatriculation,
    required this.note,
    required this.dateDemande,
    required this.dateAcceptation,
    required this.dateFin,
    this.chauffeurPosition,
    this.itineraire,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) => CourseResponse(
        id: json['id'] as int,
        depart: json['depart'] as String,
        destination: json['destination'] as String,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        prixMmc: json['prixMmc'] as int,
        statut: statutCourseDepuis(json['statut'] as String),
        clientNom: json['clientNom'] as String,
        clientTelephone: json['clientTelephone'] as String?,
        chauffeurId: json['chauffeurId'] as int?,
        chauffeurNom: json['chauffeurNom'] as String?,
        chauffeurTelephone: json['chauffeurTelephone'] as String?,
        chauffeurNote: (json['chauffeurNote'] as num?)?.toDouble(),
        typeVehiculeDemande:
            typeVehiculeDepuis(json['typeVehiculeDemande'] as String),
        vehiculeType: json['vehiculeType'] as String?,
        vehiculeImmatriculation: json['vehiculeImmatriculation'] as String?,
        note: json['note'] as int?,
        dateDemande: DateTime.parse(json['dateDemande'] as String),
        dateAcceptation: json['dateAcceptation'] == null
            ? null
            : DateTime.parse(json['dateAcceptation'] as String),
        dateFin: json['dateFin'] == null
            ? null
            : DateTime.parse(json['dateFin'] as String),
        chauffeurPosition: PositionGps.depuis(json['chauffeurPosition']),
        itineraire: json['itineraire'] as String?,
      );

  bool get enCours =>
      statut == StatutCourse.demandee ||
      statut == StatutCourse.acceptee ||
      statut == StatutCourse.enCours ||
      statut == StatutCourse.arrivee;

  String? get vehiculeLibelle {
    final t = vehiculeType;
    if (t == null || t.isEmpty) return null;
    return t == 'TRICYCLE' ? 'TriCycle' : t[0] + t.substring(1).toLowerCase();
  }
}
