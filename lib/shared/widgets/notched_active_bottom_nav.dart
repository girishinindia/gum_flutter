// Notched-active bottom navigation — the third nav silhouette.
//
// Visual spec:
//   • Solid colored bar (uses `palette.bottomNavGradient` so themes get
//     the full sweep, same as CurvedBottomNav's surface).
//   • A concave dip is CARVED into the top edge under the active tab.
//     The selected icon "pops up" out of the dip in a small floating
//     circle that takes its tint from the active palette.
//   • Central FAB still pokes up above the bar — same brand-gradient
//     circular FAB the curved nav uses, so the central action stays
//     visually consistent.
//   • Inactive items: white-ish icon + label on the gradient bar.
//   • Active item: floating brand-tinted icon above + bold white label
//     in the bar.
//
// The notch SLIDES horizontally to follow the selected index — animated
// via TweenAnimationBuilder over `selectedIndex`. Other than the slot
// FAB occupies (which never gets selected), every tab can get the dip.
//
// API parity with CurvedBottomNav so the home screen can swap one for
// the other via a single conditional.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/theming/theme_controller.dart';
import 'curved_bottom_nav.dart' show CurvedNavItem;

class NotchedActiveBottomNav extends StatelessWidget {
  const NotchedActiveBottomNav({
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
    assert(items.length == 4, 'NotchedActiveBottomNav expects exactly 4 items.');

    final palette     = context.watch<ThemeController>().palette;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final width       = size.width;

    final compact   = width < 380;
    final isTablet  = width >= 600;
    final iconSize  = compact ? 22.0 : (isTablet ? 26.0 : 24.0);
    final labelSize = compact ? 10.0 : (isTablet ? 12.0 : 11.0);
    final fabSize   = compact ? 56.0 : (isTablet ? 68.0 : 60.0);

    // 4 tab slots arranged around the central FAB phantom. Tab x-centers
    // are at widthFrac 0.125, 0.325, 0.675, 0.875 (FAB owns 0.40–0.60).
    const itemBandHeight = 76.0;          // a bit taller — dip needs room
    final  totalHeight   = itemBandHeight + bottomInset;

    return SizedBox(
      width: width,
      height: totalHeight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        // Re-paint when selection changes so the notch animates.
        child: TweenAnimationBuilder<double>(
          key: ValueKey(selectedIndex),
          tween: Tween(begin: -1, end: selectedIndex.toDouble()),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            // Map index → notch x-center (in pixels). The 4 slots:
            //   0 → 12.5% · 1 → 32.5% · 2 → 67.5% · 3 → 87.5%
            final notchCx = _xForIndex(t, width);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Gradient bar with the notch carved at notchCx ──
                Positioned.fill(
                  child: CustomPaint(
                    painter: _NotchBarPainter(
                      gradient: palette.bottomNavGradient,
                      notchCenterX: notchCx,
                      itemBandHeight: itemBandHeight,
                      isDark: palette.isDark,
                    ),
                  ),
                ),

                // ── Floating active icon — sits inside the dip ─────
                Positioned(
                  top: 4,
                  left: notchCx - 22,
                  child: _FloatingActive(
                    icon: items[selectedIndex].icon,
                    surfaceColor: palette.chromeSurface,
                    activeColor:  palette.primary500,
                    iconSize:     iconSize,
                  ),
                ),

                // ── Central FAB (basket) — same look as CurvedBottomNav
                //    so the central action stays recognisable.
                Positioned(
                  top: -4,
                  left: (width - fabSize) / 2,
                  child: _FabCircle(
                    size: fabSize,
                    gradient: palette.brandGradient,
                    accent: palette.primary500,
                    onTap: onFabTapped,
                  ),
                ),

                // ── Items row, pinned to top 76 pt of the band ─────
                Positioned(
                  top: 0, left: 0, right: 0, height: itemBandHeight,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(child: _NavSlot(
                              item: items[0],
                              isSelected: selectedIndex == 0,
                              iconSize: iconSize,
                              labelSize: labelSize,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(alpha: 0.78),
                              onTap: () => _tap(0),
                            )),
                            Expanded(child: _NavSlot(
                              item: items[1],
                              isSelected: selectedIndex == 1,
                              iconSize: iconSize,
                              labelSize: labelSize,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(alpha: 0.78),
                              onTap: () => _tap(1),
                            )),
                          ],
                        ),
                      ),
                      SizedBox(width: fabSize + 8), // FAB slot
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(child: _NavSlot(
                              item: items[2],
                              isSelected: selectedIndex == 2,
                              iconSize: iconSize,
                              labelSize: labelSize,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(alpha: 0.78),
                              onTap: () => _tap(2),
                            )),
                            Expanded(child: _NavSlot(
                              item: items[3],
                              isSelected: selectedIndex == 3,
                              iconSize: iconSize,
                              labelSize: labelSize,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(alpha: 0.78),
                              onTap: () => _tap(3),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _tap(int i) {
    HapticFeedback.selectionClick();
    onItemTapped(i);
  }

  /// Map a (possibly fractional, for animation) index to the notch's
  /// horizontal center in pixels. Slot 0 is at 12.5 % width, slot 1 at
  /// 32.5 %, slot 2 at 67.5 %, slot 3 at 87.5 % — the FAB owns the
  /// middle 20 % so we skip 0.50.
  double _xForIndex(double t, double width) {
    const xs = [0.125, 0.325, 0.675, 0.875];
    // Clamp to valid range; before first frame we get t = -1 → use slot 0.
    if (t < 0) return xs[0] * width;
    final i = t.floor().clamp(0, 3);
    final j = (i + 1).clamp(0, 3);
    final f = (t - i).clamp(0.0, 1.0);
    return ((xs[i] * (1 - f)) + (xs[j] * f)) * width;
  }
}

// ─────────────────────────────────────────────────────────────────────
// Painter — draws the bar with a notch carved at notchCenterX.
// Geometry mirrors CurvedBottomNav's FAB notch so the silhouettes
// rhyme visually.
// ─────────────────────────────────────────────────────────────────────

class _NotchBarPainter extends CustomPainter {
  _NotchBarPainter({
    required this.gradient,
    required this.notchCenterX,
    required this.itemBandHeight,
    required this.isDark,
  });

  final LinearGradient gradient;
  final double         notchCenterX;
  final double         itemBandHeight;
  final bool           isDark;

  // Notch geometry — same width as CurvedBottomNav's central dip.
  static const double _notchHalfWidth   = 28;   // half-width of the dip
  static const double _notchDepth       = 22;   // how deep the dip is

  @override
  void paint(Canvas canvas, Size size) {
    final shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(shaderRect)
      ..style  = PaintingStyle.fill;

    // Path: flat top edge with a quadratic-bezier dip centered on
    // notchCenterX.
    final cx = notchCenterX.clamp(_notchHalfWidth + 4, size.width - _notchHalfWidth - 4);
    final path = Path()..moveTo(0, _notchDepth);
    path.lineTo(cx - _notchHalfWidth, _notchDepth);
    // Smooth U-curve dip.
    path.cubicTo(
      cx - _notchHalfWidth * 0.6, _notchDepth,
      cx - _notchHalfWidth * 0.4, _notchDepth + _notchDepth,
      cx,                          _notchDepth + _notchDepth,
    );
    path.cubicTo(
      cx + _notchHalfWidth * 0.4, _notchDepth + _notchDepth,
      cx + _notchHalfWidth * 0.6, _notchDepth,
      cx + _notchHalfWidth,        _notchDepth,
    );
    path.lineTo(size.width, _notchDepth);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: isDark ? 0.55 : 0.30), 10, true);
    canvas.drawPath(path, paint);

    // Subtle inner highlight along the dip lip.
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final lip = Path()..moveTo(0, _notchDepth);
    lip.lineTo(cx - _notchHalfWidth, _notchDepth);
    lip.cubicTo(
      cx - _notchHalfWidth * 0.6, _notchDepth,
      cx - _notchHalfWidth * 0.4, _notchDepth + _notchDepth,
      cx,                          _notchDepth + _notchDepth,
    );
    lip.cubicTo(
      cx + _notchHalfWidth * 0.4, _notchDepth + _notchDepth,
      cx + _notchHalfWidth * 0.6, _notchDepth,
      cx + _notchHalfWidth,        _notchDepth,
    );
    lip.lineTo(size.width, _notchDepth);
    canvas.drawPath(lip, stroke);
  }

  @override
  bool shouldRepaint(covariant _NotchBarPainter old) =>
      old.notchCenterX != notchCenterX ||
      old.gradient     != gradient     ||
      old.itemBandHeight != itemBandHeight ||
      old.isDark       != isDark;
}

// ─────────────────────────────────────────────────────────────────────
// Floating-active icon — small surface-colored circle that sits inside
// the carved notch, with the active palette icon at its center.
// ─────────────────────────────────────────────────────────────────────

class _FloatingActive extends StatelessWidget {
  const _FloatingActive({
    required this.icon,
    required this.surfaceColor,
    required this.activeColor,
    required this.iconSize,
  });

  final IconData icon;
  final Color    surfaceColor;
  final Color    activeColor;
  final double   iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.45),
            blurRadius: 14, spreadRadius: -3, offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: activeColor, size: iconSize),
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
    required this.accent,
    required this.onTap,
  });
  final double size;
  final LinearGradient gradient;
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
          border: Border.all(color: Colors.white, width: 3),
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

// ─────────────────────────────────────────────────────────────────────
// Tab slot — icon + label. When this slot is the active one, the label
// goes bold + brighter and the icon is HIDDEN (the floating-active
// circle stands in for it). When inactive, the slot shows both.
// ─────────────────────────────────────────────────────────────────────

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.isSelected,
    required this.iconSize,
    required this.labelSize,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool   isSelected;
  final double iconSize;
  final double labelSize;
  final Color  activeColor;
  final Color  inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 32,
      highlightColor: Colors.white.withValues(alpha: 0.06),
      splashColor:    Colors.white.withValues(alpha: 0.10),
      child: SizedBox(
        height: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Active slot keeps the icon-space empty so the floating
            // surface circle can sit cleanly in the dip; only the label
            // shows below.
            Opacity(
              opacity: isSelected ? 0 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(item.icon, color: inactiveColor, size: iconSize),
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
            Text(
              item.label,
              style: AppTypography.caption.copyWith(
                color: isSelected ? activeColor : inactiveColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: labelSize,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
