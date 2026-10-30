import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/localisation.dart';
import '../../core/models/course_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/course_service.dart';
import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/bouton_rond.dart';
import '../../widgets/carte_malimall.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/primary_button.dart';
import '../chauffeur/devenir_chauffeur_screen.dart';
import '../chauffeur/espace_livreur_screen.dart';
import 'course_en_cours_screen.dart';
import 'demander_course_screen.dart';
import 'historique_courses_screen.dart';

/// Maquette 06 — accueil MotoTaxi : carte Google Maps avec ma position et
/// les chauffeurs en ligne qui partagent la leur, chauffeur le plus proche
/// et bouton "Demander une course". Si une course est en cours, un bandeau
/// permet d'y revenir.
class MotoTaxiScreen extends StatefulWidget {
  const MotoTaxiScreen({super.key});

  @override
  State<MotoTaxiScreen> createState() => _MotoTaxiScreenState();
}

class _MotoTaxiScreenState extends State<MotoTaxiScreen> {
  List<ChauffeurDisponible>? _chauffeurs;
  CourseResponse? _enCours;
  LatLng? _moi;
  bool _afficherProches = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final service = context.read<CourseService>();
    Localisation.positionActuelle().then((p) {
      if (mounted && p != null) setState(() => _moi = p);
    });
    try {
      final chauffeurs = await service.chauffeursDisponibles();
      final courses = await service.mesCourses();
      if (!mounted) return;
      setState(() {
        _chauffeurs = chauffeurs;
        _enCours = courses.where((c) => c.enCours).firstOrNull;
      });
    } catch (_) {
      // Carte affichée quand même : la liste se recharge au prochain retour.
      if (mounted) setState(() => _chauffeurs ??= []);
    }
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));
    if (mounted) await _charger();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final chauffeurs = _chauffeurs;
    final moi = _moi;
    double? distance(ChauffeurDisponible c) {
      final p = c.position;
      return (p == null || moi == null)
          ? null
          : distanceKmGps(moi, LatLng(p.latitude, p.longitude));
    }

    // Le plus proche si on connaît les positions, sinon le mieux noté.
    final meilleur = (chauffeurs == null || chauffeurs.isEmpty)
        ? null
        : (chauffeurs.toList()
              ..sort((a, b) {
                final da = distance(a), db = distance(b);
                if (da != null && db != null) return da.compareTo(db);
                if (da != null) return -1;
                if (db != null) return 1;
                return b.noteMoyenne.compareTo(a.noteMoyenne);
              }))
            .first;
    final distanceMeilleur = meilleur == null ? null : distance(meilleur);
    final enCours = _enCours;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CarteMaliMall(
              marges: const EdgeInsets.only(top: 60, bottom: 170),
              reperes: [
                for (final c in chauffeurs ?? const <ChauffeurDisponible>[])
                  if (c.position != null)
                    RepereCarte(
                      id: 'chauffeur-${c.chauffeurId}',
                      position:
                          LatLng(c.position!.latitude, c.position!.longitude),
                      teinte: BitmapDescriptor.hueAzure,
                      titre: c.nom,
                      detail:
                          '${_vehicule(c.vehiculeType)} · ★ ${c.noteMoyenne.toStringAsFixed(1)}',
                    ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const PiluleCarte('MotoTaxi'),
                  const Spacer(),
                  BoutonRond(
                    icone: Icons.people_alt_outlined,
                    onTap: () =>
                        setState(() => _afficherProches = !_afficherProches),
                  ),
                  const SizedBox(width: 8),
                  // Un vendeur qui n'est pas déjà livreur ne voit pas la
                  // proposition "Devenir livreur" (rôles exclusifs, cf. Compte).
                  if (!session.estVendeur || session.estChauffeur) ...[
                    BoutonRond(
                      icone: Icons.two_wheeler,
                      onTap: () => _ouvrir(
                        session.estChauffeur
                            ? const EspaceLivreurScreen()
                            : const DevenirChauffeurScreen(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  BoutonRond(
                      icone: Icons.schedule,
                      onTap: () => _ouvrir(const HistoriqueCoursesScreen())),
                ],
              ),
            ),
          ),
          if (_afficherProches)
            Positioned(
              left: 16,
              right: 16,
              top: 70,
              bottom: 170,
              child: _PanneauLivreursProches(
                chauffeurs: chauffeurs ?? const [],
                distance: distance,
                onFermer: () => setState(() => _afficherProches = false),
                onChoisir: (_) {
                  setState(() => _afficherProches = false);
                  _ouvrir(const DemanderCourseScreen());
                },
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (enCours != null)
                    _CarteBlanche(
                      onTap: () =>
                          _ouvrir(CourseEnCoursScreen(courseId: enCours.id)),
                      child: Row(
                        children: [
                          const AvatarIcone(icone: Icons.navigation_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  switch (enCours.statut) {
                                    StatutCourse.demandee =>
                                      'Recherche de chauffeur…',
                                    StatutCourse.acceptee =>
                                      'Chauffeur en route vers vous',
                                    StatutCourse.enCours => 'Trajet en cours',
                                    StatutCourse.arrivee =>
                                      'Arrivée à confirmer',
                                    StatutCourse.terminee => 'Course terminée',
                                    StatutCourse.annulee => 'Course annulée',
                                  },
                                  style: AppTextStyles.bodyBold(),
                                ),
                                Text(
                                    '${enCours.depart} → ${enCours.destination}',
                                    style: AppTextStyles.caption()),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.iconDisabled),
                        ],
                      ),
                    )
                  else
                    _CarteBlanche(
                      child: Row(
                        children: [
                          const AvatarIcone(icone: Icons.two_wheeler),
                          const SizedBox(width: 12),
                          Expanded(
                            child: chauffeurs == null
                                ? Text('Recherche des chauffeurs…',
                                    style: AppTextStyles.bodyMedium(
                                        color: AppColors.textSecondary))
                                : meilleur == null
                                    ? Text(
                                        'Aucun chauffeur en ligne pour le moment',
                                        style: AppTextStyles.bodyMedium(
                                            color: AppColors.textSecondary))
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(meilleur.nom,
                                              style: AppTextStyles.bodyBold()),
                                          Text(
                                            '${_vehicule(meilleur.vehiculeType)} · ★ ${meilleur.noteMoyenne.toStringAsFixed(1)}',
                                            style: AppTextStyles.caption(),
                                          ),
                                        ],
                                      ),
                          ),
                          if (distanceMeilleur != null)
                            PiluleInfo('$distanceMeilleur km',
                                couleur: AppColors.accentBleu)
                          else if (chauffeurs != null && chauffeurs.isNotEmpty)
                            PiluleInfo('${chauffeurs.length} en ligne',
                                couleur: AppColors.accentBleu),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  if (enCours == null)
                    PrimaryButton(
                        label: 'Demander une course',
                        onPressed: () => _ouvrir(const DemanderCourseScreen())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _vehicule(String? type) {
  if (type == null || type.isEmpty) return 'Moto';
  return type == 'TRICYCLE'
      ? 'TriCycle'
      : type[0] + type.substring(1).toLowerCase();
}

/// Panneau "Livreurs à proximité" — triés du plus proche au plus loin (ceux
/// sans position connue en dernier), même esprit que le panneau équivalent
/// de la vraie app MaliMall Flutter (mototaxi_home_screen.dart).
class _PanneauLivreursProches extends StatelessWidget {
  final List<ChauffeurDisponible> chauffeurs;
  final double? Function(ChauffeurDisponible) distance;
  final VoidCallback onFermer;
  final ValueChanged<ChauffeurDisponible> onChoisir;

  const _PanneauLivreursProches({
    required this.chauffeurs,
    required this.distance,
    required this.onFermer,
    required this.onChoisir,
  });

  @override
  Widget build(BuildContext context) {
    final tries = [...chauffeurs]..sort((a, b) {
        final da = distance(a) ?? double.infinity;
        final db = distance(b) ?? double.infinity;
        return da.compareTo(db);
      });
    return Material(
      color: AppColors.surfaceL1,
      borderRadius: BorderRadius.circular(18),
      elevation: 6,
      shadowColor: Colors.black38,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                    child: Text('Livreurs à proximité',
                        style: AppTextStyles.bodyBold())),
                InkWell(
                  onTap: onFermer,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: tries.isEmpty
                ? Center(
                    child: Text('Aucun livreur en ligne pour le moment.',
                        style: AppTextStyles.bodyDefault(
                            color: AppColors.textSecondary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: tries.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 58, color: AppColors.divider),
                    itemBuilder: (context, i) {
                      final c = tries[i];
                      final d = distance(c);
                      return InkWell(
                        onTap: () => onChoisir(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.accentOrange
                                      .withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.two_wheeler,
                                    color: AppColors.accentOrange, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.nom,
                                        style: AppTextStyles.bodyBold()
                                            .copyWith(fontSize: 12.5)),
                                    Text(
                                        '${_vehicule(c.vehiculeType)} · ★ ${c.noteMoyenne.toStringAsFixed(1)}',
                                        style: AppTextStyles.caption()),
                                  ],
                                ),
                              ),
                              if (d != null)
                                PiluleInfo('${d.toStringAsFixed(1)} km',
                                    couleur: AppColors.accentBleu),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CarteBlanche extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CarteBlanche({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceL1,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    );
  }
}
