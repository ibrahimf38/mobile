import 'package:flutter/material.dart';

/// Les 4 opérateurs mobile money disponibles pour la recharge/le retrait —
/// paiement entièrement SIMULÉ (aucun appel réel à Orange, Moov, Wave ou
/// Sama Money) : seul le portefeuille MaliMall, lui, est réellement mis à
/// jour côté serveur (voir PortefeuilleController).
enum OperateurArgent {
  orangeMoney('Orange Money', 'OM', Color(0xFFFF7900)),
  moovMoney('Moov Money', 'MM', Color(0xFF0072CE)),
  wave('Wave', 'W', Color(0xFF00B4D8)),
  samaMoney('Sama Money', 'SM', Color(0xFF00A651));

  final String nom;
  final String initiales;
  final Color couleur;
  const OperateurArgent(this.nom, this.initiales, this.couleur);

  /// Code envoyé au backend — purement informatif (voir RechargeRequest).
  String get code => name.toUpperCase();
}

/// Badge rond coloré (initiales) représentant un opérateur — pas de vrai
/// logo (aucun asset de marque disponible), un badge sobre en fait office.
class BadgeOperateur extends StatelessWidget {
  final OperateurArgent operateur;
  final double taille;
  const BadgeOperateur({super.key, required this.operateur, this.taille = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: operateur.couleur, shape: BoxShape.circle),
      child: Text(
        operateur.initiales,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: taille * 0.36,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// Carte sélectionnable pour le choix de l'opérateur (recharge/retrait).
class CarteOperateur extends StatelessWidget {
  final OperateurArgent operateur;
  final bool selectionne;
  final VoidCallback onTap;
  const CarteOperateur({super.key, required this.operateur, required this.selectionne, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selectionne ? operateur.couleur.withValues(alpha: 0.10) : const Color(0xFFF7F7FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selectionne ? operateur.couleur : const Color(0xFFE2E2EA), width: selectionne ? 1.6 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeOperateur(operateur: operateur),
              const SizedBox(height: 9),
              Text(
                operateur.nom,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selectionne ? FontWeight.w800 : FontWeight.w600,
                  color: selectionne ? operateur.couleur : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
