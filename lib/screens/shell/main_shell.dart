import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/notification_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../compte/compte_screen.dart';
import '../market/accueil_market_screen.dart';
import '../mototaxi/mototaxi_screen.dart';
import '../wallet/portefeuille_screen.dart';

/// Coquille principale une fois connecté — navigation du bas à 4 onglets.
/// Chaque onglet garde son propre état (IndexedStack) plutôt que d'être
/// reconstruit à chaque changement d'onglet.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _ecrans = [
    AccueilMarketScreen(),
    MotoTaxiScreen(),
    PortefeuilleScreen(),
    CompteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: MainBottomNavBar(
        indexCourant: _index,
        badgeCompte:
            notifications.nombreNonLues(TypeNotification.values.toSet()),
        onChanged: (i) {
          setState(() => _index = i);
        },
      ),
    );
  }
}
