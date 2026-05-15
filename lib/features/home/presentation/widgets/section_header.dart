// Section header — eyebrow + h2 + "See all" chip on the right.
//
// Used by every horizontal carousel on the home screen so the rhythm
// stays consistent (categories, popular courses, webinars, bundles,
// instructors, reviews).

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  // Const constructor — every callsite can keep using `const
  // SectionHeader(...)`. All defaults are compile-time constants
  // pulled from AppSpacing.
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onSeeAll,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.sectionHeaderGutter,  // 20
      AppSpacing.section,              // 30  (inter-section gap)
      AppSpacing.sectionHeaderGutter,  // 20
      AppSpacing.headerToContent,      // 20  (header → cards)
    ),
  });

  final String        eyebrow;
  final String        title;
  final VoidCallback? onSeeAll;
  final EdgeInsets    padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: AppTypography.eyebrow),
              const SizedBox(height: AppSpacing.eyebrowToTitle),
              Text(title,   style: AppTypography.h2),
            ],
          ),
          const Spacer(),
          _SeeAllChip(onTap: onSeeAll ?? () {}),
        ],
      ),
    );
  }
}

class _SeeAllChip extends StatelessWidget {
  const _SeeAllChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: AppRadius.rPill,
          border: Border.all(color: AppColors.brand200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'See all',
              style: AppTypography.caption.copyWith(
                color: AppColors.brand700,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded,
                size: 13, color: AppColors.brand700),
          ],
        ),
      ),
    );
  }
}
