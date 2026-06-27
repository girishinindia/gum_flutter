// Premium category grid — 4-column tile rail under the hero.
//
// Each tile is a 3-layer construction:
//   layer 1 — white card with `cardShadow` (subtle lift)
//   layer 2 — radial pastel glow in the top-right corner
//   layer 3 — coloured bottom accent line that matches the icon family
//
// The icon chip itself is a 2-stop gradient with an inset highlight
// and a `tintedChipShadow` so each family carries its own colour story
// without us having to bake six different background pictures.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/responsive/responsive_value.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../catalog/data/category_icon_styles.dart';
import '../../../catalog/domain/sub_category.dart';
import '../../../theming/theme_controller.dart';
import '../../../i18n/messages.dart';

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({
    super.key,
    required this.items,
    required this.t,
    this.onItemTap,
    this.isLoading = false,
    this.previewLimit = 6,
  });

  /// Items now come from the API (`CategoriesController.displayed`).
  /// Pre-resolved `displayName` already handles the translation +
  /// fallback chain — the tile just renders it.
  final List<SubCategory> items;

  /// Cap on how many tiles we render on the home. The "See all" chip
  /// in the section header already routes users to the full list, so
  /// the grid only needs to surface the first N. 8 = 2 rows × 4 cols
  /// on phones (and a clean 1 / 1 / 1 row on tablets at 6 / 8 cols).
  /// Set to `null` to render every item.
  final int? previewLimit;

  /// Translated UI strings (eyebrow, title, "See all").
  final Messages t;

  /// True while the boot fetch is in flight — show a shimmer skeleton.
  final bool isLoading;

  final ValueChanged<SubCategory>? onItemTap;

  @override
  Widget build(BuildContext context) {
    // Cap the displayed list — the "See all" chip handles overflow.
    // `take(min(items.length, limit))` would do the same, but `sublist`
    // produces a List that GridView.builder can length-check cheaply.
    final visible = (previewLimit != null && items.length > previewLimit!)
        ? items.sublist(0, previewLimit!)
        : items;

    // Title color flips to near-white on dark themes (Purple Haze /
    // Obsidian / Ember / etc.) — see SectionHeader for the same logic.
    final palette = context.watch<ThemeController>().palette;

    return Padding(
      // Top = responsive sectionTightFor (10 / 16 / 20 per breakpoint).
      // Categories sits directly under the aurora hero — tighter than
      // a normal section because the gradient already separates them.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageGutter, AppSpacing.sectionTightFor(context),
        AppSpacing.pageGutter, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────
          // Uses `headerToContentTight` so the eyebrow + title sit
          // close to the tiles below them.
          Padding(
            padding: const EdgeInsets.only(
              bottom: 0,
              top: 0
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.exploreEyebrow,
                      style: AppTypography.eyebrow
                          .copyWith(color: palette.accentOnPageBg),
                    ),
                    const SizedBox(height: AppSpacing.eyebrowToTitle),
                    Text(
                      t.browseCategoriesTitle,
                      style: AppTypography.h2.copyWith(color: palette.onPageBg),
                    ),
                  ],
                ),
                const Spacer(),
                _SeeAllChip(label: t.seeAll, onTap: () {}),
              ],
            ),
          ),

          // ── Responsive grid with Transform.translate pull-up ─────
          // -10 px is the safe value across iOS + Android. Tighter
          // offsets (we tried -40) caused the "Browse Categories"
          // title to overlap the first tile row on tighter-metric
          // Android devices (Samsung S20 FE, OnePlus, Pixel). -10
          // shaves off enough line-leading to look tight without
          // ever crossing into overlap territory.
          Transform.translate(
            offset: const Offset(0, -20),
            child: isLoading
                ? _skeletonGrid(context)
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                // 3 columns on phones = 6 tiles in 2 rows (matches the
                // 6-cap above). On tablets we keep 6 in a single row so
                // the wider viewport doesn't collapse the section into
                // a half-empty visual block.
                crossAxisCount: R<int>(
                  normal:  3,
                  tabletP: 6,
                  tabletL: 6,
                ).resolve(context),
                mainAxisSpacing:  AppSpacing.tileGap,
                crossAxisSpacing: AppSpacing.tileGap,
                // Slightly taller tiles than before — 3-col phones give
                // each tile more width, and the label is no longer
                // shrink-fitted so 2-line names ("Programming Languages",
                // "Data Science & Analytics", "साइबर सुरक्षा") need room.
                mainAxisExtent: R<double>(
                  normal:  118,
                  tabletP: 124,
                ).resolve(context),
              ),
              itemBuilder: (context, i) {
                final item = visible[i];
                return _CategoryTile(
                  item: item,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onItemTap?.call(item);
                  },
                // No slideY — the 12% downward translate was adding
                // ~11 px of perceived empty space above each tile while
                // the entry stagger played out, which read as extra
                // header-to-tile gap. Plain fadeIn keeps it crisp.
                ).animate(delay: (60 * i).ms).fadeIn(duration: 380.ms);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer skeleton shown while the `/sub-categories` boot fetch is in
  /// flight — same grid metrics as the real tiles so nothing jumps when the
  /// data lands. Gives the student an unmistakable "loading…" signal instead
  /// of a blank gap.
  Widget _skeletonGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: previewLimit ?? 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: R<int>(normal: 3, tabletP: 6, tabletL: 6).resolve(context),
        mainAxisSpacing: AppSpacing.tileGap,
        crossAxisSpacing: AppSpacing.tileGap,
        mainAxisExtent: R<double>(normal: 118, tabletP: 124).resolve(context),
      ),
      itemBuilder: (_, __) => const _SkeletonTile(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Loading skeleton tile — a real white card with shimmering grey shapes.
// ─────────────────────────────────────────────────────────────────────

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.slate200,
            borderRadius: BorderRadius.circular(4),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: AppRadius.cardShadow,
        border: Border.all(color: AppColors.outlineSoft, width: 1),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.slate200,
        highlightColor: AppColors.slate50,
        period: const Duration(milliseconds: 1300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // icon-chip placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),
            bar(58, 9),  // title line
            const SizedBox(height: 6),
            bar(34, 7),  // subtitle line
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Individual tile
// ─────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});

  final SubCategory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Slug-driven visual treatment — icon, gradient, glow tint all
    // derive from a frontend lookup table since the API doesn't carry
    // Material icon code-points. Unknown slugs get a safe fallback.
    final style = CategoryIconStyles.forSlug(item.slug);

    // Subtitle: derive from courseCount (with a tiny humanisation).
    // Falls back to empty string — the FittedBox below just collapses.
    final subtitle = item.courseCount > 0
        ? '${item.courseCount} courses'
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        splashColor: style.glowTint.withValues(alpha: 0.08),
        highlightColor: style.glowTint.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rLg,
            boxShadow: AppRadius.cardShadow,
            border: Border.all(color: AppColors.outlineSoft, width: 1),
          ),
          child: Stack(
            children: [
              // Radial glow corner — gives the white card a subtle
              // family-colour halo without flooding the surface.
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        style.glowTint.withValues(alpha: 0.22),
                        style.glowTint.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Coloured bottom accent line.
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        style.glowTint.withValues(alpha: 0.0),
                        style.glowTint.withValues(alpha: 0.85),
                        style.glowTint.withValues(alpha: 0.0),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),

              // Content — Positioned.fill so the Column receives the
              // full tile height & width.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _IconChip(
                        icon: style.icon,
                        gradient: style.iconGradient,
                        tint: style.glowTint,
                      ),
                      const SizedBox(height: 8),
                      // Fixed font size across every tile (no FittedBox
                      // scaling), so the grid reads as a uniform set.
                      // Long names ("Programming Languages", "Data
                      // Science & Analytics") wrap to 2 lines; anything
                      // longer is ellipsised. Centered for visual rhythm
                      // with the icon chip above.
                      Text(
                        item.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.h3.copyWith(
                          fontSize: 12,
                          letterSpacing: -0.1,
                          height: 1.15,
                        ),
                      ),
                      // Subtitle (e.g. "12 courses") sits below in a
                      // consistent slate-500 caption. Hidden when empty
                      // so the column doesn't reserve a phantom slot.
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.slate500,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Icon chip — 2-tone gradient + inset highlight + tinted shadow.
// ─────────────────────────────────────────────────────────────────────

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.gradient,
    required this.tint,
  });

  final IconData     icon;
  final List<Color>  gradient;
  final Color        tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppRadius.tintedChipShadow(tint),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
      ),
      child: Stack(
        children: [
          // Top inset highlight — gives the chip a 3D / glossy feel.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end:   Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.32),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// "See all" chip
// ─────────────────────────────────────────────────────────────────────

class _SeeAllChip extends StatelessWidget {
  const _SeeAllChip({required this.label, required this.onTap});
  final String       label;
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
              label,
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
