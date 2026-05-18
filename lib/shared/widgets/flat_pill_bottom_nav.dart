// Flat-pill bottom navigation — the opt-in alternative to CurvedBottomNav.
//
// Visual spec (mirrors the screenshot the user shared in Phase 43.15):
//   • Flat opaque surface, 24 pt rounded top corners
//   • 4 standard items (icon + label) flanking a raised central FAB
//   • Central FAB is a ROTATED SQUARE (diamond, π/4 rotation) filled
//     with the active palette's brandGradient — visually distinct from
//     the existing CurvedBottomNav's circular FAB
//   • Active item: palette.primary500 icon + bold matching-color label
//     + 4-pt round dot underneath
//   • Inactive item: slate-500 (chrome muted) icon + medium-weight label
//   • Safe-area aware: total height = 72 pt + viewPadding.bottom, label
//     anchor stays 8 pt above the safe-area boundary on every device
//   • Theme-aware: every accent re-tints when ThemeController.palette
//     changes (no hardcoded blues anywhere)
//   • Responsive: item width and icon size adapt to phone vs tablet
//
// API parity with CurvedBottomNav so the home screen can swap one for
// the other via a single conditional. Same field names, same order.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/theming/theme_controller.dart';
import 'curved_bottom_nav.dart' show CurvedNavItem;

// Re-export the item type so the home screen can keep using `CurvedNavItem`
// regardless of which silhouette is active. Avoids a parallel item class.

class FlatPillBottomNav extends StatelessWidget {
  const FlatPillBottomNav({
    super.key,
    required this.size,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onFabTapped,
    required this.items,
  });

  final Size              size;
  final int               selectedIndex;
  final ValueChanged<int> onItemTapped;
  final VoidCallback      onFabTapped;

