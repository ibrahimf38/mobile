import 'package:flutter/material.dart';

/// Rangée de 5 étoiles cliquables (note de 1 à 5).
class EtoilesNotation extends StatelessWidget {
  final int note;
  final ValueChanged<int>? onChanged;
  final Color couleur;
  final double taille;

  const EtoilesNotation({
    super.key,
    required this.note,
    this.onChanged,
    this.couleur = const Color(0xFFF5A623),
    this.taille = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final pleine = i < note;
        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onChanged == null ? null : () => onChanged!(i + 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                pleine ? Icons.star_rounded : Icons.star_outline_rounded,
                size: taille,
                color: pleine ? couleur : couleur.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      }),
    );
  }
}
