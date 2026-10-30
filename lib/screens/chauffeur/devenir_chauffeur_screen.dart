import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/profil_models.dart';
import '../../core/services/profil_service.dart';
import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/auth_card_scaffold.dart';
import '../../widgets/elements_liste.dart';
import '../../widgets/primary_button.dart';

class DevenirChauffeurScreen extends StatefulWidget {
  const DevenirChauffeurScreen({super.key});

  @override
  State<DevenirChauffeurScreen> createState() => _DevenirChauffeurScreenState();
}

class _DevenirChauffeurScreenState extends State<DevenirChauffeurScreen> {
  final _immatriculationCtrl = TextEditingController();
  final _permisCtrl = TextEditingController();
  TypeVehicule _typeVehicule = TypeVehicule.telimani;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _immatriculationCtrl.dispose();
    _permisCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (_immatriculationCtrl.text.trim().isEmpty) {
      setState(() => _erreur = "L'immatriculation est obligatoire.");
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final chauffeurId = await context.read<ProfilService>().devenirChauffeur(
            typeVehicule: _typeVehicule,
            immatriculation: _immatriculationCtrl.text.trim(),
            numeroPermis: _permisCtrl.text.trim().isEmpty
                ? null
                : _permisCtrl.text.trim(),
          );
      if (!mounted) return;
      context.read<SessionProvider>().activerRoleChauffeur(chauffeurId);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Compte chauffeur activé'),
          content: const Text(
              'Vous pouvez maintenant accéder à votre espace chauffeur.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'))
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } on ReseauException catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Ce que chaque véhicule peut transporter (mêmes règles que le backend).
  static String _description(TypeVehicule t) => switch (t) {
        TypeVehicule.scooter =>
          ' — livraison de colis seulement, jusqu\'à 10 kg.',
        TypeVehicule.telimani =>
          ' — transporte des passagers, ou des livraisons de 0 à 20 kg.',
        TypeVehicule.tricycle =>
          ' — livraison seulement, charges lourdes et volumineuses.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeaderBar(titre: 'Devenir chauffeur'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rejoignez les chauffeurs MotoTaxi et gagnez des MMC en transportant des passagers ou en livrant '
              'des colis Market dans votre quartier.',
              style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                  .copyWith(height: 1.55),
            ),
            const SizedBox(height: 18),
            const AuthFieldLabel('Type de véhicule'),
            Row(
              children: [
                for (final t in TypeVehicule.values) ...[
                  ChipFiltre(
                      label: t.libelle,
                      actif: _typeVehicule == t,
                      onTap: () => setState(() => _typeVehicule = t)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceL1,
                  borderRadius: BorderRadius.circular(14)),
              child: Text.rich(
                TextSpan(
                  text: _typeVehicule.libelle,
                  style: AppTextStyles.bodyBold(),
                  children: [
                    TextSpan(
                      text: _description(_typeVehicule),
                      style: AppTextStyles.caption().copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const AuthFieldLabel("Numéro d'immatriculation"),
            TextField(
              controller: _immatriculationCtrl,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.bodyDefault(),
              decoration: const InputDecoration(hintText: 'ex. KT-4521'),
            ),
            const SizedBox(height: 14),
            const AuthFieldLabel('Numéro de permis'),
            TextField(
              controller: _permisCtrl,
              textCapitalization: TextCapitalization.characters,
              style: AppTextStyles.bodyDefault(),
              decoration: const InputDecoration(
                  hintText: 'ex. BKO-2024-00451 (facultatif pour un Scooter)'),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!,
                  style: AppTextStyles.caption(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
          child: PrimaryButton(
              label: 'Soumettre ma demande',
              enChargement: _enCours,
              onPressed: _valider),
        ),
      ),
    );
  }
}
