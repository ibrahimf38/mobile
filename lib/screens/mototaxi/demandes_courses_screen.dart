import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/localisation.dart';
import '../../core/models/course_models.dart';
import '../../core/services/course_service.dart';
import '../../core/services/livreur_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/state_views.dart';
import 'course_chauffeur_screen.dart';

/// Maquette 22 — demandes de courses reçues par le chauffeur (en ligne),
/// rafraîchies toutes les 8 s. "Refuser" masque la demande pour ce
/// chauffeur ; "Accepter" l'assigne et ouvre la course (maquette 23).
class DemandesCoursesScreen extends StatefulWidget {
  const DemandesCoursesScreen({super.key});

  @override
  State<DemandesCoursesScreen> createState() => _DemandesCoursesScreenState();
}

class _DemandesCoursesScreenState extends State<DemandesCoursesScreen> {
  List<CourseResponse>? _courses;
  bool? _enLigne;
  String? _erreur;
  int? _enCours;
  final Set<int> _refusees = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(
        const Duration(seconds: 8), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    try {
      final resume = await context.read<LivreurService>().resume();
      if (!mounted) return;
      final courses = resume.disponible
          ? await context.read<CourseService>().disponibles()
          : <CourseResponse>[];
      if (!mounted) return;
      setState(() {
        _enLigne = resume.disponible;
        _courses = courses;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted || silencieux) return;
      setState(() => _erreur = messageErreur(e));
    }
  }

  Future<void> _basculer(bool valeur) async {
    try {
      final partage = context.read<PartagePosition>();
      await context.read<LivreurService>().changerDisponibilite(valeur);
      if (valeur) {
        await partage.demarrer();
      } else {
        partage.arreter();
      }
      await _charger();
    } catch (e) {
      if (mounted) AppFeedback.error(context, messageErreur(e));
    }
  }

  Future<void> _accepter(CourseResponse c) async {
    setState(() => _enCours = c.id);
    try {
      await context.read<CourseService>().accepter(c.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CourseChauffeurScreen(courseId: c.id)));
    } catch (e) {
      if (mounted) AppFeedback.error(context, messageErreur(e));
    } finally {
      if (mounted) {
        setState(() => _enCours = null);
        await _charger(silencieux: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses?.where((c) => !_refusees.contains(c.id)).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Demandes de courses'),
      body: courses == null
          ? (_erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : const LoadingView())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: [
                  CarteListe(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_enLigne == true ? 'En ligne' : 'Hors ligne',
                                  style: AppTextStyles.bodyBoldL()),
                              Text(
                                _enLigne == true
                                    ? 'Vous recevez des courses'
                                    : 'Passez en ligne pour recevoir des courses',
                                style: AppTextStyles.caption(),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enLigne ?? false,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.accentBleu,
                          onChanged: _basculer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (courses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: EmptyView(
                        message: _enLigne == true
                            ? 'Aucune demande pour le moment.'
                            : 'Vous êtes hors ligne.',
                        icone: Icons.two_wheeler,
                      ),
                    ),
                  for (final c in courses) ...[
                    _CarteDemande(
                      course: c,
                      enCours: _enCours == c.id,
                      onRefuser: () => setState(() => _refusees.add(c.id)),
                      onAccepter: _enCours == null ? () => _accepter(c) : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final CourseResponse course;
  final bool enCours;
  final VoidCallback onRefuser;
  final VoidCallback? onAccepter;
  const _CarteDemande(
      {required this.course,
      required this.enCours,
      required this.onRefuser,
      required this.onAccepter});

  @override
  Widget build(BuildContext context) {
    final c = course;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Pastille(
              texte: 'Nouvelle course', couleur: AppColors.accentBleu),
          const SizedBox(height: 12),
          _Point(couleur: AppColors.accentBleu, texte: c.depart),
          Padding(
            padding: const EdgeInsets.only(left: 3.5),
            child: Container(width: 1, height: 14, color: AppColors.divider),
          ),
          _Point(couleur: AppColors.danger, texte: c.destination),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: Text('${c.distanceKm} km · ${c.clientNom}',
                      style: AppTextStyles.caption())),
              Text('${formatMmc(c.prixMmc)} MMC',
                  style: AppTextStyles.bodyBoldL(color: AppColors.accentBleu)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextButton(
                    onPressed: onRefuser,
                    style: TextButton.styleFrom(
                        backgroundColor: AppColors.surfaceL2,
                        shape: const StadiumBorder()),
                    child: Text('Refuser',
                        style: AppTextStyles.bodyBold(
                            color: AppColors.accentBleu)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: PrimaryButton(
                      label: 'Accepter',
                      enChargement: enCours,
                      onPressed: onAccepter)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final Color couleur;
  final String texte;
  const _Point({required this.couleur, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(texte, style: AppTextStyles.bodyMedium()),
      ],
    );
  }
}
