import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:spotify_app/common/helpers/is_dark_mode.dart';
import 'package:spotify_app/common/widgets/button/basic_app_button.dart';
import 'package:spotify_app/core/configs/assets/app_images.dart';
import 'package:spotify_app/core/configs/assets/app_vectors.dart';
import 'package:spotify_app/core/configs/theme/app_colors.dart';
import 'package:spotify_app/presentation/auth/pages/signin.dart';

import '../../../common/widgets/appbar/app_bar.dart';
import 'signup.dart';

class SignupOrSigninPage extends StatefulWidget {
  const SignupOrSigninPage({super.key});

  @override
  State<SignupOrSigninPage> createState() => _SignupOrSigninPageState();
}

class _SignupOrSigninPageState extends State<SignupOrSigninPage>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BasicAppBar(),
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(AppVectors.topPattern),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SvgPicture.asset(AppVectors.bottomPattern),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(AppImages.authBG),
          ),

          // Glow bubbles (floating)
          AnimatedBuilder(
            animation: _float,
            builder: (_, __) => Stack(
              children: [
                _bubble(
                  top: 140 + _float.value,
                  right: 48,
                  size: 26,
                  color: const Color(0xFF1DB954),
                  intensity: .45,
                ),
                _bubble(
                  top: 220 - _float.value * .5,
                  left: 40,
                  size: 18,
                  color: Colors.white,
                  intensity: .25,
                ),
                _bubble(
                  top: 360 + _float.value * .3,
                  right: 86,
                  size: 16,
                  color: const Color(0xFF1DB954),
                  intensity: .55,
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo — bỏ nền glass, chỉ để logo sạch
                  SvgPicture.asset(AppVectors.logo, width: 84, height: 84),
                  const SizedBox(height: 40),

                  // Title — bỏ nền, giữ gradient chữ cho nổi
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFF1DB954), Colors.white],
                    ).createShader(bounds),
                    child: const Text(
                      'Enjoy Listening To Music',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white, // bị ShaderMask phủ
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Spotify is a proprietary Swedish audio streaming and media services provider',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color:
                          context.isDarkMode ? AppColors.grey : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildGlassButton(
                          context: context,
                          title: 'Register',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupPage(),
                              ),
                            );
                          },
                          isPrimary: true,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildGlassButton(
                          context: context,
                          title: 'Sign in',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SigninPage(),
                              ),
                            );
                          },
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- glow bubble helper ----
  Widget _bubble({
    double? top,
    double? left,
    double? right,
    required double size,
    required Color color,
    double intensity = .5,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // lõi phát sáng
          gradient: RadialGradient(
            colors: [
              color.withOpacity(intensity),
              color.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
          // bóng mờ lan rộng
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(intensity),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  // ---- button glass helper (giữ nguyên UI nút) ----
  Widget _buildGlassButton({
    required BuildContext context,
    required String title,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF1DB954).withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFF1DB954).withOpacity(0.4)
                  : Colors.white.withOpacity(0.3),
              width: isPrimary ? 2 : 1.5,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFF1DB954).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onPressed,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPrimary
                        ? Colors.white
                        : (context.isDarkMode ? Colors.white : Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
