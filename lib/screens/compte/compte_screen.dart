import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/auth_models.dart';
import '../../core/services/profil_service.dart';
import '../../state/notification_provider.dart';
import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/reseau_image.dart';
import '../../widgets/app_feedback.dart';
import '../auth/connexion_screen.dart';
import '../boutique/ma_boutique_screen.dart';
import '../boutique/publicites_screen.dart';
import '../chauffeur/devenir_chauffeur_screen.dart';
import '../chauffeur/espace_livreur_screen.dart';
import '../commandes/commandes_liste_screen.dart';
import 'notifications_screen.dart';
import '../wallet/portefeuille_screen.dart';
import 'parametres_screen.dart';

const _moisFr = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

/// "Depuis <mois> <année>" à partir d'une vraie date d'inscription — pas de
/// dépendance à `initializeDateFormatting` (locale intl), cohérent avec le
/// choix déjà fait ailleurs dans l'app (voir OrderCard) de rester en dates
/// formatées à la main plutôt que d'ajouter cette dépendance pour un seul écran.
String _depuisMoisAnnee(DateTime d) =>
    'Depuis ${_moisFr[d.month - 1]} ${d.year}';

class CompteScreen extends StatefulWidget {
  const CompteScreen({super.key});

  @override
  State<CompteScreen> createState() => _CompteScreenState();
}

class _CompteScreenState extends State<CompteScreen> {
  bool _uploadPhotoEnCours = false;

