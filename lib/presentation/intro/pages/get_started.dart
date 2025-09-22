import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:spotify_app/presentation/choose%20mode/pages/choose_mode.dart';

import '../../../core/configs/assets/app_images.dart';
import '../../../core/configs/assets/app_vectors.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _floatingController;

  // chỉ còn fade của nội dung & glow của logo
  late Animation<Offset> _contentSlide;
  late Animation<double> _contentFade;
  late Animation<double> _glowOpacity; // glow 0→1→0
  late Animation<double> _titleGlassOpacity; // nền glass sau title mờ dần
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _contentController, curve: Curves.easeOutCubic));

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _contentController, curve: const Interval(0.3, 1.0)));

    _floatingAnimation = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut));

    // Glow logo: 0 -> 1 -> 0
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_logoController);

    // Nền glass phía sau title: hiện ra rồi tắt dần
    _titleGlassOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
    ]).animate(_contentController);

    // start animations
    _logoController.forward();
    Future.delayed(
        const Duration(milliseconds: 500), _contentController.forward);
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // background
          Positioned.fill(
            child: Image.asset(AppImages.introBG, fit: BoxFit.cover),
          ),
          // overlay gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // floating dots
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 150 + _floatingAnimation.value,
                    right: 50,
                    child: _dot(const Color(0xFF1DB954).withOpacity(0.3), 20),
                  ),
                  Positioned(
                    top: 200 - _floatingAnimation.value * 0.5,
                    left: 40,
                    child: _dot(Colors.white.withOpacity(0.2), 15),
                  ),
                  Positioned(
                    top: 350 + _floatingAnimation.value * 0.3,
                    right: 80,
                    child: _dot(const Color(0xFF1DB954).withOpacity(0.4), 12),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                children: [
                  // LOGO: KHÔNG scale/rotate nữa – chỉ có glow mờ dần
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _glowOpacity.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1DB954)
                                        .withOpacity(0.35),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Hero(
                            tag: 'app_logo',
                            child: SvgPicture.asset(AppVectors.logo,
                                width: 80, height: 80),
                          ),
                        ],
                      );
                    },
                  ),

                  const Spacer(),

                  // Content
                  SlideTransition(
                    position: _contentSlide,
                    child: FadeTransition(
                      opacity: _contentFade,
                      child: Column(
                        children: [
                          // Title: glass nền tắt dần
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _titleGlassOpacity,
                                builder: (context, _) => Opacity(
                                  opacity: _titleGlassOpacity.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.20),
                                          width: 1),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child:
                                            const SizedBox(width: 1, height: 1),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFF1DB954),
                                    Colors.white
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Enjoy Listening\nTo Music',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 28,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Description
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.30),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                  width: 1),
                            ),
                            child: const Text(
                              'Discover a world of music tailored to your every mood, from the latest hits to timeless classics—experience the soundtrack of your life wherever you go.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Get Started
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF1DB954).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () => Navigator.of(context)
                                    .push(_enhancedPageRoute()),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Get Started',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.arrow_forward,
                                          color: Colors.white, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(size / 2)),
      );

  PageRouteBuilder _enhancedPageRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const ChooseModePage(),
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
        return Stack(
          children: [
            FadeTransition(opacity: curved, child: child),
            ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.0).animate(curved),
                child: child),
            SlideTransition(
                position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
                    .animate(curved),
                child: child),
          ],
        );
      },
    );
  }
}