  /// Exactly 4 items — 2 left of the FAB, 2 right of it (matches the
  /// existing CurvedBottomNav contract).
  final List<CurvedNavItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'FlatPillBottomNav expects exactly 4 items.');

    final palette     = context.watch<ThemeController>().palette;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final width       = size.width;

    // ── Responsive metrics ─────────────────────────────────────────────
    // < 380 pt → compact phones (older Androids), 380–600 → modern
    // phones, ≥ 600 → tablets. On tablets we cap the content width to
    // 600 pt and center it so the nav doesn't stretch into a wide bar.
    final compact   = width < 380;
    final isTablet  = width >= 600;
    final iconSize  = compact ? 22.0 : (isTablet ? 26.0 : 24.0);
    final fabSize   = compact ? 44.0 : (isTablet ? 56.0 : 50.0);
    final labelSize = compact ? 10.0 : (isTablet ? 12.0 : 11.0);

    const itemBandHeight = 72.0;
    final totalHeight    = itemBandHeight + bottomInset;
    final contentWidth   = isTablet ? 600.0 : width;
    final hPad           = isTablet ? 24.0 : (compact ? 8.0 : 12.0);

    // ── Theme-aware colors ─────────────────────────────────────────────
    // Surface: bright chromeSurface in light themes, the same Color in
    // dark themes (each palette already picks a contrasting surface for
    // its chrome). active = primary500. inactive = chromeMuted with
    // enough contrast to read on the chosen surface.
    final surfaceColor    = palette.chromeSurface;
    final outlineColor    = palette.chromeOutline;
    final activeColor     = palette.primary500;
    final inactiveColor   = palette.onChromeMuted;
    final inactiveLabelColor = palette.onChrome.withValues(alpha: 0.72);

    return SizedBox(
      width: width,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Pill surface ─────────────────────────────────────────────
          // Painted over the full totalHeight so the surface flows
          // behind the system gesture pill / home indicator (same
          // pattern as Phase 43.12's CurvedBottomNav extension).
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft:  Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: outlineColor, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                    spreadRadius: -2,
                  ),
                ],
              ),
            ),
          ),

          // ── Diamond FAB — raised, centered ──────────────────────────
          Positioned(
            top:  -fabSize * 0.30,   // peek roughly 30 % above the pill
            left: (width - fabSize) / 2,
            child: _DiamondFab(
              size: fabSize,
              gradient: palette.brandGradient,
              ringColor: surfaceColor,
              accentShadow: palette.primary500,
              showBadge: items.any((i) => i.badge && items.indexOf(i) >= 2),
              onTap: onFabTapped,
            ),
          ),

          // ── Items row, pinned to top 72 pt of the band ──────────────
          Positioned(
            top: 0, left: 0, right: 0, height: itemBandHeight,
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FlatNavItem(
                        item: items[0],
                        isSelected: selectedIndex == 0,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        activeColor: activeColor,
                        inactiveIconColor: inactiveColor,
                        inactiveLabelColor: inactiveLabelColor,
                        onTap: () => _tap(0),
                      ),
                      _FlatNavItem(
                        item: items[1],
                        isSelected: selectedIndex == 1,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        activeColor: activeColor,
                        inactiveIconColor: inactiveColor,
                        inactiveLabelColor: inactiveLabelColor,
                        onTap: () => _tap(1),
                      ),
                      // Phantom slot the FAB sits in — same width as a
                      // standard item so the row stays evenly spaced.
                      SizedBox(width: fabSize + 8),
                      _FlatNavItem(
                        item: items[2],
                        isSelected: selectedIndex == 2,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        activeColor: activeColor,
                        inactiveIconColor: inactiveColor,
                        inactiveLabelColor: inactiveLabelColor,
                        onTap: () => _tap(2),
                      ),
                      _FlatNavItem(
                        item: items[3],
                        isSelected: selectedIndex == 3,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        activeColor: activeColor,
                        inactiveIconColor: inactiveColor,
                        inactiveLabelColor: inactiveLabelColor,
                        onTap: () => _tap(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _tap(int i) {
    HapticFeedback.selectionClick();
    onItemTapped(i);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Diamond (rotated-square) FAB
// ─────────────────────────────────────────────────────────────────────

class _DiamondFab extends StatelessWidget {
  const _DiamondFab({
    required this.size,
    required this.gradient,
    required this.ringColor,
    required this.accentShadow,
    required this.showBadge,
    required this.onTap,
  });

  final double         size;
  final LinearGradient gradient;
  /// Surface the FAB sits in front of — used for the outer "halo" ring
  /// that visually separates the FAB from the pill.
  final Color  ringColor;
  /// Drop-shadow tint — matches the active palette's primary so the
  /// FAB doesn't feel disconnected from the brand.
  final Color  accentShadow;
  final bool   showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size, height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Rotated square (diamond) with brandGradient fill + white
            // halo border so it pops off the pill surface.
            Transform.rotate(
              angle: 0.785398, // π / 4 → 45°
              child: Container(
                width:  size * 0.78,
                height: size * 0.78,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ringColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: accentShadow.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ],
                ),
              ),
            ),
            // Icon stays UPRIGHT (not rotated) so it reads naturally.
            Icon(
              Icons.shopping_basket_rounded,
              color: Colors.white,
              size: size * 0.42,
            ),
            // Optional notification badge — top-right of the diamond.
            if (showBadge)
              Positioned(
                top:  size * 0.05,
                right: size * 0.05,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.7),
                        blurRadius: 6,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Standard nav item — icon + label + optional badge + selection dot.
// ─────────────────────────────────────────────────────────────────────

class _FlatNavItem extends StatelessWidget {
  const _FlatNavItem({
    required this.item,
    required this.isSelected,
    required this.iconSize,
    required this.labelSize,
    required this.activeColor,
    required this.inactiveIconColor,
    required this.inactiveLabelColor,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool          isSelected;
  final double        iconSize;
  final double        labelSize;
  final Color         activeColor;
  final Color         inactiveIconColor;
  final Color         inactiveLabelColor;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor  = isSelected ? activeColor : inactiveIconColor;
    final labelColor = isSelected ? activeColor : inactiveLabelColor;

    return InkResponse(
      onTap: onTap,
      radius: 32,
      highlightColor: activeColor.withValues(alpha: 0.06),
      splashColor:    activeColor.withValues(alpha: 0.10),
      child: SizedBox(
        width: 60,
        // Same 72-pt band as CurvedBottomNav (Phase 43.14) — labels
        // anchored to the bottom so they sit a fixed 8 pt above the
        // safe-area boundary, regardless of phone vs tablet.
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(item.icon, color: iconColor, size: iconSize),
                if (item.badge)
                  Positioned(
                    top: -2,
                    right: -6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withValues(alpha: 0.7),
                            blurRadius: 6,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTypography.caption.copyWith(
                color: labelColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: labelSize,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 3),
            // Selection dot — animates in/out so the transition feels
            // smooth when the user taps a different item.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width:  isSelected ? 6 : 0,
              height: isSelected ? 6 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.50),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ]
                    : null,
              ),
            ),
            // Bottom padding so the dot sits 8 pt above the safe-area
            // boundary on every device — matches CurvedBottomNav.
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
