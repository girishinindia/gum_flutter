// Featured-course spotlight card.
//
// Sits between the categories grid and the "Popular courses" carousel
// to break up the visual rhythm with a single big, opinionated tile.
// Designed to draw the eye to whichever cohort / launch we want to
// promote that month — wired today to the AI & ML Pro entry from the
// seed data, but the inputs are plain primitives so the home screen
// can pass in anything.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradient,
    required this.icon,
    this.badge,
    this.onTap,
  });

  final String        eyebrow;     // "FEATURED COHORT"
  final String        title;       // "AI & Machine Learning Pro"
  final String        subtitle;    // "Live mentor sessions · placement guarantee"
  final String        cta;         // "Reserve your seat"
  final List<Color>   gradient;    // background gradient
  final IconData      icon;        // big right-side glyph
  final String?       badge;       // small pill in the corner — "NEW", "HOT"…
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sides only; Transform.translate below pulls the card UP into
      // the slot left by the section above. The matching wrapper in
      // home_screen.dart pulls all subsequent sections by the same
      // -100 so the cascade stays consistent.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter, 0,
        AppSpacing.pageGutter, 0,
      ),
      child: Transform.translate(
        offset: const Offset(0, -100),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          borderRadius: AppRadius.rXl,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: AppRadius.rXl,
              boxShadow: AppRadius.heroShadow,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.rXl,
              child: Stack(
                children: [
                  // ── Decorative right-side icon orb ─────────────────
                  Positioned(
                    right: -28,
                    bottom: -28,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: Icon(
                      icon,
                      color: Colors.white.withValues(alpha: 0.22),
                      size: 120,
                    ),
                  ),

                  // ── Body content ───────────────────────────────────
                  Padding(
                    // Tight top (10) so the eyebrow pill sits near
                    // the top of the gradient — keeps the card short.
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.rPill,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.32),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                eyebrow,
                                style: AppTypography.eyebrow.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              _Pulse(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
                                    borderRadius: AppRadius.rPill,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.amber
                                            .withValues(alpha: 0.55),
                                        blurRadius: 12,
                                        spreadRadius: -2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt_rounded,
                                          size: 11, color: Colors.white),
                                      const SizedBox(width: 3),
                                      Text(
                                        badge!,
                                        style:
                                            AppTypography.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 240,
                          child: Text(
                            title,
                            style: AppTypography.h1.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 250,
                          child: Text(
                            subtitle,
                            style: AppTypography.bodySm.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _CtaPill(label: cta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────
// CTA — small white pill with arrow
// ─────────────────────────────────────────────────────────────────────

class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.rPill,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.buttonLabel.copyWith(
              color: AppColors.accent600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded,
              size: 16, color: AppColors.accent600),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Pulse animation wrapper for the "HOT" badge.
// ─────────────────────────────────────────────────────────────────────

class _Pulse extends StatelessWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.06, duration: 900.ms, curve: Curves.easeInOut);
  }
}
