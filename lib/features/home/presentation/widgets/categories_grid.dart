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

import '../../../../core/responsive/responsive_value.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/category_item.dart';

class CategoriesGrid extends StatelessWidget {
  const CategoriesGrid({
    super.key,
    required this.items,
    this.onItemTap,
  });

  final List<CategoryItem> items;
  final ValueChanged<CategoryItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Categories sits directly under the aurora hero — uses the
      // TIGHT spacing tokens so it nestles against the gradient
      // instead of leaving a big dead band.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter, 20,
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
                    Text('EXPLORE', style: AppTypography.eyebrow),
                    const SizedBox(height: AppSpacing.eyebrowToTitle),
                    Text('Browse Categories', style: AppTypography.h2),
                  ],
                ),
                const Spacer(),
                _SeeAllChip(onTap: () {}),
              ],
            ),
          ),

          // ── 4-col grid ────────────────────────────────────────────
          // Both axes use AppSpacing.tileGap (12) for visual uniformity
          // with the carousel `cardGap` standard.
          //
          // Transform.translate physically pulls the grid UP by 16 px
          // to close the residual gap left by the h2 line-leading
          // (~5 px) + tile-centering buffer (~2 px) + whatever the
          // .animate() stagger leaves behind. Layout slot is preserved;
          // only pixels move, so nothing else on the page shifts.
          // Tweak the offset if visually too tight/loose.
          Transform.translate(
            offset: const Offset(0, -40),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              // Responsive grid delegate:
              //   • 4 cols on phones, 6 on tablet-portrait, 8 on tablet-landscape
              //   • tile height bumps from 96 → 110 on tablets so the
              //     larger tile width doesn't make them look squat
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: R<int>(
                  normal:  4,
                  tabletP: 6,
                  tabletL: 8,
                ).resolve(context),
                mainAxisSpacing:  AppSpacing.tileGap,
                crossAxisSpacing: AppSpacing.tileGap,
                mainAxisExtent: R<double>(
                  normal:  96,
                  tabletP: 110,
                ).resolve(context),
              ),
              itemBuilder: (context, i) {
                final item = items[i];
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
}

// ─────────────────────────────────────────────────────────────────────
// Individual tile
// ─────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.onTap});

  final CategoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        splashColor: item.glowTint.withValues(alpha: 0.08),
        highlightColor: item.glowTint.withValues(alpha: 0.04),
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
                        item.glowTint.withValues(alpha: 0.22),
                        item.glowTint.withValues(alpha: 0.0),
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
                        item.glowTint.withValues(alpha: 0.0),
                        item.glowTint.withValues(alpha: 0.85),
                        item.glowTint.withValues(alpha: 0.0),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),

              // Content — Positioned.fill so the Column receives the
              // full tile height & width; otherwise mainAxisAlignment
              // .center has nothing to centre against (a bare Padding
              // inside a Stack sizes to its child and anchors top-start).
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _IconChip(
                        icon: item.icon,
                        gradient: item.iconGradient,
                        tint: item.glowTint,
                      ),
                      const SizedBox(height: 8),
                      // FittedBox scales long labels (e.g. "Marketing")
                      // down so they fit a 60–80 px tile width without
                      // ellipsis on any device size.
                      SizedBox(
                        height: 14,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: AppTypography.h3.copyWith(
                              fontSize: 12,
                              letterSpacing: -0.1,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 12,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.subtitle,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.slate500,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
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
