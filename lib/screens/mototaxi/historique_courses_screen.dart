import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/course_models.dart';
import '../../core/services/course_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/state_views.dart';
import 'course_en_cours_screen.dart';
import 'noter_chauffeur_screen.dart';

/// Maquette 17 — historique des courses du client.
class HistoriqueCoursesScreen extends StatefulWidget {
  const HistoriqueCoursesScreen({super.key});

  @override
  State<HistoriqueCoursesScreen> createState() =>
      _HistoriqueCoursesScreenState();
}

class _HistoriqueCoursesScreenState extends State<HistoriqueCoursesScreen> {
  List<CourseResponse>? _courses;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final courses = await context.read<CourseService>().mesCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses
          ..sort((a, b) => b.dateDemande.compareTo(a.dateDemande));
        _erreur = null;
      });
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    }
  }

  Future<void> _ouvrir(CourseResponse c) async {
    Widget? ecran;
    if (c.enCours) ecran = CourseEnCoursScreen(courseId: c.id);
    if (c.statut == StatutCourse.terminee && c.note == null) {
      ecran = NoterChauffeurScreen(course: c);
    }
    if (ecran == null) return;
    final cible = ecran;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => cible));
    if (mounted) await _charger();
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Historique'),
      body: courses == null
          ? (_erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : const LoadingView())
          : RefreshIndicator(
              onRefresh: _charger,
              child: courses.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      EmptyView(
                          message: 'Aucune course pour le moment.',
                          icone: Icons.two_wheeler),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                      itemCount: courses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = courses[i];
                        final annulee = c.statut == StatutCourse.annulee;
                        final (texte, couleur) = switch (c.statut) {
                          StatutCourse.terminee => (
                              'Terminée',
                              AppColors.statutTermineTexte
                            ),
                          StatutCourse.annulee => ('Annulée', AppColors.danger),
                          StatutCourse.acceptee || StatutCourse.enCours => (
                              'En cours',
                              AppColors.accentBleu
                            ),
                          StatutCourse.arrivee => (
                              'À confirmer',
                              AppColors.accentOrange
                            ),
                          StatutCourse.demandee => (
                              'En attente',
                              AppColors.accentOrange
                            ),
                        };
                        return CarteListe(
                          onTap: () => _ouvrir(c),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: annulee
                                      ? const Color(0xFFFDE3E6)
                                      : const Color(0xFFDCECFF),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  annulee ? Icons.close : Icons.place_outlined,
                                  size: 18,
                                  color: annulee
                                      ? AppColors.danger
                                      : AppColors.accentBleu,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${c.depart} → ${c.destination}',
                                        style: AppTextStyles.bodyBold()),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${dateRelative(c.dateDemande)} · ${annulee ? '—' : '${formatMmc(c.prixMmc)} MMC'}',
                                      style: AppTextStyles.caption(),
                                    ),
                                  ],
                                ),
                              ),
                              Pastille(texte: texte, couleur: couleur),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
