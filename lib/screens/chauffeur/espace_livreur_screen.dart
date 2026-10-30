import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/localisation.dart';
import '../../core/models/commande_models.dart';
import '../../core/models/course_models.dart';
import '../../core/models/livreur_models.dart';
import '../../core/services/commande_service.dart';
import '../../core/services/course_service.dart';
import '../../core/services/livreur_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/state_views.dart';
import '../mototaxi/course_chauffeur_screen.dart';
import '../mototaxi/demandes_courses_screen.dart';
import '../wallet/portefeuille_screen.dart';
import 'historique_livreur_screen.dart';
import 'livraison_en_cours_screen.dart';
import 'livraisons_disponibles_screen.dart';

/// Maquette 18 — tableau de bord du livreur : disponibilité, demandes en
/// attente (courses passagers / livraisons Market), chiffres clés et
/// raccourcis. Affiche en tête la livraison ou la course en cours s'il y en a.
class EspaceLivreurScreen extends StatefulWidget {
  const EspaceLivreurScreen({super.key});

  @override
  State<EspaceLivreurScreen> createState() => _EspaceLivreurScreenState();
}

class _EspaceLivreurScreenState extends State<EspaceLivreurScreen> {
  EspaceLivreurResponse? _resume;
  CommandeResponse? _livraisonEnCours;
  CourseResponse? _courseEnCours;
  String? _erreur;
  bool _bascule = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final resume = await context.read<LivreurService>().resume();
      if (!mounted) return;
      final livraisons =
          await context.read<CommandeService>().mesCommandes(role: 'chauffeur');
      if (!mounted) return;
      final courses =
          await context.read<CourseService>().mesCourses(role: 'chauffeur');
      if (!mounted) return;
      _synchroniserPartage(resume.disponible);
      setState(() {
        _resume = resume;
        _livraisonEnCours = livraisons
            .where((c) =>
                c.statut != StatutCommande.livree &&
                c.statut != StatutCommande.annulee)
            .firstOrNull;
        _courseEnCours = courses
            .where((c) =>
                c.statut == StatutCourse.acceptee ||
                c.statut == StatutCourse.enCours ||
                c.statut == StatutCourse.arrivee)
            .firstOrNull;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    }
  }

  Future<void> _changerDisponibilite(bool valeur) async {
    setState(() => _bascule = true);
    try {
      final r =
          await context.read<LivreurService>().changerDisponibilite(valeur);
      if (!mounted) return;
      _synchroniserPartage(r.disponible);
      setState(() => _resume = r);
    } catch (e) {
      if (mounted) {
        AppFeedback.error(context, messageErreur(e));
      }
    } finally {
      if (mounted) setState(() => _bascule = false);
    }
  }

  /// En ligne : la position est partagée pour que les clients voient le livreur.
  void _synchroniserPartage(bool disponible) {
    final partage = context.read<PartagePosition>();
    if (disponible) {
      partage.demarrer();
    } else {
      partage.arreter();
    }
  }

