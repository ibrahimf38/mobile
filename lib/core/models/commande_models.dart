import 'position_gps.dart';

/// Miroir de `com.malimall.backend.entity.enums.StatutCommande`.
enum StatutCommande { enAttente, confirmee, enLivraison, livree, annulee }

StatutCommande statutCommandeDepuis(String valeur) {
  switch (valeur) {
    case 'EN_ATTENTE':
      return StatutCommande.enAttente;
    case 'CONFIRMEE':
      return StatutCommande.confirmee;
    case 'EN_LIVRAISON':
      return StatutCommande.enLivraison;
    case 'LIVREE':
      return StatutCommande.livree;
    case 'ANNULEE':
      return StatutCommande.annulee;
    default:
      throw ArgumentError('StatutCommande inconnu : $valeur');
  }
}

/// Miroir de `com.malimall.backend.entity.enums.StatutLivraison`.
///
/// IMPORTANT : côté backend, `statutLivraison` est `null` (ou vaut
/// `EN_ATTENTE_LIVREUR`) tant qu'aucun chauffeur n'a été assigné — c'est un
/// état métier valide ("en attente d'un livreur"), jamais une erreur de
/// désérialisation. D'où le type `StatutLivraison?` (nullable) partout où ce
/// statut est utilisé, plutôt qu'une valeur d'enum dédiée pour ce cas.
enum StatutLivraison { assignee, recuperee, enRoute, livree }

StatutLivraison? statutLivraisonDepuis(String? valeur) {
  switch (valeur) {
    case null:
    case 'EN_ATTENTE_LIVREUR':
      return null; // traité comme "pas encore de chauffeur", pas comme une erreur
    case 'ASSIGNEE':
      return StatutLivraison.assignee;
    case 'RECUPEREE':
      return StatutLivraison.recuperee;
    case 'EN_ROUTE':
      return StatutLivraison.enRoute;
    case 'LIVREE':
      return StatutLivraison.livree;
    default:
      throw ArgumentError('StatutLivraison inconnu : $valeur');
  }
}

class LigneCommandeResponse {
  final int produitId;
  final String produitNom;
  final int quantite;
  final int prixUnitaireMmc;
  final int sousTotal;

  const LigneCommandeResponse({
    required this.produitId,
    required this.produitNom,
    required this.quantite,
    required this.prixUnitaireMmc,
    required this.sousTotal,
  });

  factory LigneCommandeResponse.fromJson(Map<String, dynamic> json) => LigneCommandeResponse(
        produitId: json['produitId'] as int,
        produitNom: json['produitNom'] as String,
        quantite: json['quantite'] as int,
        prixUnitaireMmc: json['prixUnitaireMmc'] as int,
        sousTotal: json['sousTotal'] as int,
      );
}

/// Miroir de `com.malimall.backend.dto.CommandeDtos.CommandeResponse`.
///
/// [codeRetrait] et [codeLivraison] sont nullable côté backend selon le
/// modèle de sécurité à deux codes (CommandeMapper) : le vendeur détient le
/// code de retrait (le livreur le scanne), le livreur détient le code de
/// livraison une fois le colis récupéré (l'acheteur le scanne). null signifie
/// "le viewer courant n'a pas le droit de le voir maintenant". Ne jamais deviner le rôle du viewer à partir de la
/// présence de ces champs — toujours se baser sur `SessionProvider.roles`.
class CommandeResponse {
  final int id;
  final int boutiqueId;
  final String boutiqueNom;
  final int acheteurId;
  final List<LigneCommandeResponse> lignes;
  final int montantTotalMmc;
  final int fraisLivraisonMmc;
  final StatutCommande statut;
  final StatutLivraison? statutLivraison;
  final String? codeRetrait;
  final String? codeLivraison;
  final int? chauffeurId;
  final DateTime dateCommande;
  final DateTime? dateLivraison;

  /// "Prénom N." de l'acheteur, et infos du livreur dès qu'il est assigné.
  final String? acheteurNom;
  final String? chauffeurNom;
  final String? chauffeurTelephone;
  final String? vehiculeType;
  final String? vehiculeImmatriculation;

  /// Poids total du colis, quartier de retrait, adresse de livraison.
  final double poidsTotalKg;
  final String? boutiqueQuartier;
  final String? adresseLivraison;

  /// Suivi horodaté, note donnée au livreur, signalement en cours.
  final DateTime? dateAssignation;
  final DateTime? dateRetrait;
  final int? noteLivreur;
  final bool signalee;

  /// true : le client vient chercher lui-même sa commande chez le vendeur
  /// (pas de livreur assigné, pas de frais de livraison).
  final bool retraitParClient;

  /// Point de livraison exact (GPS) choisi par l'acheteur, facultatif.
  final double? livraisonLatitude;
  final double? livraisonLongitude;

  /// Position en direct du livreur (acheteur et vendeur, pendant la livraison).
  final PositionGps? chauffeurPosition;

  /// Position GPS enregistrée par le vendeur (bouton "Ma boutique"), pour que
  /// le livreur retrouve exactement la boutique au retrait.
  final PositionGps? boutiquePosition;

