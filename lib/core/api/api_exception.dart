/// Erreur métier renvoyée par le backend, traduite depuis l'enveloppe JSON
/// `{timestamp, status, erreur, message}` produite par
/// `GlobalExceptionHandler` (backend). [statusCode] permet aux écrans de
/// distinguer un cas précis (ex. 400 sur un code retrait/livraison invalide)
/// sans reparser le message.
class ApiException implements Exception {
  final int statusCode;
  final String erreur;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.erreur,
    required this.message,
  });

  bool get estNonAutorise => statusCode == 401;
  bool get estAccesRefuse => statusCode == 403;
  bool get estCodeInvalide => statusCode == 400;
  bool get estConflit => statusCode == 409;
  bool get estFondsInsuffisants => statusCode == 422;

  @override
  String toString() => message;
}

/// Erreur de bas niveau (pas de réponse HTTP exploitable) — backend injoignable,
/// timeout, réponse non-JSON... Distincte d'[ApiException] pour que les écrans
/// puissent afficher "Impossible de joindre le serveur" plutôt qu'un message
/// métier inventé.
class ReseauException implements Exception {
  final String message;
  const ReseauException(this.message);

  @override
  String toString() => message;
}

/// Message lisible pour n'importe quelle erreur remontée par un service.
String messageErreur(Object e) {
  if (e is ApiException || e is ReseauException) return e.toString();
  return 'Une erreur inattendue est survenue. Réessayez dans quelques instants. Si le problème persiste, contactez le support.';
}
