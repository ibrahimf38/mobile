import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/localisation.dart';
import '../../core/models/course_models.dart';
import '../../core/quartiers.dart';
import '../../core/services/course_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/bouton_rond.dart';
import '../../widgets/carte_malimall.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/primary_button.dart';
import 'course_en_cours_screen.dart';

/// Maquette 14 — choix du départ et de la destination (quartiers de
/// Bamako), estimation distance/prix par le backend, puis confirmation.
/// Le prix est réservé sur le portefeuille jusqu'à la fin de la course.
class DemanderCourseScreen extends StatefulWidget {
  const DemanderCourseScreen({super.key});

  @override
  State<DemanderCourseScreen> createState() => _DemanderCourseScreenState();
}

class _DemanderCourseScreenState extends State<DemanderCourseScreen> {
  List<String> _quartiers = quartiersConnus;
  String? _depart;
  String? _destination;
  EstimationCourse? _estimation;
  bool _estimationEnCours = false;
  bool _envoi = false;
  String? _erreur;

  /// Catégorie de véhicule choisie — détermine le tarif par palier (voir
  /// QuartiersBamako côté backend) : Scooter/Telimani = 1000/2000/3000 f,
  /// TriCycle = 2500/5000/7500 f selon la distance (≤3km / ≤6km / >6km).
  TypeVehicule _typeVehicule = TypeVehicule.telimani;

  @override
  void initState() {
    super.initState();
    context.read<CourseService>().quartiers().then((q) {
      if (mounted && q.isNotEmpty) setState(() => _quartiers = q);
    }).catchError((_) {});
    // Le départ n'est plus un choix manuel : c'est toujours l'endroit où le
    // client se trouve actuellement (comme dans un vrai service de VTC/moto-
    // taxi — et comme le vrai MaliMall). positionRapide() combine deux API
    // GPS : la dernière position connue (réseau/cache, quasi instantanée)
    // pour ne pas laisser l'écran vide, puis affine avec la position GPS
    // précise dès qu'elle arrive — et continue de suivre le client si sa
    // position se précise encore après.
    Localisation.positionRapide(
      onPositionPrecise: (p) {
        if (!mounted) return;
        final quartierPrecis = quartierLePlusProche(p);
        if (_depart == quartierPrecis) return;
        setState(() => _depart = quartierPrecis);
        _estimer();
      },
    ).then((p) {
      if (!mounted || p == null) return;
      setState(() => _depart = quartierLePlusProche(p));
      _estimer();
    });
  }

