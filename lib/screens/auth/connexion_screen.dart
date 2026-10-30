import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth_card_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../shell/main_shell.dart';
import 'inscription_screen.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _telephoneCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _enCours = false;

  @override
  void dispose() {
    _telephoneCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    final session = context.read<SessionProvider>();
    setState(() => _enCours = true);
    final ok = await session.connecter(
      telephone: _telephoneCtrl.text.trim(),
      motDePasse: _motDePasseCtrl.text,
    );
    if (!mounted) return;
    setState(() => _enCours = false);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return AuthCardScaffold(
      titre: 'Bienvenue',
      questionBas: 'Pas encore de compte ?',
      lienBas: 'Créer un compte',
      onLienBas: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InscriptionScreen()),
      ),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFieldLabel('Numéro de téléphone'),
          AuthTextField(
            controller: _telephoneCtrl,
            icone: Icons.phone_outlined,
            clavier: TextInputType.phone,
            hint: '71 71 15 81',
          ),
          const SizedBox(height: 13),
          const AuthFieldLabel('Mot de passe'),
          AuthTextField(
            controller: _motDePasseCtrl,
            icone: Icons.lock_outline,
            obscure: true,
            hint: '••••••••',
          ),
          if (session.erreur != null) ...[
            const SizedBox(height: 12),
            Text(session.erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
          ],
          const SizedBox(height: 23),
          PrimaryButton(label: 'Se connecter', enChargement: _enCours, onPressed: _seConnecter),
        ],
      ),
    );
  }
}
