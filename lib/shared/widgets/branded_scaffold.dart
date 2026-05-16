// Shared scaffold that gives auth + profile screens the same visual
// language as the home page:
//
//   • soft vertical page-bg tint from the active palette
//   • optional aurora hero strip at the top with the brand SVG logo
//     + screen title + subtitle (mirrors the home hero)
//   • soft floating glow orbs for depth (lifted from the splash)
//
// Why centralise: the auth + profile screens were all using plain
// Material Scaffold defaults, which made them feel like a different
// app. Wrapping them in one widget means a future palette swap
// (ThemePresets) flows through everywhere automatically.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../features/theming/theme_controller.dart';

class BrandedScaffold extends StatelessWidget {
  const BrandedScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.hero = false,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showLogo = true,
  });

  /// Page content. Wrapped in `SafeArea` by default; the caller decides
  /// scroll vs. fixed layout.
  final Widget child;

  /// Hero variant — when `true`, a tall aurora gradient strip with the
  /// brand mark + title + subtitle is painted at the top. When `false`
  /// (the default), only the soft page-bg tint is applied so the
  /// caller's own AppBar / Card / etc. stays prominent.
  final bool hero;

  /// Title rendered inside the hero strip (only when `hero: true`).
  final String? title;
  final String? subtitle;

  /// Optional standard AppBar — useful for sub-screens that need a
  /// back button. When supplied, the hero is hidden (you typically
  /// want one or the other, not both).
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  /// Whether the brand SVG logo renders inside the hero strip.
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeController>().palette;
    final hasHero = hero && appBar == null;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        // Expand so Positioned.fill children fill the whole body — the
        // default loose fit sizes the stack to the largest non-
        // positioned child (the hero), squashing the content into a
        // sliver below.
        fit: StackFit.expand,
        children: [
          // Soft vertical page-bg tint matching the home page.
          DecoratedBox(
            decoration: BoxDecoration(gradient: palette.pageBgGradient),
          ),

          // Hero strip (only when `hero: true` AND no appBar provided).
          // Pinned to the top with explicit dimensions so the Stack's
          // expand fit doesn't try to stretch it the whole body.
          if (hasHero)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _BrandHero(
                palette: palette,
                title: title,
                subtitle: subtitle,
                showLogo: showLogo,
              ),
            ),

          // Content
          Positioned.fill(
            top: hasHero ? 220 : 0,
            child: SafeArea(top: !hasHero, child: child),
          ),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.showLogo,
  });

  final dynamic palette; // AppPalette — kept dynamic to avoid leaking the import
  final String? title;
  final String? subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onHero = palette.onHero as Color;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft:  Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: SizedBox(
        height: 240,
        width:  double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── White brand strip (mirrors the home's sticky app bar) ──
            if (showLogo)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      // Graduation chip — identical to the home's
                      // app-bar chip (hero_header.dart lines 75-90).
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          gradient: palette.brandGradient as Gradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (palette.primary500 as Color).withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      // GM wordmark — natural ink on light themes,
                      // white on dark themes (matches hero_header.dart).
                      Expanded(
                        child: ClipRect(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: SvgPicture.asset(
                              AppAssets.brandLogoSvg,
                              height: 36,
                              colorFilter: (palette.isDark as bool)
                                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Aurora panel with title + subtitle below the brand ──
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(gradient: palette.heroGradient as Gradient),
                child: Stack(
                  children: [
                    // Glow orbs for depth.
                    Positioned(
                      top: -60, right: -50,
                      child: _Orb(size: 180, color: onHero.withValues(alpha: 0.18)),
                    ),
                    Positioned(
                      bottom: -80, left: -60,
                      child: _Orb(size: 160, color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(child: CustomPaint(painter: _DotGrid())),
                    ),
                    Padding(
                      // Bumped bottom padding (was 16 → now 32) so
                      // the subtitle breathes against the rounded
                      // bottom edge of the aurora panel and doesn't
                      // press against the form card below.
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: onHero,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: onHero.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
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

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color  color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _DotGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
