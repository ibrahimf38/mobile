import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/services/portefeuille_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/primary_button.dart';

/// Envoi de MMC à un autre compte MaliMall, identifié par son numéro de
/// téléphone — vers un vrai portefeuille MaliMall, donc AUCUNE simulation
/// ici (contrairement à Recharge/Retrait) : la vérification (le numéro
/// existe-t-il ?) et le virement sont réels, faits par le backend.
class EnvoyerScreen extends StatefulWidget {
  final int soldeDisponible;
  const EnvoyerScreen({super.key, required this.soldeDisponible});

  @override
  State<EnvoyerScreen> createState() => _EnvoyerScreenState();
}

class _EnvoyerScreenState extends State<EnvoyerScreen> {
  int _etape = 0;
  final _telephoneCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  bool _enCours = false;
  String? _erreur;
  int? _nouveauSolde;
  String? _destinataireNom;

  int? get _montant => int.tryParse(_montantCtrl.text.trim());

  @override
  void dispose() {
    _telephoneCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  void _versConfirmation() {
    if (_telephoneCtrl.text.trim().isEmpty) {
      setState(() => _erreur = 'Indiquez le numéro du destinataire.');
      return;
    }
    final montant = _montant;
    if (montant == null || montant <= 0) {
      setState(() => _erreur = 'Indiquez un montant valide.');
      return;
    }
    if (montant > widget.soldeDisponible) {
      setState(() => _erreur = 'Solde disponible insuffisant.');
      return;
    }
    setState(() {
      _erreur = null;
      _etape = 1;
    });
  }

  Future<void> _confirmer() async {
    setState(() {
      _erreur = null;
      _enCours = true;
    });
    try {
      final resultat = await context.read<PortefeuilleService>().transferer(
            montantMmc: _montant!,
            telephoneDestinataire: _telephoneCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _nouveauSolde = resultat.portefeuille.soldeDisponible;
        _destinataireNom = resultat.destinataireNomComplet;
        _etape = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = messageErreur(e);
        _etape = 0;
      });
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppHeaderBar(titre: 'Envoyer des MMC', afficherRetour: _etape != 2),
      body: SafeArea(
        child: switch (_etape) {
          0 => _etapeFormulaire(),
          1 => _etapeConfirmation(),
          _ => _etapeSucces(),
        },
      ),
    );
  }

  Widget _etapeFormulaire() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text('Solde disponible : ${formatMmc(widget.soldeDisponible)} MMC',
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Text('Numéro du destinataire', style: AppTextStyles.bodyBold()),
        const SizedBox(height: 9),
        TextField(
          controller: _telephoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+223 00 00 00 00',
            prefixIcon: Icon(Icons.phone_outlined,
                size: 18, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 4),
        Text('Un compte MaliMall existant, jamais un numéro mobile money.',
            style: AppTextStyles.caption()),
        const SizedBox(height: 20),
        Text('Montant (MMC)', style: AppTextStyles.bodyBold()),
        const SizedBox(height: 9),
        TextField(
          controller: _montantCtrl,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.headingM(),
          decoration: const InputDecoration(hintText: '0'),
        ),
        if (_montant != null && _montant! > 0) ...[
          const SizedBox(height: 6),
          Text('≈ ${formatMmc(equivalentFcfa(_montant!))} FCFA',
              style: AppTextStyles.caption()),
        ],
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Text(_erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
        ],
        const SizedBox(height: 24),
        PrimaryButton(label: 'Continuer', onPressed: _versConfirmation),
      ],
    );
  }

  Widget _etapeConfirmation() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.surfaceL1,
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.walletEnvoyer.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.send_outlined,
                    color: AppColors.walletEnvoyer, size: 22),
              ),
              const SizedBox(height: 12),
              Text('${formatMmc(_montant!)} MMC',
                  style: AppTextStyles.displayMontant()),
              const SizedBox(height: 4),
              Text('vers ${_telephoneCtrl.text.trim()}',
                  style: AppTextStyles.caption()),
            ],
          ),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Text(_erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
        ],
        const SizedBox(height: 22),
        PrimaryButton(
            label: 'Confirmer l\'envoi',
            enChargement: _enCours,
            onPressed: _confirmer),
      ],
    );
  }

  Widget _etapeSucces() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
                color: AppColors.walletEnvoyer, shape: BoxShape.circle),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 18),
          Text('Envoi réussi !', style: AppTextStyles.headingM()),
          const SizedBox(height: 6),
          Text(
            '${formatMmc(_montant!)} MMC ont été envoyés à ${_destinataireNom ?? ''}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyDefault(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
              'Nouveau solde disponible : ${formatMmc(_nouveauSolde ?? 0)} MMC',
              style: AppTextStyles.bodyBold()),
          const Spacer(),
          PrimaryButton(
              label: 'Terminé',
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}
