import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Repère posé sur la carte illustrée.
class RepereCarte {
  /// Position relative (0..1, 0..1) — voir core/quartiers.dart.
  final Offset position;
  final Color couleur;
  final IconData icone;

  const RepereCarte({required this.position, required this.couleur, required this.icone});
}

/// Carte illustrée des maquettes MotoTaxi / livraison : fond clair, rues en
/// quadrillage, repères en goutte et, si fourni, un trajet entre deux points
/// (plein ou pointillé). C'est une illustration : aucune donnée GPS réelle.
class CarteStylisee extends StatelessWidget {
  final List<RepereCarte> reperes;
  final (Offset, Offset)? trajet;
  final bool trajetPointille;

  const CarteStylisee({super.key, this.reperes = const [], this.trajet, this.trajetPointille = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final taille = Size(c.maxWidth, c.maxHeight);
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _FondCarte(trajet: trajet, pointille: trajetPointille)),
          ),
          for (final r in reperes)
            Positioned(
              left: r.position.dx * taille.width - 15,
              top: r.position.dy * taille.height - 36,
              child: _Goutte(couleur: r.couleur, icone: r.icone),
            ),
        ],
      );
    });
  }
}

class _Goutte extends StatelessWidget {
  final Color couleur;
  final IconData icone;
  const _Goutte({required this.couleur, required this.icone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 38,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 2,
            child: Transform.rotate(
              angle: 0.785,
              child: Container(width: 12, height: 12, color: couleur),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: couleur,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: couleur.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(icone, size: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FondCarte extends CustomPainter {
  final (Offset, Offset)? trajet;
  final bool pointille;
  _FondCarte({this.trajet, this.pointille = false});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE4E9F1));

    // Îlots (pâtés de maisons) légèrement plus foncés.
    final ilot = Paint()..color = const Color(0xFFD9DFEA);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.28, size.height * 0.22, size.width * 0.2, size.height * 0.08), ilot);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.56, size.height * 0.46, size.width * 0.24, size.height * 0.1), ilot);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.12, size.height * 0.52, size.width * 0.16, size.height * 0.07), ilot);

    // Rues principales.
    final rue = Paint()
      ..color = const Color(0xFFCCD4E2)
      ..strokeWidth = 7;
    final ligne = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.4;
    for (final fx in [0.18, 0.5, 0.82]) {
      final x = size.width * fx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), rue);
      _pointilles(canvas, Offset(x, 0), Offset(x, size.height), ligne);
    }
    for (final fy in [0.2, 0.45, 0.72]) {
      final y = size.height * fy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rue);
      _pointilles(canvas, Offset(0, y), Offset(size.width, y), ligne);
    }

    // Fleuve (bas de la carte).
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.9, size.width, size.height * 0.035),
      Paint()..color = const Color(0xFFC5D9EF),
    );

    final t = trajet;
    if (t != null) {
      final a = Offset(t.$1.dx * size.width, t.$1.dy * size.height);
      final b = Offset(t.$2.dx * size.width, t.$2.dy * size.height);
      final trait = Paint()
        ..color = AppColors.accentBleu
        ..strokeWidth = pointille ? 3 : 4
        ..strokeCap = StrokeCap.round;
      if (pointille) {
        _pointilles(canvas, a, b, trait, tiret: 3, espace: 6);
      } else {
        canvas.drawLine(a, b, trait);
      }
    }
  }

  void _pointilles(Canvas canvas, Offset a, Offset b, Paint p, {double tiret = 8, double espace = 8}) {
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    var parcouru = 0.0;
    while (parcouru < d) {
      final debut = a + dir * parcouru;
      final fin = a + dir * math.min(parcouru + tiret, d);
      canvas.drawLine(debut, fin, p);
      parcouru += tiret + espace;
    }
  }

  @override
  bool shouldRepaint(covariant _FondCarte oldDelegate) => oldDelegate.trajet != trajet;
}