  Future<void> _ouvrir(Widget ecran) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ecran));
    if (mounted) await _charger();
  }

  void _monVehicule(EspaceLivreurResponse r) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceL1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mon véhicule', style: AppTextStyles.headingM()),
            const SizedBox(height: 14),
            _ligne('Type', r.vehiculeLibelle),
            _ligne('Immatriculation', r.immatriculation ?? '—'),
            _ligne('Capacité', r.capaciteLibelle),
          ],
        ),
      ),
    );
  }

  Widget _ligne(String libelle, String valeur) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
                width: 120,
                child: Text(libelle, style: AppTextStyles.caption())),
            Expanded(child: Text(valeur, style: AppTextStyles.bodyMedium())),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = _resume;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Espace livreur'),
      body: r == null
          ? (_erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : const LoadingView())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: [
                  CarteListe(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.disponible ? 'Disponible' : 'Hors ligne',
                                  style: AppTextStyles.bodyBoldL()),
                              const SizedBox(height: 3),
                              Text(
                                r.disponible
                                    ? 'Vous recevez des demandes de courses et de livraisons'
                                    : 'Activez pour recevoir des demandes',
                                style: AppTextStyles.caption(),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: r.disponible,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.accentBleu,
                          onChanged: _bascule ? null : _changerDisponibilite,
                        ),
                      ],
                    ),
                  ),
                  if (_livraisonEnCours != null) ...[
                    const SizedBox(height: 12),
                    _BandeauEnCours(
                      titre: 'Livraison en cours',
                      detail:
                          '${_livraisonEnCours!.boutiqueNom} · ${_livraisonEnCours!.resumeArticles}',
                      onTap: () => _ouvrir(LivraisonEnCoursScreen(
                          commandeId: _livraisonEnCours!.id)),
                    ),
                  ],
                  if (_courseEnCours != null) ...[
                    const SizedBox(height: 12),
                    _BandeauEnCours(
                      titre: 'Course en cours',
                      detail:
                          '${_courseEnCours!.depart} → ${_courseEnCours!.destination}',
                      onTap: () => _ouvrir(
                          CourseChauffeurScreen(courseId: _courseEnCours!.id)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (r.transportePassagers) ...[
                        Expanded(
                          child: _TuileFile(
                            icone: Icons.person_outline,
                            titre: 'Courses passagers',
                            sousTitre: 'MotoTaxi',
                            attente: r.coursesEnAttente,
                            onTap: () => _ouvrir(const DemandesCoursesScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: _TuileFile(
                          icone: Icons.shopping_bag_outlined,
                          titre: 'Livraisons Market',
                          sousTitre: 'Colis à récupérer',
                          attente: r.livraisonsEnAttente,
                          onTap: () =>
                              _ouvrir(const LivraisonsDisponiblesScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TuileChiffre(
                          valeur: '${r.coursesEtLivraisonsTerminees}',
                          libelle: 'Courses'),
                      const SizedBox(width: 10),
                      TuileChiffre(
                          valeur: r.noteMoyenne.toStringAsFixed(1),
                          libelle: 'Note moy.'),
                      const SizedBox(width: 10),
                      TuileChiffre(
                          valeur: formatMmc(r.gainsMmc), libelle: 'MMC gagnés'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const TitreSection('Gérer'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: AppColors.surfaceL1,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _LigneGerer(
                          icone: Icons.two_wheeler,
                          titre: 'Mon véhicule',
                          detail: [
                            r.vehiculeLibelle,
                            r.immatriculation,
                            r.capaciteLibelle
                          ].whereType<String>().join(' · '),
                          onTap: () => _monVehicule(r),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _LigneGerer(
                          icone: Icons.schedule,
                          titre: 'Historique',
                          detail: 'Courses et livraisons',
                          onTap: () => _ouvrir(const HistoriqueLivreurScreen()),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _LigneGerer(
                          icone: Icons.credit_card,
                          titre: 'Retirer mes gains',
                          detail: 'Vers mon portefeuille',
                          onTap: () => _ouvrir(const PortefeuilleScreen()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _BandeauEnCours extends StatelessWidget {
  final String titre;
  final String detail;
  final VoidCallback onTap;
  const _BandeauEnCours(
      {required this.titre, required this.detail, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentBleu,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: AppTextStyles.bodyBold(color: Colors.white)),
                    Text(detail,
                        style: AppTextStyles.caption(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _TuileFile extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final int attente;
  final VoidCallback onTap;

  const _TuileFile({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.attente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CarteListe(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentBleu.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icone, size: 16, color: AppColors.accentBleu),
          ),
          const SizedBox(height: 14),
          Text(titre, style: AppTextStyles.bodyBold()),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(sousTitre, style: AppTextStyles.captionSmall()),
              if (attente > 0)
                Pastille(
                    texte: '$attente en attente',
                    couleur: AppColors.accentOrange),
            ],
          ),
        ],
      ),
    );
  }
}

class _LigneGerer extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;
  final VoidCallback onTap;
  const _LigneGerer(
      {required this.icone,
      required this.titre,
      required this.detail,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: AvatarIcone(icone: icone, taille: 32),
      title: Text(titre, style: AppTextStyles.bodyBold()),
      subtitle: Text(detail, style: AppTextStyles.caption()),
      trailing: const Icon(Icons.chevron_right, color: AppColors.iconDisabled),
    );
  }
}