  const CommandeResponse({
    required this.id,
    required this.boutiqueId,
    required this.boutiqueNom,
    required this.acheteurId,
    required this.lignes,
    required this.montantTotalMmc,
    required this.fraisLivraisonMmc,
    required this.statut,
    required this.statutLivraison,
    required this.codeRetrait,
    required this.codeLivraison,
    required this.chauffeurId,
    required this.dateCommande,
    required this.dateLivraison,
    this.acheteurNom,
    this.chauffeurNom,
    this.chauffeurTelephone,
    this.vehiculeType,
    this.vehiculeImmatriculation,
    this.poidsTotalKg = 0,
    this.boutiqueQuartier,
    this.adresseLivraison,
    this.dateAssignation,
    this.dateRetrait,
    this.noteLivreur,
    this.signalee = false,
    this.retraitParClient = false,
    this.livraisonLatitude,
    this.livraisonLongitude,
    this.chauffeurPosition,
    this.boutiquePosition,
  });

  factory CommandeResponse.fromJson(Map<String, dynamic> json) => CommandeResponse(
        id: json['id'] as int,
        boutiqueId: json['boutiqueId'] as int,
        boutiqueNom: json['boutiqueNom'] as String,
        acheteurId: json['acheteurId'] as int,
        lignes: (json['lignes'] as List)
            .map((e) => LigneCommandeResponse.fromJson(e as Map<String, dynamic>))
            .toList(),
        montantTotalMmc: json['montantTotalMmc'] as int,
        fraisLivraisonMmc: json['fraisLivraisonMmc'] as int,
        statut: statutCommandeDepuis(json['statut'] as String),
        statutLivraison: statutLivraisonDepuis(json['statutLivraison'] as String?),
        codeRetrait: json['codeRetrait'] as String?,
        codeLivraison: json['codeLivraison'] as String?,
        chauffeurId: json['chauffeurId'] as int?,
        dateCommande: DateTime.parse(json['dateCommande'] as String),
        dateLivraison: json['dateLivraison'] == null ? null : DateTime.parse(json['dateLivraison'] as String),
        acheteurNom: json['acheteurNom'] as String?,
        chauffeurNom: json['chauffeurNom'] as String?,
        chauffeurTelephone: json['chauffeurTelephone'] as String?,
        vehiculeType: json['vehiculeType'] as String?,
        vehiculeImmatriculation: json['vehiculeImmatriculation'] as String?,
        poidsTotalKg: (json['poidsTotalKg'] as num?)?.toDouble() ?? 0,
        boutiqueQuartier: json['boutiqueQuartier'] as String?,
        adresseLivraison: json['adresseLivraison'] as String?,
        dateAssignation: _date(json['dateAssignation']),
        dateRetrait: _date(json['dateRetrait']),
        noteLivreur: json['noteLivreur'] as int?,
        signalee: json['signalee'] as bool? ?? false,
        retraitParClient: json['retraitParClient'] as bool? ?? false,
        livraisonLatitude: (json['livraisonLatitude'] as num?)?.toDouble(),
        livraisonLongitude: (json['livraisonLongitude'] as num?)?.toDouble(),
        chauffeurPosition: PositionGps.depuis(json['chauffeurPosition']),
        boutiquePosition: PositionGps.depuis(json['boutiquePosition']),
      );

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.parse(v as String);

  /// "Boubou brodé homme" ou "Boubou brodé homme +2".
  String get resumeArticles {
    if (lignes.isEmpty) return 'Commande n°$id';
    final autres = lignes.length - 1;
    return autres > 0 ? '${lignes.first.produitNom} +$autres' : lignes.first.produitNom;
  }

  /// "Scooter" / "Telimani" / "Tricycle".
  String? get vehiculeLibelle {
    final t = vehiculeType;
    if (t == null || t.isEmpty) return null;
    return t == 'TRICYCLE' ? 'TriCycle' : t[0] + t.substring(1).toLowerCase();
  }

  int get montantTotalAvecLivraison => montantTotalMmc + fraisLivraisonMmc;

  /// Statut "affiché" simplifié, pour le badge (widgets/status_badge.dart) —
  /// regroupe statut + statutLivraison en une seule pastille lisible, plutôt
  /// que d'exposer les deux enums bruts à l'UI.
  StatutAffiche get statutAffiche {
    if (statut == StatutCommande.annulee) return StatutAffiche.annule;
    if (statut == StatutCommande.livree) return StatutAffiche.termine;
    if (statutLivraison != null) return StatutAffiche.enTransit;
    return StatutAffiche.enAttente;
  }
}

/// Statut simplifié affiché en badge — voir la maquette Figma MaliMall
/// section 2 ("Couleurs des badges de statut") pour les couleurs exactes.
enum StatutAffiche { enAttente, enTransit, termine, annule }

/// Motifs de l'écran "Signaler un problème" (miroir de MotifSignalement).
enum MotifSignalement {
  colisNonRecu('COLIS_NON_RECU', 'Colis non reçu / manquant'),
  colisEndommage('COLIS_ENDOMMAGE', 'Colis endommagé à la réception'),
  codeInvalide('CODE_INVALIDE', 'Code de retrait ou de livraison invalide'),
  contactInjoignable('CONTACT_INJOIGNABLE', 'Vendeur / acheteur injoignable'),
  boutiqueFermee('BOUTIQUE_FERMEE', "Boutique fermée à l'arrivée"),
  autre('AUTRE', 'Autre');

  final String valeurBackend;
  final String libelle;
  const MotifSignalement(this.valeurBackend, this.libelle);
}
