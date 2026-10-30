import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/course_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/course_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/bouton_rond.dart';
import '../../widgets/carte_malimall.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import 'noter_chauffeur_screen.dart';

/// Maquette 15 — côté client : recherche d'un chauffeur puis course en
/// cours (chauffeur, véhicule, prix). Rafraîchi toutes les 5 s ; à la fin
/// de la course, bascule sur la notation (maquette 16).
class CourseEnCoursScreen extends StatefulWidget {
  final int courseId;
  const CourseEnCoursScreen({super.key, required this.courseId});

  @override
  State<CourseEnCoursScreen> createState() => _CourseEnCoursScreenState();
}

class _CourseEnCoursScreenState extends State<CourseEnCoursScreen> {
  CourseResponse? _course;
  String? _erreur;
  Timer? _timer;
  bool _annulation = false;
  bool _confirmation = false;
  bool _chargementEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (_chargementEnCours) return;
    _chargementEnCours = true;
    try {
      final c = await context.read<CourseService>().obtenir(widget.courseId);
      if (!mounted) return;
      if (c.statut == StatutCourse.terminee) {
        _timer?.cancel();
        if (c.note == null) {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => NoterChauffeurScreen(course: c)),
          );
          return;
        }
      }
      if (c.statut == StatutCourse.annulee) _timer?.cancel();
      setState(() {
        _course = c;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted || silencieux) return;
      setState(() => _erreur = messageErreur(e));
    } finally {
      _chargementEnCours = false;
    }
  }

  Future<void> _annuler() async {
    setState(() => _annulation = true);
    try {
      await context.read<CourseService>().annuler(widget.courseId);
      if (!mounted) return;
      AppFeedback.success(
        context,
        'Course annulée : le montant réservé est libéré.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, messageErreur(e));
      }
    } finally {
      if (mounted) setState(() => _annulation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;
    if (c == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeaderBar(titre: 'Course'),
        body: _erreur != null
            ? ErrorView(message: _erreur!, onReessayer: _charger)
            : const LoadingView(),
      );
    }
    final depart = coordQuartier(c.depart) ?? centreBamako;
    final arrivee = coordQuartier(c.destination) ?? centreBamako;
    final pos = c.chauffeurPosition;
    final posChauffeur =
        pos == null ? null : LatLng(pos.latitude, pos.longitude);
    final cibleChauffeur = c.statut == StatutCourse.acceptee ? depart : arrivee;
    final kmChauffeur = posChauffeur == null
        ? null
        : distanceKmGps(posChauffeur, cibleChauffeur);
    final enAttente = c.statut == StatutCourse.demandee;
    final titrePilule = switch (c.statut) {
      StatutCourse.demandee => 'Recherche d\'un chauffeur…',
      StatutCourse.acceptee => 'Chauffeur en route vers vous',
      StatutCourse.enCours => 'Trajet en cours',
      StatutCourse.arrivee => 'Arrivée signalée',
      StatutCourse.terminee => 'Course terminée',
      StatutCourse.annulee => 'Course annulée',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CarteMaliMall(
              marges: const EdgeInsets.only(top: 60, bottom: 150),
              reperes: [
                RepereCarte(
                    id: 'depart',
                    position: depart,
                    teinte: BitmapDescriptor.hueAzure,
                    titre: c.depart),
                RepereCarte(
                    id: 'destination',
                    position: arrivee,
                    teinte: BitmapDescriptor.hueOrange,
                    titre: c.destination),
                if (posChauffeur != null)
                  RepereCarte(
                    id: 'chauffeur',
                    position: posChauffeur,
                    teinte: BitmapDescriptor.hueViolet,
                    titre: c.chauffeurNom ?? 'Chauffeur',
                    detail: 'Position en direct',
                  ),
              ],
              trajet: (depart, arrivee),
              itineraire: c.itineraire != null
                  ? decodeGooglePolyline(c.itineraire!)
                  : null,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  BoutonRond.retour(context),
                  Expanded(child: Center(child: PiluleCarte(titrePilule))),
                  const SizedBox(width: 34),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: PanneauBasCarte(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (c.chauffeurNom != null)
                        AvatarInitiales(nom: c.chauffeurNom!)
                      else
                        const AvatarIcone(icone: Icons.search),
                      const SizedBox(width: 12),
                      Expanded(
                        child: c.chauffeurNom == null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('En attente d\'un chauffeur',
                                      style: AppTextStyles.bodyBold()),
                                  Text('${c.depart} → ${c.destination}',
                                      style: AppTextStyles.caption()),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.chauffeurNom} ★ ${(c.chauffeurNote ?? 5).toStringAsFixed(1)}',
                                    style: AppTextStyles.bodyBold(),
                                  ),
                                  Text(
                                    [
                                      c.vehiculeLibelle ?? 'Moto',
                                      c.vehiculeImmatriculation
                                    ].whereType<String>().join(' · '),
                                    style: AppTextStyles.caption(),
                                  ),
                                ],
                              ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${formatMmc(c.prixMmc)} MMC',
                              style: AppTextStyles.bodyBold(
                                  color: AppColors.accentBleu)),
                          const SizedBox(height: 4),
                          PiluleInfo(
                            kmChauffeur != null
                                ? 'à $kmChauffeur km'
                                : '~${minutesEstimees(c.distanceKm)} min',
                          ),
                        ],
                      ),
                      if (c.chauffeurTelephone != null) ...[
                        const SizedBox(width: 8),
                        BoutonTelephone(telephone: c.chauffeurTelephone),
                      ],
                    ],
                  ),
                  if (c.statut == StatutCourse.arrivee) ...[
                    const Divider(height: 22),
                    Text(
                      'Le chauffeur a signalé son arrivée. Confirmez uniquement après être arrivé à destination.',
                      style: AppTextStyles.caption(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Confirmer l’arrivée',
                      enChargement: _confirmation,
                      onPressed: _confirmation ? null : _confirmerArrivee,
                    ),
                  ] else if (c.statut == StatutCourse.enCours) ...[
                    const Divider(height: 22),
                    Text('Vous êtes en route vers votre destination.',
                        style: AppTextStyles.caption()),
                  ] else if (enAttente) ...[
                    const Divider(height: 22),
                    const LinearProgressIndicator(minHeight: 3),
                    LienDiscret(
                        _annulation ? 'Annulation…' : 'Annuler la demande',
                        onTap: _annulation ? null : _annuler),
                  ] else
                    const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerArrivee() async {
    setState(() => _confirmation = true);
    try {
      final course =
          await context.read<CourseService>().confirmerArrivee(widget.courseId);
      if (!mounted) return;
      _timer?.cancel();
      if (course.note == null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => NoterChauffeurScreen(course: course)),
        );
      } else {
        setState(() => _course = course);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, messageErreur(e));
      }
    } finally {
      if (mounted) setState(() => _confirmation = false);
    }
  }
}
