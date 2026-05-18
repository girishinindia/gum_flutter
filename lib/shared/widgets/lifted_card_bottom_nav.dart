// Lifted-card bottom navigation — the fourth nav silhouette.
//
// Visual spec:
//   • Flat opaque base bar (uses `palette.chromeSurface`, same as the
//     flat-pill style, so all themes can render it cleanly).
//   • Active tab physically RISES above the bar inside a colored card
//     (uses `palette.brandGradient`) — same gradient as the FAB so the
//     active slot reads as a peer of the central action.
//   • The lifted card carries an outer drop-shadow so the elevation is
//     immediately legible; on dark themes the shadow is desaturated and
//     supplemented with a subtle highlight ring for the same effect.
//   • Inactive items stay flush in the bar: muted icon + label.
//   • Central FAB still pokes up — same circular basket FAB the curved
//     nav uses, so the middle action stays consistent across all four
//     styles.
//
// The lifted card animates between slots when the user taps a different
// tab — TweenAnimationBuilder over a fractional `selectedIndex`. Slots
// 0 / 1 / 2 / 3 sit symmetrically around the FAB phantom in the middle.
//
// API parity with CurvedBottomNav / FlatPillBottomNav / NotchedActive
// so the home screen swaps any of them with a single conditional.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/theming/theme_controller.dart';
import 'curved_bottom_nav.dart' show CurvedNavItem;

