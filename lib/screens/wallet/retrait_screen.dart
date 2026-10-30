import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/format.dart';
import '../../core/services/portefeuille_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/primary_button.dart';
import 'operateur_argent.dart';

/// Retrait du portefeuille vers un opérateur mobile money — même principe
/// que [RechargeScreen] (simulation de bout en bout), en sens inverse : le
/// solde disponible MaliMall est débité, l'envoi à l'opérateur est simulé.
class RetraitScreen extends StatefulWidget {
  final int soldeDisponible;
  const RetraitScreen({super.key, required this.soldeDisponible});

  @override
  State<RetraitScreen> createState() => _RetraitScreenState();
}

class _RetraitScreenState extends State<RetraitScreen> {
  int _etape = 0;
  OperateurArgent? _operateur;
  final _montantCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _enTraitement = false;
  String? _erreur;
  int? _nouveauSolde;

  int? get _montant => int.tryParse(_montantCtrl.text.trim());

  @override
  void dispose() {
    _montantCtrl.dispose();
    _telephoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _versConfirmation() {
    if (_operateur == null) {
      setState(() => _erreur = 'Choisissez un opérateur.');
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
    if (_telephoneCtrl.text.trim().isEmpty) {
      setState(
          () => _erreur = "Indiquez le numéro associé à ${_operateur!.nom}.");
      return;
    }
    if (_pinCtrl.text.trim().length < 4) {
      setState(() => _erreur = 'Le code secret doit contenir 4 chiffres.');
      return;
    }
    setState(() {
      _erreur = null;
      _enTraitement = true;
    });
    final service = context.read<PortefeuilleService>();
    try {
      await Future.delayed(const Duration(milliseconds: 1400));
      final resultat = await service.retirer(
        montantMmc: _montant!,
        operateur: _operateur!.code,
        telephoneOperateur: _telephoneCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _nouveauSolde = resultat.soldeDisponible;
        _etape = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _enTraitement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(titre: 'Retrait', afficherRetour: _etape != 2),
      body: SafeArea(
        child: switch (_etape) {
          0 => _etapeChoix(),
          1 => _etapeConfirmation(),
          _ => _etapeSucces(),
        },
      ),
    );
  }

  Widget _etapeChoix() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text('Solde disponible : ${formatMmc(widget.soldeDisponible)} MMC',
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        Text('Choisissez un opérateur', style: AppTextStyles.bodyBold()),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: 1.5,
          children: [
            for (final op in OperateurArgent.values)
              CarteOperateur(
                operateur: op,
                selectionne: _operateur == op,
                onTap: () => setState(() {
                  _operateur = op;
                  _erreur = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 22),
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
    final operateur = _operateur!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.surfaceL1,
              borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              BadgeOperateur(operateur: operateur, taille: 44),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(operateur.nom, style: AppTextStyles.bodyBold()),
                    const SizedBox(height: 3),
                    Text(
                        '${formatMmc(_montant!)} MMC · ≈ ${formatMmc(equivalentFcfa(_montant!))} FCFA',
                        style: AppTextStyles.caption()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Numéro ${operateur.nom}', style: AppTextStyles.bodyBold()),
        const SizedBox(height: 9),
        TextField(
          controller: _telephoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+223 00 00 00 00'),
        ),
        const SizedBox(height: 18),
        Text('Code secret', style: AppTextStyles.bodyBold()),
        const SizedBox(height: 4),
        Text('Simulation : entrez 4 chiffres, n\'importe lesquels.',
            style: AppTextStyles.caption()),
        const SizedBox(height: 9),
        TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(hintText: '••••', counterText: ''),
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 10),
          Text(_erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
            label: 'Confirmer',
            enChargement: _enTraitement,
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
                color: AppColors.walletRetrait, shape: BoxShape.circle),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 18),
          Text('Retrait réussi !', style: AppTextStyles.headingM()),
          const SizedBox(height: 6),
          Text(
            '${formatMmc(_montant!)} MMC ont été envoyés vers votre compte ${_operateur!.nom}.',
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
