import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/notification_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/state_views.dart';
import '../boutique/commandes_boutique_screen.dart';
import '../chauffeur/livraisons_disponibles_screen.dart';
import '../livraison/suivi_commande_screen.dart';
import '../mototaxi/demandes_courses_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _ouvrir(BuildContext context, NotificationMaliMall notification) {
    final provider = context.read<NotificationProvider>();
    provider.marquerLue(notification.id);
    final destination = switch (notification.type) {
      TypeNotification.nouvelleCommande => const CommandesBoutiqueScreen(),
      TypeNotification.nouvelleCourse => const DemandesCoursesScreen(),
      TypeNotification.nouvelleLivraison => const LivraisonsDisponiblesScreen(),
      TypeNotification.avancementCommande =>
        SuiviCommandeScreen(commandeId: notification.commandeId!),
    };
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final items = notifications.notifications;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Notifications'),
      body: items.isEmpty
          ? const EmptyView(
              message:
                  'Aucune notification pour le moment. Les nouvelles commandes, courses et étapes de livraison apparaîtront ici.',
              icone: Icons.notifications_none_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = items[index];
                final nonLue = notifications.estNonLue(notification.id);
                return Material(
                  color: nonLue
                      ? AppColors.accentBleu.withValues(alpha: 0.08)
                      : AppColors.surfaceL1,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _ouvrir(context, notification),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            _icone(notification.type),
                            color: AppColors.accentBleu,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notification.message,
                              style: AppTextStyles.bodyDefault(),
                            ),
                          ),
                          if (nonLue)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.circle,
                                  size: 9, color: AppColors.accentBleu),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _icone(TypeNotification type) => switch (type) {
        TypeNotification.nouvelleCommande => Icons.shopping_bag_outlined,
        TypeNotification.nouvelleCourse => Icons.two_wheeler_outlined,
        TypeNotification.nouvelleLivraison => Icons.local_shipping_outlined,
        TypeNotification.avancementCommande =>
          Icons.local_shipping_outlined,
      };
}
