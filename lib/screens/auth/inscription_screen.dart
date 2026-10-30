import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/auth_card_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../shell/main_shell.dart';
import 'connexion_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _nomCompletCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _enCours = false;
  String? _erreurLocale;

  @override
  void dispose() {
    _nomCompletCtrl.dispose();
    _telephoneCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    final session = context.read<SessionProvider>();
    // "Nom complet" (maquette 04) : premier mot = prénom, le reste = nom.
    final morceaux = _nomCompletCtrl.text.trim().split(RegExp(r'\s+'));
    final prenom = morceaux.first;
    if (morceaux.length < 2) {
      setState(() => _erreurLocale = 'Indiquez votre prénom et votre nom.');
      return;
    }
    final nom = morceaux.sublist(1).join(' ');
    setState(() {
      _erreurLocale = null;
      _enCours = true;
    });
    final ok = await session.inscrire(
      nom: nom,
      prenom: prenom,
      telephone: _telephoneCtrl.text.trim(),
      email: null,
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
      titre: 'Créer un compte',
      questionBas: 'Déjà un compte ?',
      lienBas: 'Se connecter',
      onLienBas: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConnexionScreen()),
      ),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthFieldLabel('Nom complet'),
          AuthTextField(controller: _nomCompletCtrl, icone: Icons.person_outline, hint: 'Ibrahim Diarra'),
          const SizedBox(height: 13),
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
            hint: 'Au moins 6 caractères',
          ),
          if ((_erreurLocale ?? session.erreur) != null) ...[
            const SizedBox(height: 12),
            Text(_erreurLocale ?? session.erreur!, style: AppTextStyles.caption(color: AppColors.danger)),
          ],
          const SizedBox(height: 19),
          PrimaryButton(label: "S'inscrire", enChargement: _enCours, onPressed: _sInscrire),
        ],
      ),
    );
  }
}