class LiftedCardBottomNav extends StatelessWidget {
  const LiftedCardBottomNav({
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
  final List<CurvedNavItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'LiftedCardBottomNav expects exactly 4 items.');

    final palette     = context.watch<ThemeController>().palette;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final width       = size.width;

    final compact   = width < 380;
    final isTablet  = width >= 600;
    final iconSize  = compact ? 22.0 : (isTablet ? 26.0 : 24.0);
    final labelSize = compact ? 10.0 : (isTablet ? 12.0 : 11.0);
    final fabSize   = compact ? 52.0 : (isTablet ? 64.0 : 56.0);
    final cardWidth = compact ? 60.0 : (isTablet ? 78.0 : 68.0);

    const itemBandHeight = 78.0;          // a bit taller so the lifted
                                          // card has room to peek above
    final  totalHeight   = itemBandHeight + bottomInset;
    final  contentWidth  = isTablet ? 600.0 : width;
    final  hPad          = isTablet ? 24.0 : (compact ? 6.0 : 10.0);

    // Theme-aware colors. Inactive uses the chrome's muted foreground;
    // active card pulls from brandGradient so it stays vivid on every
    // palette without us hardcoding any hex value.
    final surfaceColor      = palette.chromeSurface;
    final outlineColor      = palette.chromeOutline;
    final inactiveIconColor = palette.onChromeMuted;
    final inactiveLabelColor= palette.onChrome.withValues(alpha: 0.72);

    // 4 slot x-centers expressed as fractions of `contentWidth`.
    // Slots 0/1 left of FAB, 2/3 right of FAB. FAB owns 0.40–0.60.
    const xFracs = [0.125, 0.325, 0.675, 0.875];

    return SizedBox(
      width: width,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Flat bar surface ────────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
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

          // ── Animated lifted card under the active tab ──────────────
          TweenAnimationBuilder<double>(
            tween: Tween(begin: selectedIndex.toDouble(), end: selectedIndex.toDouble()),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              final i  = t.clamp(0.0, 3.0);
              final iL = i.floor().clamp(0, 3);
              final iR = (iL + 1).clamp(0, 3);
              final f  = (i - iL).clamp(0.0, 1.0);
              final frac = (xFracs[iL] * (1 - f)) + (xFracs[iR] * f);
              // Apply tablet center-cap. The slot lives in the centered
              // content strip, not the full screen width.
              final centerOffset = (width - contentWidth) / 2;
              final cx = centerOffset + frac * contentWidth;

              return Positioned(
                top: -10,
                left: cx - cardWidth / 2,
                child: _LiftedCard(
                  width: cardWidth,
                  height: 64,
                  gradient: palette.brandGradient,
                  accentShadow: palette.primary500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[selectedIndex].icon,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[selectedIndex].label,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: labelSize - 0.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Central FAB ─────────────────────────────────────────────
          Positioned(
            top: -fabSize * 0.30,
            left: (width - fabSize) / 2,
            child: _FabCircle(
              size: fabSize,
              gradient: palette.brandGradient,
              ringColor: surfaceColor,
              accent: palette.primary500,
              onTap: onFabTapped,
            ),
          ),

          // ── Items row — inactive items show flush in the bar; the
          //    ACTIVE item leaves an empty slot beneath its lifted card
          //    (just the tap target, no icon/label rendered here).
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
                      _NavSlot(
                        item: items[0],
                        isSelected: selectedIndex == 0,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        iconColor: inactiveIconColor,
                        labelColor: inactiveLabelColor,
                        onTap: () => _tap(0),
                      ),
                      _NavSlot(
                        item: items[1],
                        isSelected: selectedIndex == 1,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        iconColor: inactiveIconColor,
                        labelColor: inactiveLabelColor,
                        onTap: () => _tap(1),
                      ),
                      SizedBox(width: fabSize + 8),
                      _NavSlot(
                        item: items[2],
                        isSelected: selectedIndex == 2,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        iconColor: inactiveIconColor,
                        labelColor: inactiveLabelColor,
                        onTap: () => _tap(2),
                      ),
                      _NavSlot(
                        item: items[3],
                        isSelected: selectedIndex == 3,
                        iconSize: iconSize,
                        labelSize: labelSize,
                        iconColor: inactiveIconColor,
                        labelColor: inactiveLabelColor,
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
// The card that rises above the bar to host the active tab's icon +
// label. Pulled into its own widget so we can drop a `Hero`-style
// transition in later if we want even fancier moves.
// ─────────────────────────────────────────────────────────────────────

class _LiftedCard extends StatelessWidget {
  const _LiftedCard({
    required this.width,
    required this.height,
    required this.gradient,
    required this.accentShadow,
    required this.child,
  });

  final double         width;
  final double         height;
  final LinearGradient gradient;
  final Color          accentShadow;
  final Widget         child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentShadow.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: -3,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.violet500.withValues(alpha: 0.20),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Inactive nav slot — flush icon + label inside the bar.
// ─────────────────────────────────────────────────────────────────────

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.isSelected,
    required this.iconSize,
    required this.labelSize,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool   isSelected;
  final double iconSize;
  final double labelSize;
  final Color  iconColor;
  final Color  labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      highlightColor: iconColor.withValues(alpha: 0.06),
      splashColor:    iconColor.withValues(alpha: 0.10),
      child: SizedBox(
        width: 60,
        height: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // When this slot is selected the lifted card takes over the
            // visual — we render the in-bar icon at zero opacity so the
            // layout (and tap target size) stays identical to the other
            // slots.
            Opacity(
              opacity: isSelected ? 0 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(item.icon, color: iconColor, size: iconSize),
                  if (item.badge)
                    Positioned(
                      top: -2, right: -6,
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: isSelected ? 0 : 1,
              child: Text(
                item.label,
                style: AppTypography.caption.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                  fontSize: labelSize,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// FAB circle — same shape as CurvedBottomNav's basket FAB.
// ─────────────────────────────────────────────────────────────────────

class _FabCircle extends StatelessWidget {
  const _FabCircle({
    required this.size,
    required this.gradient,
    required this.ringColor,
    required this.accent,
    required this.onTap,
  });
  final double size;
  final LinearGradient gradient;
  /// Surface color — used for the outer ring around the FAB so it
  /// separates cleanly from the bar on any theme.
  final Color  ringColor;
  final Color  accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); onTap(); },
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          border: Border.all(color: ringColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.50),
              blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -3,
            ),
            BoxShadow(
              color: AppColors.violet500.withValues(alpha: 0.30),
              blurRadius: 28, offset: const Offset(0, 14), spreadRadius: -5,
            ),
          ],
        ),
        child: Icon(
          Icons.shopping_basket_rounded,
          color: Colors.white, size: size * 0.42,
        ),
      ),
    );
  }
}
