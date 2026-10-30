import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'reseau_image.dart';

/// Zone de sélection de photo — reprend le composant "Zone d'upload
/// pointillée" de la charte (la maquette Figma MaliMall section 6) :
/// radius 14, bordure pointillée grise 1.6px, hauteur 96px tant qu'aucune
/// image n'est choisie. Une fois une photo sélectionnée (ou déjà présente
/// sur le produit/la boutique), affiche un aperçu plein cadre avec un badge
/// "Changer" en overlay.
class PhotoPickerTile extends StatelessWidget {
  final Uint8List? apercu;
  final String? imageUrlExistante;
  final bool enCours;
  final VoidCallback onChoisir;

  const PhotoPickerTile({
    super.key,
    this.apercu,
    this.imageUrlExistante,
    this.enCours = false,
    required this.onChoisir,
  });

  bool get _aUneImage => apercu != null || (imageUrlExistante != null && imageUrlExistante!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enCours ? null : onChoisir,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 96,
        width: double.infinity,
        child: CustomPaint(
          painter: _aUneImage ? null : _BordurePointilleePainter(color: AppColors.iconDisabled),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: AppColors.surfaceL2,
              child: _contenu(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenu() {
    if (enCours) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBleu)));
    }
    if (apercu != null) {
      return Image.memory(apercu!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    if (imageUrlExistante != null && imageUrlExistante!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ReseauImage(imageUrl: imageUrlExistante),
          Positioned(right: 8, bottom: 8, child: _badgeChanger()),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 26),
          const SizedBox(height: 4),
          Text('Ajouter une photo', style: AppTextStyles.caption(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _badgeChanger() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text('Changer', style: TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}

/// Trace une bordure arrondie pointillée — pas de composant natif Flutter
/// pour ça ; dessin manuel volontairement simple (segments égaux le long du
/// contour), suffisant pour reproduire fidèlement la maquette.
class _BordurePointilleePainter extends CustomPainter {
  final Color color;
  const _BordurePointilleePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    const largeurTrait = 5.0;
    const espace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final suivant = distance + largeurTrait;
        canvas.drawPath(metric.extractPath(distance, suivant.clamp(0, metric.length)), paint);
        distance = suivant + espace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BordurePointilleePainter oldDelegate) => oldDelegate.color != color;
}
