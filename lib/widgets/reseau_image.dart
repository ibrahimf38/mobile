import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Affiche une photo hébergée sur Supabase Storage (`imageUrl`) si elle est
/// renseignée, avec un indicateur de chargement pendant le téléchargement et
/// un repli propre — le même pictogramme de substitution qu'avant — si
/// `imageUrl` est nul (aucune photo téléversée) ou si le chargement échoue
/// (URL expirée, pas de réseau...). Jamais d'image cassée à l'écran.
class ReseauImage extends StatelessWidget {
  final String? imageUrl;
  final IconData icone;
  final double tailleIcone;
  final BoxFit fit;
  final Color? couleurFond;
  final Color? couleurIcone;

  const ReseauImage({
    super.key,
    required this.imageUrl,
    this.icone = Icons.storefront_outlined,
    this.tailleIcone = 36,
    this.fit = BoxFit.cover,
    this.couleurFond,
    this.couleurIcone,
  });

  Widget _placeholder() => Container(
        color: couleurFond ?? AppColors.surfaceL2,
        child: Center(
          child: Icon(
            icone,
            size: tailleIcone,
            color: (couleurIcone ?? AppColors.accentBleu).withValues(alpha: 0.55),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.surfaceL2,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBleu),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }
}
