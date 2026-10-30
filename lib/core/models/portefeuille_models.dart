/// Miroir de `com.malimall.backend.entity.enums.TypeOperation`.
enum TypeOperation {
  recharge,
  retrait,
  achat,
  vente,
  fraisLivraison,
  commission,
  coursePaiement,
  courseRevenu,
  publicite,
  transfertEnvoye,
  transfertRecu,
}

TypeOperation typeOperationDepuis(String valeur) {
  switch (valeur) {
    case 'RECHARGE':
      return TypeOperation.recharge;
    case 'RETRAIT':
      return TypeOperation.retrait;
    case 'ACHAT':
      return TypeOperation.achat;
    case 'VENTE':
      return TypeOperation.vente;
    case 'FRAIS_LIVRAISON':
      return TypeOperation.fraisLivraison;
    case 'COMMISSION':
      return TypeOperation.commission;
    case 'COURSE_PAIEMENT':
      return TypeOperation.coursePaiement;
    case 'COURSE_REVENU':
      return TypeOperation.courseRevenu;
    case 'PUBLICITE':
      return TypeOperation.publicite;
    case 'TRANSFERT_ENVOYE':
      return TypeOperation.transfertEnvoye;
    case 'TRANSFERT_RECU':
      return TypeOperation.transfertRecu;
    default:
      throw ArgumentError('TypeOperation inconnu : $valeur');
  }
}

/// true si l'écriture crédite le portefeuille du viewer (affichage "+"),
/// false si elle le débite (affichage "-"). Purement indicatif pour
/// l'affichage : le signe réel dépend du rôle du viewer sur l'opération
/// (ex. VENTE crédite le vendeur mais ne concerne pas l'acheteur), donc
/// utilisé uniquement dans l'historique du portefeuille du viewer courant,
/// où toutes les écritures listées le concernent déjà par construction
/// (GET /api/portefeuille/historique ne renvoie que celles de l'appelant).
bool estCredit(TypeOperation type) {
  switch (type) {
    case TypeOperation.recharge:
    case TypeOperation.vente:
    case TypeOperation.fraisLivraison:
    case TypeOperation.courseRevenu:
    case TypeOperation.transfertRecu:
      return true;
    case TypeOperation.retrait:
    case TypeOperation.achat:
    case TypeOperation.commission:
    case TypeOperation.coursePaiement:
    case TypeOperation.publicite:
    case TypeOperation.transfertEnvoye:
      return false;
  }
}

class PortefeuilleResponse {
  final int soldeMmc;
  final int soldeGeleMmc;
  final int soldeDisponible;

  const PortefeuilleResponse({required this.soldeMmc, required this.soldeGeleMmc, required this.soldeDisponible});

  factory PortefeuilleResponse.fromJson(Map<String, dynamic> json) => PortefeuilleResponse(
        soldeMmc: json['soldeMmc'] as int,
        soldeGeleMmc: json['soldeGeleMmc'] as int,
        soldeDisponible: json['soldeDisponible'] as int,
      );
}

class TransfertResultat {
  final PortefeuilleResponse portefeuille;
  final String destinataireNomComplet;

  const TransfertResultat({required this.portefeuille, required this.destinataireNomComplet});

  factory TransfertResultat.fromJson(Map<String, dynamic> json) => TransfertResultat(
        portefeuille: PortefeuilleResponse.fromJson(json['portefeuille'] as Map<String, dynamic>),
        destinataireNomComplet: json['destinataireNomComplet'] as String,
      );
}

class EcritureResponse {
  final int id;
  final TypeOperation typeOperation;
  final int montantMmc;
  // Nullable côté serveur : une recharge/retrait/transfert (opérateur mobile
  // money simulé) ne référence ni commande ni course, contrairement à une
  // vente ou une commission.
  final String? referenceType;
  final int? referenceId;
  final DateTime dateCreation;

  const EcritureResponse({
    required this.id,
    required this.typeOperation,
    required this.montantMmc,
    required this.referenceType,
    required this.referenceId,
    required this.dateCreation,
  });

  factory EcritureResponse.fromJson(Map<String, dynamic> json) => EcritureResponse(
        id: json['id'] as int,
        typeOperation: typeOperationDepuis(json['typeOperation'] as String),
        montantMmc: json['montantMmc'] as int,
        referenceType: json['referenceType'] as String?,
        referenceId: json['referenceId'] as int?,
        dateCreation: DateTime.parse(json['dateCreation'] as String),
      );
}
