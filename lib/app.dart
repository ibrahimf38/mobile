import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/localisation.dart';
import 'core/services/auth_service.dart';
import 'core/services/catalogue_service.dart';
import 'core/services/commande_service.dart';
import 'core/services/course_service.dart';
import 'core/services/livreur_service.dart';
import 'core/services/panier_service.dart';
import 'core/services/portefeuille_service.dart';
import 'core/services/profil_service.dart';
import 'core/services/publicite_service.dart';
import 'core/storage/token_storage.dart';
import 'screens/auth/connexion_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/main_shell.dart';
import 'state/notification_provider.dart';
import 'state/panier_provider.dart';
import 'state/session_provider.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

/// Racine de l'app : construit une fois les dépendances (ApiClient, services,
/// providers d'état) et les injecte via `provider` pour tout le reste de
/// l'arbre de widgets — aucun écran ne doit instancier un service lui-même.
class MaliMallApp extends StatefulWidget {
  const MaliMallApp({super.key});

  @override
  State<MaliMallApp> createState() => _MaliMallAppState();
}

class _MaliMallAppState extends State<MaliMallApp> {
  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final ProfilService _profilService;
  late final CatalogueService _catalogueService;
  late final PanierService _panierService;
  late final CommandeService _commandeService;
  late final PortefeuilleService _portefeuilleService;
  late final PubliciteService _publiciteService;
  late final LivreurService _livreurService;
  late final CourseService _courseService;
  late final PartagePosition _partagePosition;

  @override
  void initState() {
    super.initState();
    _tokenStorage = TokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);
    _authService = AuthService(_apiClient);
    _profilService = ProfilService(_apiClient);
    _catalogueService = CatalogueService(_apiClient);
    _panierService = PanierService(_apiClient);
    _commandeService = CommandeService(_apiClient);
    _portefeuilleService = PortefeuilleService(_apiClient);
    _publiciteService = PubliciteService(_apiClient);
    _livreurService = LivreurService(_apiClient);
    _courseService = CourseService(_apiClient);
    _partagePosition = PartagePosition(_livreurService);
  }

  @override
  void dispose() {
    _partagePosition.arreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _apiClient),
        Provider<AuthService>.value(value: _authService),
        Provider<ProfilService>.value(value: _profilService),
        Provider<CatalogueService>.value(value: _catalogueService),
        Provider<PanierService>.value(value: _panierService),
        Provider<CommandeService>.value(value: _commandeService),
        Provider<PortefeuilleService>.value(value: _portefeuilleService),
        Provider<PubliciteService>.value(value: _publiciteService),
        Provider<LivreurService>.value(value: _livreurService),
        Provider<CourseService>.value(value: _courseService),
        Provider<PartagePosition>.value(value: _partagePosition),
        ChangeNotifierProvider<SessionProvider>(
          create: (_) => SessionProvider(
            apiClient: _apiClient,
            authService: _authService,
            tokenStorage: _tokenStorage,
          )..initialiser(),
        ),
        ChangeNotifierProxyProvider<SessionProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
            commandeService: _commandeService,
            courseService: _courseService,
            livreurService: _livreurService,
          ),
          update: (_, session, notifications) =>
              notifications!..suivreSession(session),
        ),
        ChangeNotifierProvider<PanierProvider>(
          create: (_) => PanierProvider(_panierService),
        ),
      ],
      child: MaterialApp(
        title: 'MaliMall',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _RacineNavigation(),
      ),
    );
  }
}

/// Bascule entre Onboarding (déconnecté) et MainShell (connecté) selon
/// [SessionProvider.etat] — jamais de logique de session dupliquée dans les
/// écrans eux-mêmes.
class _RacineNavigation extends StatelessWidget {
  const _RacineNavigation();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    switch (session.etat) {
      case EtatSession.chargement:
        return const Scaffold(
          backgroundColor: AppColors.accentBleu,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        );
      case EtatSession.connecte:
        return const MainShell();
      case EtatSession.deconnecte:
        // L'onboarding ne doit s'afficher qu'une seule fois, juste après
        // l'installation — sur cet appareil, il a déjà été vu (ou
        // l'utilisateur vient de se déconnecter) : direction Connexion.
        return session.onboardingVu
            ? const ConnexionScreen()
            : const OnboardingScreen();
    }
  }
}
