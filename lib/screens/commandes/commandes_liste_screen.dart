import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/commande_models.dart';
import '../../core/services/commande_service.dart';
import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/order_card.dart';
import '../../widgets/state_views.dart';
import '../boutique/detail_commande_vendeur_screen.dart';
import '../chauffeur/livraison_en_cours_screen.dart';
import '../livraison/suivi_commande_screen.dart';
import 'detail_commande_screen.dart';

class _Onglet {
  final String role; // 'acheteur' | 'vendeur' | 'chauffeur'
  final String titre;
  final ViewerRole viewerRole;
  const _Onglet(this.role, this.titre, this.viewerRole);
}

/// Liste des commandes — un onglet "Achats" toujours présent (tout
/// utilisateur a une spécialisation Client), plus "Ventes"/"Livraisons"
/// selon les rôles courants (SessionProvider.roles).
class CommandesListeScreen extends StatelessWidget {
  const CommandesListeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final onglets = <_Onglet>[
      const _Onglet('acheteur', 'Achats', ViewerRole.acheteur),
      if (session.estVendeur) const _Onglet('vendeur', 'Ventes', ViewerRole.vendeur),
      if (session.estChauffeur) const _Onglet('chauffeur', 'Livraisons', ViewerRole.chauffeur),
    ];

    return DefaultTabController(
      length: onglets.length,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeaderBar(
          titre: 'Mes commandes',
          bottom: onglets.length > 1
              ? TabBar(
                  labelColor: AppColors.accentBleu,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.accentBleu,
                  tabs: onglets.map((o) => Tab(text: o.titre)).toList(),
                )
              : null,
        ),
        body: TabBarView(
          physics: onglets.length > 1 ? null : const NeverScrollableScrollPhysics(),
          children: onglets.map((o) => _ListeParRole(onglet: o)).toList(),
        ),
      ),
    );
  }
}

class _ListeParRole extends StatefulWidget {
  final _Onglet onglet;
  const _ListeParRole({required this.onglet});

  @override
  State<_ListeParRole> createState() => _ListeParRoleState();
}

class _ListeParRoleState extends State<_ListeParRole> with AutomaticKeepAliveClientMixin {
  List<CommandeResponse>? _commandes;
  String? _erreur;
  bool _chargement = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final commandes = await context.read<CommandeService>().mesCommandes(role: widget.onglet.role);
      if (!mounted) return;
      setState(() => _commandes = commandes..sort((a, b) => b.dateCommande.compareTo(a.dateCommande)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } on ReseauException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_chargement) return const LoadingView();
    if (_erreur != null) return ErrorView(message: _erreur!, onReessayer: _charger);
    final commandes = _commandes ?? [];
    if (commandes.isEmpty) {
      return const EmptyView(message: 'Aucune commande pour le moment.', icone: Icons.receipt_long_outlined);
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: commandes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final commande = commandes[i];
          return OrderCard(
            commande: commande,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => switch (widget.onglet.viewerRole) {
                  ViewerRole.acheteur => SuiviCommandeScreen(commandeId: commande.id),
                  ViewerRole.vendeur => DetailCommandeVendeurScreen(commandeId: commande.id),
                  ViewerRole.chauffeur => commande.statut == StatutCommande.livree ||
                          commande.statut == StatutCommande.annulee
                      ? DetailCommandeScreen(commandeId: commande.id, viewerRole: ViewerRole.chauffeur)
                      : LivraisonEnCoursScreen(commandeId: commande.id),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
