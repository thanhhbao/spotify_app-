import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:spotify_app/presentation/choose%20mode/bloc/theme_cubit.dart';
import '../../../core/configs/assets/app_images.dart';
import '../../../core/configs/assets/app_vectors.dart';
import '../../auth/pages/signup_or_signin.dart';

class ChooseModePage extends StatefulWidget {
  const ChooseModePage({super.key});

  @override
  State<ChooseModePage> createState() => _ChooseModePageState();
}

class _ChooseModePageState extends State<ChooseModePage>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _floatCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
  late Animation<Offset> _cardsSlide;
  late Animation<double> _cardsFade;
  late Animation<double> _float;

  ThemeMode? _selected;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _contentCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _floatCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Logo vẫn scale/rotate (nếu muốn tắt luôn, có thể đặt begin=end và bỏ Transform)
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.elasticOut));

    _logoRotate = Tween<double>(begin: -0.4, end: 0.0).animate(
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutBack));

    _cardsSlide = Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic));

    _cardsFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    _float = Tween<double>(begin: -10, end: 10)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), _contentCtrl.forward);
    _floatCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _choose(ThemeMode m) {
    setState(() => _selected = m);
    context.read<ThemeCubit>().updateTheme(m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // background
          Positioned.fill(
            child: Image.asset(AppImages.chooseModeBG, fit: BoxFit.cover),
          ),
          // overlay gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.35),
                    Colors.black.withOpacity(.15),
                    Colors.black.withOpacity(.65),
                  ],
                  stops: const [0, .5, 1],
                ),
              ),
            ),
          ),

          // floating dots
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Stack(
              children: [
                _dot(
                    top: 140 + _float.value,
                    right: 50,
                    size: 18,
                    color: const Color(0xFF1DB954).withOpacity(.35)),
                _dot(
                    top: 210 - _float.value * .4,
                    left: 36,
                    size: 14,
                    color: Colors.white.withOpacity(.22)),
                _dot(
                    top: 340 + _float.value * .25,
                    right: 86,
                    size: 12,
                    color: const Color(0xFF1DB954).withOpacity(.45)),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Column(
                children: [
                  // Logo — đã bỏ hoàn toàn lớp glow mờ
                  AnimatedBuilder(
                    animation: _headerCtrl,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotate.value,
                          child: SvgPicture.asset(
                            AppVectors.logo,
                            width: 80,
                            height: 80,
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFF1DB954), Colors.white],
                    ).createShader(bounds),
                    child: const Text(
                      'Choose Mode',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // 2 mode cards
                  FadeTransition(
                    opacity: _cardsFade,
                    child: SlideTransition(
                      position: _cardsSlide,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _modeCard(
                            title: 'Dark Mode',
                            icon: AppVectors.moon,
                            selected: _selected == ThemeMode.dark,
                            onTap: () => _choose(ThemeMode.dark),
                          ),
                          const SizedBox(width: 22),
                          _modeCard(
                            title: 'Light Mode',
                            icon: AppVectors.sun,
                            selected: _selected == ThemeMode.light,
                            onTap: () => _choose(ThemeMode.light),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  _primaryButton(
                    text: 'Continue',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupOrSigninPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------- widgets nhỏ --------

  Widget _dot(
      {double? top,
      double? left,
      double? right,
      required double size,
      required Color color}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(size / 2)),
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 140,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(.10),
        border: Border.all(
          width: selected ? 2 : 1,
          color: selected
              ? const Color(0xFF1DB954)
              : Colors.white.withOpacity(.25),
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF1DB954).withOpacity(.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const SizedBox(),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(.25),
                        ),
                        child: Center(
                          child: SvgPicture.asset(icon, width: 28, height: 28),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.95),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Opacity(
                        opacity: .7,
                        child: Text(
                          selected ? 'Selected' : 'Tap to choose',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          radius: 1.2,
                          colors: [
                            const Color(0xFF1DB954).withOpacity(.20),
                            Colors.transparent,
                          ],
                          center: Alignment.topLeft,
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

  Widget _primaryButton({required String text, required VoidCallback onTap}) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF1ED760)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withOpacity(.38),
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
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Continue',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
