import 'package:flutter/material.dart';

/// Bordure en pointillés arrondie (Flutter n'a pas de BorderStyle.dashed).
/// À utiliser en `foregroundPainter` d'un CustomPaint.
class BordurePointillee extends CustomPainter {
  final Color couleur;
  final double rayon;
  final double tiret;
  final double espace;

  BordurePointillee({required this.couleur, this.rayon = 16, this.tiret = 4, this.espace = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final chemin = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(rayon)));
    for (final metrique in chemin.computeMetrics()) {
      var distance = 0.0;
      while (distance < metrique.length) {
        canvas.drawPath(metrique.extractPath(distance, distance + tiret), paint);
        distance += tiret + espace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BordurePointillee oldDelegate) =>
      oldDelegate.couleur != couleur || oldDelegate.rayon != rayon;
}
