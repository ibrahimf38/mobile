import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/api/api_exception.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'bouton_rond.dart';
import 'code_input_field.dart';
import 'primary_button.dart';

/// Écran de scan plein écran sombre (maquettes 26 et 32) : caméra avec
/// cadre en coins, consigne, encadré d'avertissement et bouton de secours
/// pour saisir le code à 6 chiffres à la main (si la caméra ou le scan
/// échoue). [onCode] envoie le code au backend ; s'il lève une erreur, le
/// message s'affiche et le scan reprend.
class EcranScanCode extends StatefulWidget {
  final String titre;
  final String consigne;
  final String sousConsigne;
  final String avertissement;
  final Future<void> Function(String code) onCode;

  const EcranScanCode({
    super.key,
    required this.titre,
    required this.consigne,
    required this.sousConsigne,
    required this.avertissement,
    required this.onCode,
  });

  @override
  State<EcranScanCode> createState() => _EcranScanCodeState();
}

class _EcranScanCodeState extends State<EcranScanCode> {
  static const _fondSombre = Color(0xFF15161E);
  final _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  static bool _codeValide(String? v) => v != null && RegExp(r'^\d{6}$').hasMatch(v);

  Future<void> _envoyer(String code) async {
    if (_envoi) return;
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await widget.onCode(code);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = messageErreur(e));
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  void _surDetection(BarcodeCapture capture) {
    for (final b in capture.barcodes) {
      final valeur = b.rawValue?.replaceAll(' ', '');
      if (_codeValide(valeur)) {
        _envoyer(valeur!);
        return;
      }
    }
  }

  Future<void> _saisieManuelle() async {
    final ctrl = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceL1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Saisir le code', style: AppTextStyles.headingM(), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Le code à 6 chiffres affiché sous le QR.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyDefault(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            CodeInputField(controller: ctrl),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Valider',
              onPressed: () {
                if (_codeValide(ctrl.text)) Navigator.of(ctx).pop(ctrl.text);
              },
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (code != null) await _envoyer(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondSombre,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  BoutonRond.retour(context, surFondSombre: true),
                  const SizedBox(width: 12),
                  Text(widget.titre, style: AppTextStyles.titleAppBar(color: Colors.white)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 230,
                    height: 230,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFF1C2033)),
                        MobileScanner(controller: _scanner, onDetect: _surDetection),
                        CustomPaint(painter: _CoinsCadre()),
                        if (_envoi)
                          Container(
                            color: Colors.black45,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(widget.consigne, style: AppTextStyles.bodyBold(color: Colors.white)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.sousConsigne,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(color: Colors.white70).copyWith(height: 1.5),
                  ),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _erreur!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium(color: const Color(0xFFFF8A8A)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            decoration: const BoxDecoration(
              color: AppColors.surfaceL1,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 17, color: AppColors.accentOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.avertissement,
                              style: AppTextStyles.caption(color: AppColors.accentOrange).copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(label: 'Saisir le code à 6 chiffres', onPressed: _envoi ? null : _saisieManuelle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinsCadre extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const m = 26.0, l = 40.0;
    final w = size.width, h = size.height;
    for (final (x, y, dx, dy) in [(m, m, 1.0, 1.0), (w - m, m, -1.0, 1.0), (m, h - m, 1.0, -1.0), (w - m, h - m, -1.0, -1.0)]) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * l, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * l), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
