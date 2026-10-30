import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Structure commune à Connexion/Inscription (maquette 03/04) : bandeau bleu
/// (42 % de l'écran) avec le logo, "MaliMall" et "Market & MotoTaxis", puis
/// une carte qui chevauche le bandeau (-28 px, radius 24, ombre portée) avec
/// le titre centré en bleu.
class AuthCardScaffold extends StatelessWidget {
  final String titre;
  final Widget enfant;

  /// Lien de bas de carte ("Pas encore de compte ?" / "Créer un compte").
  final String? questionBas;
  final String? lienBas;
  final VoidCallback? onLienBas;

  const AuthCardScaffold({
    super.key,
    required this.titre,
    required this.enfant,
    this.questionBas,
    this.lienBas,
    this.onLienBas,
  });

  @override
  Widget build(BuildContext context) {
    final hauteurEcran = MediaQuery.of(context).size.height;
    final hauteurBandeau = hauteurEcran * 0.42;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: hauteurEcran),
          child: Column(
            children: [
              SizedBox(
                height: hauteurBandeau,
                child: Stack(
                  children: [
                    Container(color: AppColors.accentBleu.withValues(alpha: 0.8)),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _BoutonRetourRond(),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(30, 0, 30, 38),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/branding/logo_mark.png',
                              height: hauteurBandeau * 0.36,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'MaliMall',
                              style: AppTextStyles.headingXL(color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w800, height: 1.5),
                            ),
                            const SizedBox(height: 3),
                            Text('Market & MotoTaxis', style: AppTextStyles.titleS(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceL1,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        spreadRadius: -10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(titre, textAlign: TextAlign.center, style: AppTextStyles.headingL(color: AppColors.accentBleu)),
                      const SizedBox(height: 18),
                      enfant,
                      if (questionBas != null && lienBas != null) ...[
                        const SizedBox(height: 40),
                        Text(
                          questionBas!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyDefault(color: AppColors.textSecondary).copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: TextButton(
                            onPressed: onLienBas,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                            child: Text(lienBas!, style: AppTextStyles.bodyBold(color: AppColors.accentBleu)
                                .copyWith(fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonRetourRond extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Label majuscule 10.5px au-dessus d'un champ, style de la charte.
class AuthFieldLabel extends StatelessWidget {
  final String texte;
  const AuthFieldLabel(this.texte, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texte.toUpperCase(),
        style: AppTextStyles.caption().copyWith(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.42),
      ),
    );
  }
}

/// Champ de saisie de la maquette : fond gris clair, radius 12, icône 15 px
/// grise à gauche.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icone;
  final String? hint;
  final bool obscure;
  final TextInputType? clavier;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.icone,
    this.hint,
    this.obscure = false,
    this.clavier,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: clavier,
      style: AppTextStyles.bodyDefault(),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: Icon(icone, size: 15, color: AppColors.textSecondary),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
      ),
    );
  }
}