  Future<void> _choisirDestination() async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceL1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('Destination', style: AppTextStyles.headingM()),
            ),
            for (final q in _quartiers)
              ListTile(
                leading: const Icon(Icons.place, size: 18, color: AppColors.accentOrange),
                title: Text(q, style: AppTextStyles.bodyDefault()),
                onTap: () => Navigator.of(ctx).pop(q),
              ),
          ],
        ),
      ),
    );
    if (choix == null) return;
    setState(() {
      _destination = choix;
      _estimation = null;
      _erreur = null;
    });
    await _estimer();
  }

  /// Touche directement une zone de la carte pour indiquer la destination
  /// (comme dans le vrai MaliMall — request_ride_screen.dart) : on résout le
  /// quartier connu le plus proche du point touché, notre backend ne
  /// travaillant qu'avec des quartiers (pas de géocodage réel, tout reste en
  /// simulation, comme demandé).
  Future<void> _choisirSurCarte(LatLng point) async {
    final quartier = quartierLePlusProche(point);
    setState(() {
      _destination = quartier;
      _estimation = null;
      _erreur = null;
    });
    await _estimer();
  }

  void _choisirTypeVehicule(TypeVehicule type) {
    if (type == _typeVehicule) return;
    setState(() {
      _typeVehicule = type;
      _estimation = null;
    });
    _estimer();
  }

  Future<void> _estimer() async {
    final d = _depart, a = _destination;
    if (d == null || a == null) return;
    if (d == a) {
      setState(() => _erreur = 'Le départ et la destination doivent être différents.');
      return;
    }
    setState(() => _estimationEnCours = true);
    try {
      final e = await context.read<CourseService>().estimer(d, a, _typeVehicule);
      if (mounted) setState(() => _estimation = e);
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _estimationEnCours = false);
    }
  }

  Future<void> _confirmer() async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final course = await context.read<CourseService>().demander(_depart!, _destination!, _typeVehicule);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CourseEnCoursScreen(courseId: course.id)),
      );
    } catch (e) {
      if (mounted) setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _estimation;
    final posDepart = coordQuartier(_depart);
    final posArrivee = coordQuartier(_destination);
    // Carte plein écran (comme l'accueil MotoTaxi et l'écran chauffeur) au
    // lieu d'un simple morceau de carte : le panneau de sélection flotte
    // par-dessus plutôt que de partager l'écran avec elle.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CarteMaliMall(
              marges: const EdgeInsets.only(top: 100, bottom: 260),
              afficherMaPosition: true,
              onTap: _choisirSurCarte,
              reperes: [
                if (posDepart != null)
                  RepereCarte(
                    id: 'depart',
                    position: posDepart,
                    teinte: BitmapDescriptor.hueAzure,
                    titre: _depart!,
                    detail: 'Point de départ',
                  ),
                if (posArrivee != null)
                  RepereCarte(
                    id: 'destination',
                    position: posArrivee,
                    teinte: BitmapDescriptor.hueOrange,
                    titre: _destination!,
                    detail: 'Destination',
                  ),
              ],
              trajet: posDepart != null && posArrivee != null ? (posDepart, posArrivee) : null,
              itineraire: e?.itineraire != null ? decodeGooglePolyline(e!.itineraire!) : null,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  BoutonRond.retour(context),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Center(
                      child: PiluleCarte(
                        _destination == null ? 'Touchez la carte pour choisir la destination' : 'Destination choisie',
                        icone: _destination == null ? Icons.touch_app_outlined : Icons.check_circle_outline,
                      ),
                    ),
                  ),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AffichageDepart(valeur: _depart),
                  const SizedBox(height: 8),
                  _Selecteur(
                    couleur: AppColors.accentOrange,
                    libelle: 'Destination',
                    valeur: _destination,
                    onTap: _choisirDestination,
                  ),
                  const SizedBox(height: 10),
                  _SelecteurTypeVehicule(
                    valeur: _typeVehicule,
                    onChange: _choisirTypeVehicule,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surfaceL2, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Distance', style: AppTextStyles.caption()),
                              const SizedBox(height: 2),
                              Text(e == null ? '—' : '${e.distanceKm} km', style: AppTextStyles.bodyBoldL()),
                            ],
                          ),
                        ),
                        if (_estimationEnCours)
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Prix estimé', style: AppTextStyles.caption()),
                              const SizedBox(height: 2),
                              Text(
                                e == null
                                    ? '—'
                                    : '${formatMmc(e.prixMmc)} MMC · ≈ ${formatMmc(equivalentFcfa(e.prixMmc))} FCFA',
                                style: AppTextStyles.bodyBoldL(color: AppColors.accentBleu),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 8),
                    Text(_erreur!, style: AppTextStyles.bodyMedium(color: AppColors.danger), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Confirmer la course',
                    enChargement: _envoi,
                    onPressed: e == null ? null : _confirmer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Point de départ = position actuelle du client, non modifiable (voir
/// initState) — affichage seul, sans chevron ni tap, pour bien montrer que
/// ce n'est pas un choix mais une détection automatique.
class _AffichageDepart extends StatelessWidget {
  final String? valeur;
  const _AffichageDepart({required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.accentBleu, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: valeur == null
                ? Text('Localisation en cours…', style: AppTextStyles.bodyDefault(color: AppColors.textSecondary))
                : Text.rich(
                    TextSpan(
                      text: valeur,
                      style: AppTextStyles.bodyBold(),
                      children: [TextSpan(text: '  Votre position actuelle', style: AppTextStyles.caption())],
                    ),
                  ),
          ),
          const Icon(Icons.gps_fixed, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _Selecteur extends StatelessWidget {
  final Color couleur;
  final String libelle;
  final String? valeur;
  final VoidCallback onTap;
  const _Selecteur({required this.couleur, required this.libelle, required this.valeur, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceL1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(width: 9, height: 9, decoration: BoxDecoration(color: couleur, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: valeur == null
                    ? Text(libelle, style: AppTextStyles.bodyDefault(color: AppColors.textSecondary))
                    : Text.rich(
                        TextSpan(
                          text: valeur,
                          style: AppTextStyles.bodyBold(),
                          children: [TextSpan(text: '  $libelle', style: AppTextStyles.caption())],
                        ),
                      ),
              ),
              const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choix de la catégorie de véhicule (Scooter / Telimani / TriCycle) — le
/// tarif par palier et les chauffeurs à qui la demande est visible en
/// dépendent (voir QuartiersBamako côté backend).
class _SelecteurTypeVehicule extends StatelessWidget {
  final TypeVehicule valeur;
  final ValueChanged<TypeVehicule> onChange;
  const _SelecteurTypeVehicule({required this.valeur, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in TypeVehicule.values) ...[
          Expanded(child: _optionType(type)),
          if (type != TypeVehicule.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _optionType(TypeVehicule type) {
    final selectionne = type == valeur;
    return Material(
      color: selectionne ? AppColors.accentBleu.withValues(alpha: 0.14) : AppColors.surfaceL1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChange(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selectionne ? AppColors.accentBleu : Colors.transparent, width: 1.4),
          ),
          child: Column(
            children: [
              Icon(type.icone, size: 20, color: selectionne ? AppColors.accentBleu : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                type.libelle,
                style: AppTextStyles.caption(color: selectionne ? AppColors.accentBleu : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
