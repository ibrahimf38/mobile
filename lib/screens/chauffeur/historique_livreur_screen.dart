import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/models/commande_models.dart';
import '../../core/models/course_models.dart';
import '../../core/services/commande_service.dart';
import '../../core/services/course_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/state_views.dart';
import '../mototaxi/course_chauffeur_screen.dart';

enum _Filtre { tout, courses, livraisons }

class _Entree {
  final DateTime date;
  final bool estCourse;
  final String titre;
  final String detail;
  final int graine;
  final String? montant;
  final (String, Color)? statut;
  final int? courseId;
  const _Entree({
    required this.date,
    required this.estCourse,
    required this.titre,
    required this.detail,
    required this.graine,
    this.montant,
    this.statut,
    this.courseId,
  });
}

/// Maquette 36 — historique unifié du livreur : courses MotoTaxi et
/// livraisons Market, avec le montant net crédité.
class HistoriqueLivreurScreen extends StatefulWidget {
  const HistoriqueLivreurScreen({super.key});

  @override
  State<HistoriqueLivreurScreen> createState() =>
      _HistoriqueLivreurScreenState();
}

class _HistoriqueLivreurScreenState extends State<HistoriqueLivreurScreen> {
  List<_Entree>? _entrees;
  String? _erreur;
  _Filtre _filtre = _Filtre.tout;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final livraisons =
          await context.read<CommandeService>().mesCommandes(role: 'chauffeur');
      if (!mounted) return;
      final courses =
          await context.read<CourseService>().mesCourses(role: 'chauffeur');
      if (!mounted) return;
      final entrees = [
        for (final c in livraisons) _depuisLivraison(c),
        for (final c in courses) _depuisCourse(c),
      ]..sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _entrees = entrees;
        _erreur = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    }
  }

  _Entree _depuisLivraison(CommandeResponse c) {
    final date = c.dateLivraison ?? c.dateAssignation ?? c.dateCommande;
    (String, Color)? statut;
    String? montant;
    if (c.signalee) {
      statut = ('Signalée', AppColors.danger);
    } else if (c.statut == StatutCommande.livree) {
      montant = '+${formatMmc(netApresCommission(c.fraisLivraisonMmc))} MMC';
    } else if (c.statut == StatutCommande.annulee) {
      statut = ('Annulée', AppColors.danger);
    } else {
      statut = ('En cours', AppColors.accentBleu);
    }
    return _Entree(
      date: date,
      estCourse: false,
      titre: c.resumeArticles,
      detail:
          '${c.boutiqueNom} → ${c.acheteurNom ?? 'client'} · ${dateRelative(date)}',
      graine: c.id,
      montant: montant,
      statut: statut,
    );
  }

  _Entree _depuisCourse(CourseResponse c) {
    final date = c.dateFin ?? c.dateAcceptation ?? c.dateDemande;
    return _Entree(
      date: date,
      estCourse: true,
      titre: '${c.depart} → ${c.destination}',
      detail: '${c.clientNom} · ${dateRelative(date)}',
      graine: c.id,
      montant: c.statut == StatutCourse.terminee
          ? '+${formatMmc(netApresCommission(c.prixMmc))} MMC'
          : null,
      courseId: c.id,
      statut: switch (c.statut) {
        StatutCourse.annulee => ('Annulée', AppColors.danger),
        StatutCourse.terminee => null,
        StatutCourse.arrivee => ('À confirmer', AppColors.accentOrange),
        _ => ('En cours', AppColors.accentBleu),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final toutes = _entrees;
    final entrees = toutes
        ?.where((e) => switch (_filtre) {
              _Filtre.tout => true,
              _Filtre.courses => e.estCourse,
              _Filtre.livraisons => !e.estCourse,
            })
        .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Historique'),
      body: entrees == null
          ? (_erreur != null
              ? ErrorView(message: _erreur!, onReessayer: _charger)
              : const LoadingView())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: Row(
                    children: [
                      for (final (f, label) in [
                        (_Filtre.tout, 'Tout'),
                        (_Filtre.courses, 'Courses'),
                        (_Filtre.livraisons, 'Livraisons'),
                      ]) ...[
                        ChipFiltre(
                            label: label,
                            actif: _filtre == f,
                            onTap: () => setState(() => _filtre = f)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _charger,
                    child: entrees.isEmpty
                        ? ListView(children: const [
                            SizedBox(height: 120),
                            EmptyView(
                                message: 'Rien pour le moment.',
                                icone: Icons.history),
                          ])
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                            itemCount: entrees.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _Ligne(
                              entree: entrees[i],
                              onTap: entrees[i].courseId == null
                                  ? null
                                  : () async {
                                      await Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (_) => CourseChauffeurScreen(
                                            courseId: entrees[i].courseId!),
                                      ));
                                      if (mounted) await _charger();
                                    },
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final _Entree entree;
  final VoidCallback? onTap;
  const _Ligne({required this.entree, this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = entree;
    return CarteListe(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          e.estCourse
              ? Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDCECFF),
                      borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.place_outlined,
                      size: 18, color: AppColors.accentBleu),
                )
              : VignettePastel(graine: e.graine),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titre,
                    style: AppTextStyles.bodyBold(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(e.detail, style: AppTextStyles.caption(), maxLines: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Pastille(
                texte: e.estCourse ? 'COURSE' : 'LIVRAISON',
                couleur: AppColors.accentViolet,
                couleurTexte: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              if (e.montant != null)
                Pastille(
                    texte: e.montant!, couleur: AppColors.statutTermineTexte),
              if (e.statut != null)
                Pastille(texte: e.statut!.$1, couleur: e.statut!.$2),
            ],
          ),
        ],
      ),
    );
  }
}
