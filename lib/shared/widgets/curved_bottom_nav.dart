// Premium curved bottom navigation.
//
// IMPORTANT: the curve geometry is preserved 1:1 from the original
// BNBCustomePainter the user hand-crafted — only the *paint* is swapped
// to the brand bottomNavGradient (sky → indigo → violet). The Bezier
// control points, arc radius and overall shape are byte-identical so
// the silhouette the user already loves stays exactly the same.
//
// Premium enhancements layered on top of that shape:
//   • 4-stop bottomNavGradient fill (sky800 → sky700 → accent → violet500)
//   • subtle inner top stroke for a polished glassy edge
//   • per-tab active state — coloured label + 6×6 dot under selected
//   • notification dot on the "Saved" tab when there are unread items
//   • FAB with brandGradient + 3-layer brandShadow + white halo border

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/theming/theme_controller.dart';

/// One nav slot (icon + label + optional badge).
class CurvedNavItem {
  const CurvedNavItem({
    required this.icon,
    required this.label,
    this.badge = false,
  });

  final IconData icon;
  final String   label;
  final bool     badge;
}

class CurvedBottomNav extends StatelessWidget {
  const CurvedBottomNav({
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

  /// Exactly 4 items — 2 left of the FAB, 2 right of it.
  final List<CurvedNavItem> items;

  @override
  Widget build(BuildContext context) {
    assert(items.length == 4, 'CurvedBottomNav expects exactly 4 items.');
    // Themed nav gradient + FAB gradient. Painters take it as a field
    // since CustomPainter has no BuildContext of its own.
    final palette = context.watch<ThemeController>().palette;

    return SizedBox(
      width: size.width,
      height: 86,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Curved gradient backdrop ────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              size: Size(size.width, 86),
              painter: _BNBPainter(gradient: palette.bottomNavGradient),
            ),
          ),

          // ── Inner top stroke — sits just inside the curve ───────────
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BNBStrokePainter(),
              ),
            ),
          ),

          // ── Central FAB (raised "halo" basket button) ───────────────
          Positioned(
            top: -4,
            left: size.width / 2 - 32,
            child: _Fab(onTap: onFabTapped),
          ),

          // ── Row of items ────────────────────────────────────────────
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  item: items[0],
                  isSelected: selectedIndex == 0,
                  onTap: () => _tap(0),
                ),
                _NavItem(
                  item: items[1],
                  isSelected: selectedIndex == 1,
                  onTap: () => _tap(1),
                ),
                SizedBox(width: size.width * 0.20),
                _NavItem(
                  item: items[2],
                  isSelected: selectedIndex == 2,
                  onTap: () => _tap(2),
                ),
                _NavItem(
                  item: items[3],
                  isSelected: selectedIndex == 3,
                  onTap: () => _tap(3),
                ),
              ],
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
// FAB
// ─────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeController>().palette;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: palette.brandGradient,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: palette.primary500.withValues(alpha: 0.50),
              blurRadius: 26,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: AppColors.violet500.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -6,
            ),
          ],
        ),
        child: const Icon(
          Icons.shopping_basket_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Individual nav item
// ─────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CurvedNavItem item;
  final bool          isSelected;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    // Selected: opaque white. Unselected: bumped from 0.72 → 0.88 so
    // labels stay readable on the brighter pastel-bottomed gradients
    // (Sunshine, Champagne, Aqua Mint, Peach Rose). Font weight is
    // also lifted to w600 on unselected (see below) so the slightly
    // smaller chroma difference is offset by stroke weight.
    final color = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.88);

    return InkResponse(
      onTap: onTap,
      radius: 32,
      highlightColor: Colors.white.withValues(alpha: 0.06),
      splashColor:    Colors.white.withValues(alpha: 0.10),
      child: SizedBox(
        width: 64,
        height: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(item.icon, color: color, size: 22),
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
                color: color,
                // w600 (was w500) on unselected — heavier stroke makes
                // labels read as confidently on pastel-bottomed themes
                // where pure-white text loses contrast.
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 10.5,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isSelected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.55),
                          blurRadius: 6,
                          spreadRadius: -1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// Painters — geometry preserved from the user's original BNBCustomePainter.
// Only the paint is swapped to use bottomNavGradient.
// ═════════════════════════════════════════════════════════════════════

class _BNBPainter extends CustomPainter {
  _BNBPainter({required this.gradient});

  /// Themed sweep — supplied by `CurvedBottomNav` from the active palette
  /// so the curved bg retints alongside the rest of the chrome.
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(shaderRect)
      ..style  = PaintingStyle.fill;

    // Exact path from BNBCustomePainter (preserved 1:1).
    final path = Path()..moveTo(0, 20);
    path.quadraticBezierTo(size.width * .20, 0, size.width * .35, 0);
    path.quadraticBezierTo(size.width * .40, 0, size.width * .40, 20);
    path.arcToPoint(
      Offset(size.width * .60, 20),
      radius: const Radius.circular(10),
      clockwise: false,
    );
    path.quadraticBezierTo(size.width * .60, 0, size.width * .65, 0);
    path.quadraticBezierTo(size.width * .80, 0, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Drop shadow (matches the original 5 / true elevation feel).
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.35), 8, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BNBPainter oldDelegate) =>
      oldDelegate.gradient != gradient;
}

class _BNBStrokePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Same outline path, just stroked for a faint inner highlight.
    final path = Path()..moveTo(0, 20);
    path.quadraticBezierTo(size.width * .20, 0, size.width * .35, 0);
    path.quadraticBezierTo(size.width * .40, 0, size.width * .40, 20);
    path.arcToPoint(
      Offset(size.width * .60, 20),
      radius: const Radius.circular(10),
      clockwise: false,
    );
    path.quadraticBezierTo(size.width * .60, 0, size.width * .65, 0);
    path.quadraticBezierTo(size.width * .80, 0, size.width, 20);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BNBStrokePainter oldDelegate) => false;
}
