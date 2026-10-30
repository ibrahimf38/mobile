import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class MainBottomNavBar extends StatelessWidget {
  final int indexCourant;
  final ValueChanged<int> onChanged;
  final int badgeCompte;

  const MainBottomNavBar(
      {super.key,
      required this.indexCourant,
      required this.onChanged,
      this.badgeCompte = 0});

  static const _items = [
    (icone: Icons.shopping_bag_outlined, label: 'Market'),
    (icone: Icons.two_wheeler_outlined, label: 'MotoTaxis'),
    (icone: Icons.account_balance_wallet_outlined, label: 'Wallet'),
    (icone: Icons.person_outline, label: 'Compte'),
  ];

  @override
  Widget build(BuildContext context) {
    final largeur = MediaQuery.sizeOf(context).width;
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: indexCourant.toDouble()),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeInOutCubic,
            builder: (context, indexAnime, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BarreCourbePainter(indexAnime),
                  ),
                ),
                Row(
                  children: List.generate(_items.length, (i) {
                    final item = _items[i];
                    final actif = i == indexCourant;
                    return Expanded(
                      child: InkWell(
                        onTap: () => onChanged(i),
                        child: Semantics(
                          label: item.label,
                          selected: actif,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!actif)
                                Positioned(
                                  top: 7,
                                  child: _IconeNavigation(
                                    icone: item.icone,
                                    couleur: AppColors.textSecondary,
                                    badge: i == 3 ? badgeCompte : 0,
                                  ),
                                ),
                              if (!actif)
                                Positioned(
                                  bottom: 20,
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    style: AppTextStyles.caption(
                                      color: AppColors.textSecondary,
                                    ).copyWith(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                Positioned(
                  left: largeur * (indexAnime + 0.5) / _items.length - 19,
                  top: -5,
                  child: IgnorePointer(
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.accentBleu,
                        shape: BoxShape.circle,
                      ),
                      child: _IconeNavigation(
                        icone: _items[indexCourant].icone,
                        couleur: Colors.white,
                        badge: indexCourant == 3 ? badgeCompte : 0,
                        taille: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarreCourbePainter extends CustomPainter {
  final double indexActif;

  const _BarreCourbePainter(this.indexActif);

  @override
  void paint(Canvas canvas, Size size) {
    final centre =
        size.width * (indexActif + 0.5) / MainBottomNavBar._items.length;
    final chemin = Path()
      ..moveTo(0, 0)
      ..lineTo(centre - 46, 0)
      ..cubicTo(centre - 30, 0, centre - 34, 46, centre, 46)
      ..cubicTo(centre + 34, 46, centre + 30, 0, centre + 48, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(chemin, Paint()..color = AppColors.surfaceL1);
  }

  @override
  bool shouldRepaint(covariant _BarreCourbePainter oldDelegate) =>
      oldDelegate.indexActif != indexActif;
}

class _IconeNavigation extends StatelessWidget {
  final IconData icone;
  final Color couleur;
  final int badge;
  final double taille;

  const _IconeNavigation(
      {required this.icone,
      required this.couleur,
      this.badge = 0,
      this.taille = 18});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icone, size: taille, color: couleur),
        if (badge > 0)
          Positioned(
            top: -8,
            right: -11,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                badge > 9 ? '9+' : '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
