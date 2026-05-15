// Course-bundle horizontal carousel.
//
// Each card is a gradient panel pushing the "save X%" story:
//   • bundle icon + course-count chip in the top-left
//   • savings badge in the top-right (animated pulse)
//   • title + subtitle
//   • bottom row — strike-through MRP, bundle price, "Get Bundle" CTA

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/course_bundle.dart';
import 'section_header.dart';

class BundlesSection extends StatelessWidget {
  const BundlesSection({super.key, required this.items});
  final List<CourseBundle> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(eyebrow: 'BEST VALUE', title: 'Course Bundles'),
        // Bundle card uses an internal `Spacer` — needs a bounded
        // height. Wrap the row in IntrinsicHeight so the tallest
        // card's height becomes the row height, and Spacer works
        // within that bounded height. crossAxisAlignment.stretch
        // makes every card take the same height (the max).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.cardGap),
                  _BundleCard(
                    bundle: items[i],
                    onTap: () => HapticFeedback.selectionClick(),
                  ).animate(delay: (60 * i).ms).fadeIn(duration: 380.ms).slideX(
                        begin: 0.08, end: 0, curve: Curves.easeOutCubic,
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.bundle, required this.onTap});
  final CourseBundle bundle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rLg,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bundle.cover,
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
              borderRadius: AppRadius.rLg,
              boxShadow: AppRadius.heroShadow,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.rLg,
              child: Stack(
                children: [
                  // Decorative orb (top-right corner)
                  Positioned(
                    right: -28, top: -28,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.20),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12, top: 14,
                    child: _SavingsBadge(label: bundle.savingsLabel),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon + course count
                        Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Icon(bundle.icon, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.rPill,
                              ),
                              child: Text(
                                '${bundle.courseCount} courses',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          bundle.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bundle.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              bundle.displayBundlePrice,
                              style: AppTypography.h2.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                bundle.displayTotalPrice,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _GetBundleCta(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsBadge extends StatelessWidget {
  const _SavingsBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: AppRadius.rPill,
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.55),
            blurRadius: 12, spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .scaleXY(begin: 1.0, end: 1.05, duration: 900.ms, curve: Curves.easeInOut);
  }
}

class _GetBundleCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.rPill,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14, offset: const Offset(0, 6), spreadRadius: -3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Get',
            style: AppTypography.buttonLabel.copyWith(
              color: AppColors.accent600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded,
              color: AppColors.accent600, size: 14),
        ],
      ),
    );
  }
}