  Future<void> _deconnecter(BuildContext context) async {
    await context.read<SessionProvider>().deconnecter();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ConnexionScreen()),
      (route) => false,
    );
  }

  Future<void> _changerPhotoProfil() async {
    final fichier = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (!mounted) return;
    setState(() => _uploadPhotoEnCours = true);
    try {
      final url = await context
          .read<ProfilService>()
          .televerserPhoto(octets: octets, nomFichier: fichier.name);
      if (!mounted) return;
      context.read<SessionProvider>().mettreAJourPhotoProfil(url);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _uploadPhotoEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final notifications = context.watch<NotificationProvider>();
    final utilisateur = session.utilisateur;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _banniereHero(utilisateur)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _titreSection('Informations personnelles'),
                const SizedBox(height: 10),
                _panneauInformationsPersonnelles(utilisateur),
                const SizedBox(height: 24),
                _titreSection('Mes espaces'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    // Un vendeur qui n'est pas encore livreur ne voit pas la
                    // proposition "Devenir livreur", et inversement : les deux
                    // rôles restent exclusifs tant qu'on ne les a pas déjà
                    // tous les deux (l'espace de gestion reste alors visible).
                    if (!session.estChauffeur || session.estVendeur)
                      _EspaceTuile(
                        icone: Icons.shopping_basket_outlined,
                        couleur: AppColors.accentBleu,
                        label: 'Ma boutique',
                        badge: notifications
                            .nombreNonLues({TypeNotification.nouvelleCommande}),
                        onTap: () {
                          notifications
                              .marquerLues({TypeNotification.nouvelleCommande});
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const MaBoutiqueScreen()));
                        },
                      ),
                    if (!session.estVendeur || session.estChauffeur)
                      _EspaceTuile(
                        icone: Icons.two_wheeler,
                        couleur: AppColors.accentViolet,
                        label: session.estChauffeur
                            ? 'Espace livreur'
                            : 'Devenir livreur',
                        badge: session.estChauffeur
                            ? notifications.nombreNonLues({
                                TypeNotification.nouvelleCourse,
                                TypeNotification.nouvelleLivraison,
                              })
                            : 0,
                        onTap: () {
                          if (session.estChauffeur) {
                            notifications.marquerLues({
                              TypeNotification.nouvelleCourse,
                              TypeNotification.nouvelleLivraison,
                            });
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => session.estChauffeur
                                  ? const EspaceLivreurScreen()
                                  : const DevenirChauffeurScreen(),
                            ),
                          );
                        },
                      ),
                    if (session.estVendeur)
                      _EspaceTuile(
                        icone: Icons.campaign_outlined,
                        couleur: AppColors.accentOrange,
                        label: 'Publicité',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const PublicitesScreen())),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _titreSection('Général'),
                const SizedBox(height: 10),
                _panneauGeneral(context),
                const SizedBox(height: 18),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _deconnecter(context),
                    icon: const Icon(Icons.logout_rounded, size: 17),
                    label: Text('Se déconnecter',
                        style: AppTextStyles.bodyBold(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 13),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banniereHero(MoiResponse? utilisateur) {
    final nom = utilisateur?.nomComplet ?? '';
    final telephone = utilisateur?.telephone ?? '';
    final roles = context.watch<SessionProvider>().roles;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.accentBleu,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Text('Profil',
                style: AppTextStyles.titleAppBar(color: Colors.white)),
            const SizedBox(height: 14),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _uploadPhotoEnCours ? null : _changerPhotoProfil,
                customBorder: const CircleBorder(),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle),
                      child: _uploadPhotoEnCours
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : (utilisateur?.imageUrl != null &&
                                  utilisateur!.imageUrl!.isNotEmpty
                              ? ReseauImage(imageUrl: utilisateur.imageUrl)
                              : const Icon(Icons.person_outline,
                                  color: Colors.white, size: 38)),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                        border:
                            Border.all(color: AppColors.accentBleu, width: 2),
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          size: 11, color: AppColors.accentBleu),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(nom, style: AppTextStyles.headingL(color: Colors.white)),
            const SizedBox(height: 2),
            Text(telephone,
                style: AppTextStyles.bodyDefault(
                    color: Colors.white.withValues(alpha: 0.85))),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                if (utilisateur?.verifie == true)
                  _pilleInfo(Icons.check_rounded, 'Compte vérifié'),
                if (utilisateur != null)
                  _pilleInfo(Icons.event_outlined,
                      _depuisMoisAnnee(utilisateur.dateCreation)),
                ...roles.map((r) => _pilleRole(r)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pilleInfo(IconData icone, String texte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(texte, style: AppTextStyles.captionSmall(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _pilleRole(String role) {
    final libelle = switch (role) {
      'ROLE_CLIENT' => 'Acheteur',
      'ROLE_VENDEUR' => 'Vendeur',
      'ROLE_CHAUFFEUR' => 'Chauffeur',
      'ROLE_ADMIN' => 'Admin',
      _ => role,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20)),
      child:
          Text(libelle, style: AppTextStyles.captionSmall(color: Colors.white)),
    );
  }

  Widget _titreSection(String texte) => Text(texte.toUpperCase(),
      style: AppTextStyles.eyebrow(color: AppColors.textSecondary));

  Widget _panneauInformationsPersonnelles(MoiResponse? utilisateur) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _ligneInfo(
              icone: Icons.credit_card_outlined,
              label: 'Nom complet',
              valeur: utilisateur?.nomComplet ?? '—'),
          const Divider(height: 1, indent: 58, color: AppColors.divider),
          _ligneInfo(
            icone: Icons.phone_outlined,
            label: 'Téléphone',
            valeur: utilisateur?.telephone ?? '—',
            dernier: true,
          ),
        ],
      ),
    );
  }

  /// Lecture seule — aucun endpoint de modification de profil n'existe côté
  /// backend ce lot (téléphone = identifiant de connexion, nom non éditable),
  /// donc pas de chevron/tap ici pour ne pas suggérer une action inexistante.
  Widget _ligneInfo(
      {required IconData icone,
      required String label,
      required String valeur,
      bool dernier = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icone, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption()
                        .copyWith(fontWeight: FontWeight.w400)),
                const SizedBox(height: 3),
                Text(valeur, style: AppTextStyles.bodyBold()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panneauGeneral(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final nombreNotifications = notifications.nombreNonLues(
      TypeNotification.values.toSet(),
    );
    return Container(
      decoration: BoxDecoration(
          color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          _ligne(
            context,
            icone: Icons.notifications_none_rounded,
            label: 'Notifications',
            sousTitre: nombreNotifications == 0
                ? 'Commandes, courses et livraisons'
                : '$nombreNotifications notification(s) non lue(s)',
            badge: nombreNotifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          const Divider(height: 1, indent: 58, color: AppColors.divider),
          _ligne(
            context,
            icone: Icons.receipt_long_outlined,
            label: 'Mes commandes',
            sousTitre: 'Suivi de vos achats',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommandesListeScreen()),
            ),
          ),
          const Divider(height: 1, indent: 58, color: AppColors.divider),
          _ligne(
            context,
            icone: Icons.account_balance_wallet_outlined,
            label: 'Mon portefeuille',
            sousTitre: 'Solde, historique, recharge',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PortefeuilleScreen()),
            ),
          ),
          const Divider(height: 1, indent: 58, color: AppColors.divider),
          _ligne(
            context,
            icone: Icons.settings_outlined,
            label: 'Paramètres',
            sousTitre: 'Sécurité, langue, aide',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParametresScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligne(BuildContext context,
      {required IconData icone,
      required String label,
      required String sousTitre,
      int badge = 0,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: AppColors.accentBleu.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(icone, size: 16, color: AppColors.accentBleu),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyBold()),
                  const SizedBox(height: 3),
                  Text(sousTitre,
                      style: AppTextStyles.caption().copyWith(
                          fontSize: 10.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: AppTextStyles.captionSmall(color: Colors.white),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.iconDisabled),
          ],
        ),
      ),
    );
  }
}

class _EspaceTuile extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _EspaceTuile({
    required this.icone,
    required this.couleur,
    required this.label,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
            color: AppColors.surfaceL1,
            borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: couleur.withValues(alpha: 0.14),
                        shape: BoxShape.circle),
                    child: Icon(icone, size: 17, color: couleur),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.captionSmall(
                              color: AppColors.textPrimary)
                          .copyWith(fontSize: 10)),
                ],
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 17, minHeight: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
