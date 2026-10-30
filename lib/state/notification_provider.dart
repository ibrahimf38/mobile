import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/models/commande_models.dart';
import '../core/models/course_models.dart';
import '../core/services/commande_service.dart';
import '../core/services/course_service.dart';
import '../core/services/livreur_service.dart';

import 'session_provider.dart';

enum TypeNotification {
  nouvelleCommande,
  nouvelleCourse,
  nouvelleLivraison,
  avancementCommande,
}

class NotificationMaliMall {
  final String id;
  final String message;
  final TypeNotification type;
  final int? commandeId;

  const NotificationMaliMall({
    required this.id,
    required this.message,
    required this.type,
    this.commandeId,
  });
}

/// Détecte les nouvelles commandes/demandes et les changements de livraison
/// pendant que l'application est ouverte. Les premières réponses servent de
/// référence afin de ne pas notifier les éléments présents au lancement.
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  final CommandeService _commandeService;
  final CourseService _courseService;
  final LivreurService _livreurService;
  final Set<int> _commandesConnues = {};
  final Map<int, String> _statutsCommandesAcheteur = {};
  final Set<int> _coursesConnues = {};
  final Set<int> _livraisonsConnues = {};
  final List<NotificationMaliMall> _notifications = [];
  final Set<String> _notificationsNonLues = {};

  SessionProvider? _session;
  Timer? _timer;
  bool _commandesInitialisees = false;
  bool _coursesInitialisees = false;
  bool _livraisonsInitialisees = false;
  bool _actualisationEnCours = false;
  bool _estDispose = false;
  int _generation = 0;

  NotificationProvider({
    required CommandeService commandeService,
    required CourseService courseService,
    required LivreurService livreurService,
  })  : _commandeService = commandeService,
        _courseService = courseService,
        _livreurService = livreurService {
    WidgetsBinding.instance.addObserver(this);
  }

  List<NotificationMaliMall> get notifications =>
      List.unmodifiable(_notifications);

  int nombreNonLues(Set<TypeNotification> types) => _notifications
      .where((notification) =>
          types.contains(notification.type) &&
          _notificationsNonLues.contains(notification.id))
      .length;

  bool estNonLue(String id) => _notificationsNonLues.contains(id);

  void marquerLue(String id) {
    if (_notificationsNonLues.remove(id)) notifyListeners();
  }

  void marquerLues(Set<TypeNotification> types) {
    final ids = _notifications
        .where((notification) => types.contains(notification.type))
        .map((notification) => notification.id)
        .toSet();
    if (!ids.any(_notificationsNonLues.contains)) return;
    _notificationsNonLues.removeAll(ids);
    notifyListeners();
  }

  void suivreSession(SessionProvider session) {
    if (identical(_session, session)) return;
    _session?.removeListener(_synchroniser);
    _session = session;
    _session!.addListener(_synchroniser);
    _synchroniser();
  }

  void _synchroniser() {
    if (_session?.estConnecte != true) {
      _generation++;
      _timer?.cancel();
      _timer = null;
      _reinitialiserReferences();
      if (_notifications.isNotEmpty) {
        _notifications.clear();
        _notificationsNonLues.clear();
        notifyListeners();
      }
      return;
    }

    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    _timer ??=
        Timer.periodic(const Duration(seconds: 20), (_) => _actualiser());
    _actualiser();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _synchroniser();
  }

  Future<void> _actualiser() async {
    final session = _session;
    if (_actualisationEnCours || session?.estConnecte != true) return;
    final generation = _generation;
    _actualisationEnCours = true;
    var nouvellesNotifications = false;
    try {
      if (session!.estVendeur) {
        try {
          final commandes =
              await _commandeService.mesCommandes(role: 'vendeur');
          if (_generation != generation || !session.estConnecte) return;
          nouvellesNotifications |= _ajouterCommandesNouvelles(commandes);
        } on Exception catch (e) {
          debugPrint('Notifications de commandes non actualisées : $e');
        }
      } else {
        _commandesInitialisees = false;
        _commandesConnues.clear();
      }

      try {
        final commandesAcheteur =
            await _commandeService.mesCommandes(role: 'acheteur');
        if (_generation != generation || !session.estConnecte) return;
        nouvellesNotifications |=
            _actualiserAvancementCommandes(commandesAcheteur);
      } on Exception catch (e) {
        debugPrint('Notifications de suivi non actualisées : $e');
      }

      if (session.estChauffeur) {
        try {
          final livreur = await _livreurService.resume();
          if (_generation != generation || !session.estConnecte) return;
          if (livreur.disponible) {
            try {
              final courses = await _courseService.disponibles();
              if (_generation != generation || !session.estConnecte) return;
              nouvellesNotifications |= _ajouterCoursesNouvelles(courses);
            } on Exception catch (e) {
              debugPrint('Notifications de courses non actualisées : $e');
            }
            try {
              final livraisons = await _commandeService.disponibles();
              if (_generation != generation || !session.estConnecte) return;
              nouvellesNotifications |= _ajouterLivraisonsNouvelles(
                livraisons
                    .where((livraison) =>
                        livreur.peutTransporter(livraison.poidsTotalKg))
                    .toList(),
              );
            } on Exception catch (e) {
              debugPrint('Notifications de livraisons non actualisées : $e');
            }
          } else {
            _coursesInitialisees = false;
            _livraisonsInitialisees = false;
            _coursesConnues.clear();
            _livraisonsConnues.clear();
          }
        } on Exception catch (e) {
          debugPrint('Notifications chauffeur non actualisées : $e');
        }
      } else {
        _coursesInitialisees = false;
        _livraisonsInitialisees = false;
        _coursesConnues.clear();
        _livraisonsConnues.clear();
      }
    } finally {
      _actualisationEnCours = false;
      if (nouvellesNotifications && !_estDispose && _generation == generation) {
        notifyListeners();
      }
    }
  }

  bool _ajouterCommandesNouvelles(List<CommandeResponse> commandes) {
    final nouvelles = commandes
        .where((commande) => !_commandesConnues.contains(commande.id))
        .toList();
    final initialisation = !_commandesInitialisees;
    _commandesConnues.addAll(commandes.map((commande) => commande.id));
    _commandesInitialisees = true;
    if (initialisation) return false;
    for (final commande in nouvelles) {
      _enregistrerNotification(
        NotificationMaliMall(
          id: 'commande-${commande.id}',
          message:
              'Nouvelle commande reçue : ${commande.boutiqueNom} (#${commande.id}).',
          type: TypeNotification.nouvelleCommande,
        ),
      );
    }
    return nouvelles.isNotEmpty;
  }

  bool _ajouterCoursesNouvelles(List<CourseResponse> courses) {
    final nouvelles = courses
        .where((course) => !_coursesConnues.contains(course.id))
        .toList();
    final initialisation = !_coursesInitialisees;
    _coursesConnues.addAll(courses.map((course) => course.id));
    _coursesInitialisees = true;
    if (initialisation) return false;
    for (final course in nouvelles) {
      _enregistrerNotification(
        NotificationMaliMall(
          id: 'course-${course.id}',
          message: 'Nouvelle course MotoTaxi disponible (#${course.id}).',
          type: TypeNotification.nouvelleCourse,
        ),
      );
    }
    return nouvelles.isNotEmpty;
  }

  bool _ajouterLivraisonsNouvelles(List<CommandeResponse> livraisons) {
    final nouvelles = livraisons
        .where((livraison) => !_livraisonsConnues.contains(livraison.id))
        .toList();
    final initialisation = !_livraisonsInitialisees;
    _livraisonsConnues.addAll(livraisons.map((livraison) => livraison.id));
    _livraisonsInitialisees = true;
    if (initialisation) return false;
    for (final livraison in nouvelles) {
      _enregistrerNotification(
        NotificationMaliMall(
          id: 'livraison-${livraison.id}',
          message: 'Nouvelle livraison Market disponible (#${livraison.id}).',
          type: TypeNotification.nouvelleLivraison,
        ),
      );
    }
    return nouvelles.isNotEmpty;
  }

  bool _actualiserAvancementCommandes(List<CommandeResponse> commandes) {
    var nouvelles = false;
    for (final commande in commandes) {
      final statut = _statutSuivi(commande);
      final precedent = _statutsCommandesAcheteur[commande.id];
      _statutsCommandesAcheteur[commande.id] = statut;
      if (precedent == null || precedent == statut) continue;

      final (cle, message) = switch (statut) {
        'assignee' => (
            'chauffeur-assigne',
            'Un chauffeur a accepté la livraison de votre commande #${commande.id}.',
          ),
        'recuperee' => (
            'colis-recupere',
            'Le colis de votre commande #${commande.id} a été récupéré chez le vendeur. Le chauffeur se prépare à partir.',
          ),
        'en-route' => (
            'colis-en-route',
            'Le colis de votre commande #${commande.id} est en route vers vous.',
          ),
        'livree' => (
            'livraison-confirmee',
            'La livraison de votre commande #${commande.id} est confirmée.',
          ),
        'annulee' => (
            'commande-annulee',
            'Votre commande #${commande.id} a été annulée.',
          ),
        _ => (null, null),
      };
      if (cle == null || message == null) continue;
      final messageFinal = statut == 'livree' && commande.retraitParClient
          ? 'Le vendeur a confirmé le retrait de votre commande #${commande.id}.'
          : message;
      _enregistrerNotification(
        NotificationMaliMall(
          id: 'suivi-${commande.id}-$cle',
          message: messageFinal,
          type: TypeNotification.avancementCommande,
          commandeId: commande.id,
        ),
      );
      nouvelles = true;
    }
    return nouvelles;
  }

  String _statutSuivi(CommandeResponse commande) {
    if (commande.statut == StatutCommande.annulee) return 'annulee';
    if (commande.statut == StatutCommande.livree) return 'livree';
    return switch (commande.statutLivraison) {
      StatutLivraison.assignee => 'assignee',
      StatutLivraison.recuperee => 'recuperee',
      StatutLivraison.enRoute => 'en-route',
      StatutLivraison.livree => 'livree',
      null => 'en-attente',
    };
  }

  void _reinitialiserReferences() {
    _commandesInitialisees = false;
    _coursesInitialisees = false;
    _livraisonsInitialisees = false;
    _commandesConnues.clear();
    _statutsCommandesAcheteur.clear();
    _coursesConnues.clear();
    _livraisonsConnues.clear();
  }

  void _enregistrerNotification(NotificationMaliMall notification) {
    _notifications.insert(0, notification);
    _notificationsNonLues.add(notification.id);
    if (_notifications.length > 50) {
      final ancienne = _notifications.removeLast();
      _notificationsNonLues.remove(ancienne.id);
    }
  }

  @override
  void dispose() {
    _estDispose = true;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _session?.removeListener(_synchroniser);
    _timer?.cancel();
    super.dispose();
  }
}
