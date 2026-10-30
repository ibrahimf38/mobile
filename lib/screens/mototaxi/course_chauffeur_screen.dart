import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/localisation.dart';
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

/// Vue détaillée d'une course côté chauffeur. Le passager confirme la fin
/// après le signalement d'arrivée par le chauffeur.
class CourseChauffeurScreen extends StatefulWidget {
  final int courseId;
  const CourseChauffeurScreen({super.key, required this.courseId});

  @override
  State<CourseChauffeurScreen> createState() => _CourseChauffeurScreenState();
}

class _CourseChauffeurScreenState extends State<CourseChauffeurScreen> {
  CourseResponse? _course;
  String? _erreur;
  bool _envoi = false;
  Timer? _timer;
  bool _chargementEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _charger());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _charger() async {
    if (_chargementEnCours) return;
    _chargementEnCours = true;
    try {
      final c = await context.read<CourseService>().obtenir(widget.courseId);
      if (!mounted) return;
      if (c.statut == StatutCourse.terminee ||
          c.statut == StatutCourse.annulee) {
        _timer?.cancel();
      } else if (c.statut == StatutCourse.acceptee ||
          c.statut == StatutCourse.enCours ||
          c.statut == StatutCourse.arrivee) {
        context.read<PartagePosition>().demarrer();
      }
      setState(() => _course = c);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      _chargementEnCours = false;
    }
  }

  Future<void> _avancerCourse() async {
    setState(() => _envoi = true);
    try {
      final service = context.read<CourseService>();
      final c = _course!;
      final maj = c.statut == StatutCourse.acceptee
          ? await service.prendreEnCharge(widget.courseId)
          : await service.signalerArrivee(widget.courseId);
      if (!mounted) return;
      setState(() => _course = maj);
      AppFeedback.success(
        context,
        maj.statut == StatutCourse.enCours
            ? 'Passager pris en charge.'
            : 'Arrivée signalée. En attente de la confirmation du passager.',
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, messageErreur(e));
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CarteMaliMall(
              marges: const EdgeInsets.only(top: 60, bottom: 170),
              reperes: [
                RepereCarte(
                  id: 'depart',
                  position: depart,
                  teinte: BitmapDescriptor.hueAzure,
                  titre: c.depart,
                  detail: 'Prise en charge de ${c.clientNom}',
                ),
                RepereCarte(
                    id: 'destination',
                    position: arrivee,
                    teinte: BitmapDescriptor.hueRed,
                    titre: c.destination),
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
                  Expanded(
                      child:
                          Center(child: PiluleCarte('Vers ${c.destination}'))),
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
                      const AvatarIcone(icone: Icons.person_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.clientNom, style: AppTextStyles.bodyBold()),
                            Text('Client · ${c.depart} → ${c.destination}',
                                style: AppTextStyles.caption()),
                          ],
                        ),
                      ),
                      PiluleInfo('${minutesEstimees(c.distanceKm)} min'),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      BoutonTelephone(telephone: c.clientTelephone),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: switch (c.statut) {
                            StatutCourse.acceptee => 'Passager récupéré',
                            StatutCourse.enCours => 'Signaler l’arrivée',
                            StatutCourse.arrivee => 'En attente du passager',
                            StatutCourse.terminee => 'Course confirmée',
                            StatutCourse.demandee => 'En attente',
                            StatutCourse.annulee => 'Course annulée',
                          },
                          enChargement: _envoi,
                          onPressed: c.statut == StatutCourse.acceptee ||
                                  c.statut == StatutCourse.enCours
                              ? _avancerCourse
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
