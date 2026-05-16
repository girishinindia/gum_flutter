// Section header — eyebrow + h2 + "See all" chip on the right.
//
// Used by every horizontal carousel on the home screen so the rhythm
// stays consistent (categories, popular courses, webinars, bundles,
// instructors, reviews).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../theming/theme_controller.dart';

class SectionHeader extends StatelessWidget {
  // Non-const so the default padding can be responsive per context.
  // Callsites use `SectionHeader(...)` (no const). Override `padding`
  // explicitly for any non-standard layout.
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onSeeAll,
    this.padding,
  });

  final String        eyebrow;
  final String        title;
  final VoidCallback? onSeeAll;
  final EdgeInsets?   padding;

  @override
  Widget build(BuildContext context) {
    // Default = responsive: section gap on top, header-to-cards on
    // bottom. Both scale 16 → 22 → 28 from phone to tablet.
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(
          AppSpacing.sectionHeaderGutter,
          AppSpacing.sectionFor(context),
          AppSpacing.sectionHeaderGutter,
          AppSpacing.headerToContentFor(context),
        );

    // Title color follows the active theme's page-bg luminance — flips
    // from slate-900 (light themes) to near-white (dark themes) so it
    // stays readable when the scaffold is painted in Purple Haze /
    // Obsidian / Ember etc. Eyebrow keeps its brand colour because the
    // brand hues already contrast against both light and dark page bg.
    final palette = context.watch<ThemeController>().palette;

    return Padding(
      padding: effectivePadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: AppTypography.eyebrow
                    .copyWith(color: palette.accentOnPageBg),
              ),
              const SizedBox(height: AppSpacing.eyebrowToTitle),
              Text(
                title,
                style: AppTypography.h2.copyWith(color: palette.onPageBg),
              ),
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
