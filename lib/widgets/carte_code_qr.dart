import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'bordure_pointillee.dart';

/// Encadré pointillé des maquettes 28 et 34 : QR code du code à 6 chiffres,
/// le code en clair ("73 08 21") et une légende.
class CarteCodeQr extends StatelessWidget {
  final String code;
  final String legende;

  const CarteCodeQr({super.key, required this.code, required this.legende});

  String get _codeEspace {
    if (code.length != 6) return code;
    return '${code.substring(0, 2)} ${code.substring(2, 4)} ${code.substring(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: BordurePointillee(couleur: AppColors.accentBleu, rayon: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        decoration: BoxDecoration(color: AppColors.surfaceL1, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
              ),
              child: QrImageView(data: code, size: 126, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 14),
            Text(
              _codeEspace,
              style: AppTextStyles.headingXL(color: AppColors.accentBleu).copyWith(fontSize: 22, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              legende.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.captionSmall().copyWith(fontSize: 8.5, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
