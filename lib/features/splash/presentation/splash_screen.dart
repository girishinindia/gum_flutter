// Splash screen — first paint while we boot the home tree.
//
// Lifted out of the legacy flat `lib/splash_screen.dart` into a
// feature-first location and re-skinned with the aurora gradient so
// the brand identity hits before the user even sees the home.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2200), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, animation, __, child) {
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: fade, child: child);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sky900,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Aurora background
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.auroraGradient),
          ),

          // Glow orbs for depth (same idea as desktop floating-orbs)
          Positioned(
            top: -120,
            right: -100,
            child: _Orb(size: 360, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _Orb(size: 320, color: AppColors.violet300.withValues(alpha: 0.22)),
          ),

          // Subtle dot-grid texture overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Brand mark — graduation chip + SVG wordmark
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 700)),
                    SlideEffect(begin: Offset(0, 0.12), duration: Duration(milliseconds: 700), curve: Curves.easeOutCubic),
                  ],
                  child: Column(
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.10)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 22),
                      SvgPicture.asset(
                        AppAssets.brandLogoSvg,
                        height: 44,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Growing Beyond Limits",
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Footer tagline
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 900), delay: Duration(milliseconds: 400)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Column(
                      children: [
                        // Mini loader dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5 + (i * 0.15)),
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(begin: const Offset(1, 1), end: const Offset(1.4, 1.4), duration: const Duration(milliseconds: 700), delay: Duration(milliseconds: 200 * i)),
                              if (i < 2) const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Welcome to Grow Up More — your ultimate platform for e-learning and growth.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
