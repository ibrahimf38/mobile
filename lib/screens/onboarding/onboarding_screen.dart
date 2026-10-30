import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_provider.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_button.dart';
import '../auth/connexion_screen.dart';

class _Slide {
  final List<String> images;
  final IconData icone;
  final Color couleurIcone;
  final String titre;
  final String sousTitre;
  const _Slide({
    required this.images,
    required this.icone,
    required this.couleurIcone,
    required this.titre,
    required this.sousTitre,
  });
}

/// Photos exportées de la maquette (voir README, section Onboarding) :
/// assets/images/onboarding/market_1..6.jpg et moto_1..5.jpg.
const _slides = [
  _Slide(
    images: [
      'assets/images/onboarding/market_1.png',
      'assets/images/onboarding/market_2.png',
      'assets/images/onboarding/market_3.png',
      'assets/images/onboarding/market_4.png',
      'assets/images/onboarding/market_5.png',
      'assets/images/onboarding/market_6.png',
    ],
    icone: Icons.shopping_bag_outlined,
    couleurIcone: AppColors.accentBleu,
    titre: 'Achetez & vendez sur Market',
    sousTitre: 'Mode, artisanat, bijoux et plus encore — payez en MMC, votre monnaie MaliMall, '
        'livré près de chez vous.',
  ),
  _Slide(
    images: [
      'assets/images/onboarding/moto_1.png',
      'assets/images/onboarding/moto_2.png',
      'assets/images/onboarding/moto_3.png',
      'assets/images/onboarding/moto_4.png',
      'assets/images/onboarding/moto_5.png',
    ],
    icone: Icons.two_wheeler,
    couleurIcone: AppColors.accentOrange,
    titre: 'Déplacez-vous en MotoTaxi',
    sousTitre: 'Demandez une course en quelques secondes et suivez votre chauffeur en temps réel sur la carte.',
  ),
];

/// Maquette 01/02 : carrousel photo en haut (56 % de l'écran) avec pastille
/// ronde d'icône, puis titre, texte, indicateur de page et bouton
/// "Suivant" → "Commencer".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _dernierePage => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _suivant() {
    if (_dernierePage) {
      // Onboarding terminé : ne plus jamais le réafficher sur cet appareil,
      // même après une déconnexion (voir _RacineNavigation dans app.dart).
      context.read<SessionProvider>().marquerOnboardingVu();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ConnexionScreen()));
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => _SlideVue(slide: _slides[i]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final actif = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: actif ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: actif ? AppColors.accentBleu : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 56, 26, 30),
              child: PrimaryButton(label: _dernierePage ? 'Commencer' : 'Suivant', onPressed: _suivant),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideVue extends StatelessWidget {
  final _Slide slide;
  const _SlideVue({required this.slide});

  @override
  Widget build(BuildContext context) {
    final hauteurPhoto = MediaQuery.of(context).size.height * 0.56;
    return Column(
      children: [
        SizedBox(
          height: hauteurPhoto,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CarrouselPhotos(images: slide.images, couleurFond: slide.couleurIcone),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: slide.couleurIcone.withValues(alpha: 0.88),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(slide.icone, color: Colors.white, size: 56),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slide.titre, textAlign: TextAlign.center, style: AppTextStyles.headingXL()),
                const SizedBox(height: 12),
                Text(
                  slide.sousTitre,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyDefault(color: AppColors.textSecondary)
                      .copyWith(fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fait défiler automatiquement les photos d'une slide (toutes les 3 s).
class _CarrouselPhotos extends StatefulWidget {
  final List<String> images;
  final Color couleurFond;
  const _CarrouselPhotos({required this.images, required this.couleurFond});

  @override
  State<_CarrouselPhotos> createState() => _CarrouselPhotosState();
}

class _CarrouselPhotosState extends State<_CarrouselPhotos> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      _index = (_index + 1) % widget.images.length;
      _controller.animateToPage(_index, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.images.length,
      itemBuilder: (context, i) => Image.asset(
        widget.images[i],
        fit: BoxFit.cover,
        width: double.infinity,
        // Photo pas encore ajoutée : fond uni plutôt qu'un écran cassé.
        errorBuilder: (context, error, stackTrace) =>
            Container(color: widget.couleurFond.withValues(alpha: 0.25)),
      ),
    );
  }
}
