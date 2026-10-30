import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/course_models.dart';
import '../../core/services/course_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/elements_livraison.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/etoiles_notation.dart';
import '../../widgets/primary_button.dart';

/// Maquette 16 — note (1 à 5) et commentaire facultatif sur le chauffeur.
class NoterChauffeurScreen extends StatefulWidget {
  final CourseResponse course;
  const NoterChauffeurScreen({super.key, required this.course});

  @override
  State<NoterChauffeurScreen> createState() => _NoterChauffeurScreenState();
}

class _NoterChauffeurScreenState extends State<NoterChauffeurScreen> {
  int _note = 0;
  final _commentaire = TextEditingController();
  bool _envoi = false;

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_note == 0) {
      AppFeedback.warning(context, 'Choisissez une note entre 1 et 5 étoiles.');
      return;
    }
    setState(() => _envoi = true);
    try {
      final texte = _commentaire.text.trim();
      await context
          .read<CourseService>()
          .noter(widget.course.id, _note, texte.isEmpty ? null : texte);
      if (!mounted) return;
      AppFeedback.success(context, 'Merci pour votre avis !');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) AppFeedback.error(context, messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final nom = c.chauffeurNom ?? 'Votre chauffeur';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 6),
          child: Column(
            children: [
              AvatarInitiales(nom: nom, taille: 84),
              const SizedBox(height: 16),
              Text(nom, style: AppTextStyles.headingM()),
              const SizedBox(height: 6),
              Text(
                'Course terminée · ${c.depart} → ${c.destination}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption(),
              ),
              const SizedBox(height: 20),
              EtoilesNotation(
                note: _note,
                couleur: AppColors.accentBleu,
                onChanged: (n) => setState(() => _note = n),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _commentaire,
                maxLines: 3,
                maxLength: 300,
                style: AppTextStyles.bodyDefault(),
                decoration: const InputDecoration(
                    hintText: 'Ajouter un commentaire (facultatif)…'),
              ),
              const Spacer(),
              PrimaryButton(
                  label: "Envoyer l'avis",
                  enChargement: _envoi,
                  onPressed: _envoyer),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Passer',
                      style:
                          AppTextStyles.bodyBold(color: AppColors.accentBleu)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
