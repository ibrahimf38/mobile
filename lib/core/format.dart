// Formatage d'affichage partagé par les écrans.

/// 1800 → "1 800" (séparateur de milliers, comme sur la maquette).
String formatMmc(int valeur) {
  final negatif = valeur < 0;
  final s = valeur.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return negatif ? '-$buffer' : buffer.toString();
}

/// Taux de commission plateforme (même valeur que `malimall.commission.taux`
/// côté backend) et part nette qui revient au livreur / chauffeur.
const double tauxCommission = 0.08;

int netApresCommission(int montantMmc) => montantMmc - (montantMmc * tauxCommission).round();

/// Équivalent indicatif suivant le taux déjà utilisé dans le portefeuille :
/// 1 MMC ≈ 5 FCFA.
int equivalentFcfa(int montantMmc) => montantMmc * 5;
