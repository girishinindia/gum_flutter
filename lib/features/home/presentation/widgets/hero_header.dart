// Hero — split into two consumers so the home screen can pin the
// brand row at the top and let everything else scroll under it.
//
//   • [BrandSliverAppBar] — sticky white SliverAppBar containing the
//     graduation chip, the GM_Logo_Dark.svg wordmark (rendered in its
//     ORIGINAL brand colours — no white tint), and a drawer trigger
//     with a pulsing notification dot.
//
//   • [HeroBody] — the aurora gradient panel that sits directly below
//     the app bar. Always shows the glass search field; the progress
//     stats row is only rendered when [isLoggedIn] is true.
//
// User identity (greeting + name + streak) is no longer painted into
// the hero — it lives in [AppDrawer] now, only when the user is
// signed in.

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/language_sheet.dart';
import '../../../i18n/language_controller.dart';
import '../../../theming/theme_controller.dart';

// ═════════════════════════════════════════════════════════════════════
// PUBLIC — sticky brand app bar.
//
// Returns a `SliverAppBar` so the home screen can drop it straight
// into a `CustomScrollView` with `pinned: true` already configured.
// ═════════════════════════════════════════════════════════════════════

class BrandSliverAppBar extends StatelessWidget {
  const BrandSliverAppBar({
    super.key,
    required this.onMenuTap,
    this.showNotificationDot = true,
  });

  final VoidCallback onMenuTap;
  final bool         showNotificationDot;

  @override
  Widget build(BuildContext context) {
    // Themed brand gradient + glow tint for the graduation chip.
    final palette = context.watch<ThemeController>().palette;
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,           // M3: kill the auto tint
      foregroundColor: AppColors.slate900,
      elevation: 0,
      scrolledUnderElevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      automaticallyImplyLeading: false,
      toolbarHeight: 68,
      // Tighter on narrow phones so the title row leaves enough room
      // for two right-side action buttons without clipping. 12 px on
      // most devices, 16 only on tablets.
      titleSpacing: 12,
      title: Row(
        children: [
          // Graduation chip — brand-gradient square that visually
          // anchors the row; sized to match the new logo height.
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: palette.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: palette.primary500.withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          // GM wordmark — Expanded gives the SVG exactly the leftover
          // space after the 42-px chip on the left and the two action
          // buttons on the right have claimed theirs. FittedBox then
          // scales the SVG down (never up) so the wide "Don't just
          // learn, apply!" tagline never overflows on narrow Android
          // devices (Realme C3, Pixel 4a, Galaxy S20 FE etc.).
          //
          // ClipRect is belt-and-braces — even if a single frame is
          // measured before FittedBox computes scale, the paint stays
          // inside bounds so Flutter's debug overflow stripe is gone.
          Expanded(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SvgPicture.asset(
                  AppAssets.brandLogoSvg,
                  height: 36,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Compact action cluster — Language pill on the left, drawer
        // menu on the right. Same shape parity (pill / circle) as the
        // mobile-web language popup trigger so muscle memory transfers.
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Language pill ─────────────────────────────────────
              const _LanguagePillButton(),
              const SizedBox(width: 8),
              // ── Drawer menu (with unread notification dot) ────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  InkResponse(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMenuTap();
                    },
                    radius: 24,
                    child: Container(
                      width: 42, height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_rounded,
                          color: AppColors.slate700, size: 22),
                    ),
                  ),
                  if (showNotificationDot)
                    Positioned(
                      top: -1, right: -1,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            begin: const Offset(0.9, 0.9),
                            end:   const Offset(1.15, 1.15),
                            duration: 900.ms,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// PUBLIC — aurora panel that sits beneath the app bar.
//
// Always shows the glass search field. The stats row only renders
// when [isLoggedIn] is true.
// ═════════════════════════════════════════════════════════════════════

class HeroBody extends StatelessWidget {
  const HeroBody({
    super.key,
    required this.isLoggedIn,
    this.enrolledCount    = 0,
    this.enrolledDelta    = 0,
    this.activeCount      = 0,
    this.certificateCount = 0,
  });

  final bool isLoggedIn;
  final int  enrolledCount;
  final int  enrolledDelta;
  final int  activeCount;
  final int  certificateCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeController>().palette;
    return Container(
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        // No heavy heroShadow — that blur was projecting ~40 px of
        // soft falloff below the gradient and reading as extra gap.
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Stack(
          children: [
            // ── Depth layers ─────────────────────────────────────────
            Positioned(
              top: -40, right: -50,
              child: _Orb(size: 180, color: Colors.white.withValues(alpha: 0.35)),
            ),
            Positioned(
              bottom: -30, left: -40,
              child: _Orb(size: 140, color: AppColors.amber.withValues(alpha: 0.35)),
            ),
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _DotGridPainter())),
            ),

            // ── Foreground content ───────────────────────────────────
            // Bottom = 5 — extends the aurora gradient 5 px BELOW
            // the search bar so it doesn't visually glue to the
            // border. The next section provides the inter-section
            // gap on top of this.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _GlassSearch(),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 16),
                    _StatsRow(
                      enrolled:      enrolledCount,
                      enrolledDelta: enrolledDelta,
                      active:        activeCount,
                      certificates:  certificateCount,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

// ═════════════════════════════════════════════════════════════════════
// Private subwidgets
// ═════════════════════════════════════════════════════════════════════

// ─── Glass search field ───────────────────────────────────────────────
//
// All colours pull from the active palette so the chip stays readable
// regardless of whether the hero is dark (Aurora / Ocean → white text on
// white-tinted glass) or pastel (Sunshine / Champagne / Mint / Spring /
// Peach Rose / Cyan Lavender → slate-900 text on dark-tinted glass).
//
// The ⌘K chip uses `palette.brandGradient` with white text — guaranteed
// contrast on every theme since the brand gradient is always saturated.
class _GlassSearch extends StatelessWidget {
  const _GlassSearch();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeController>().palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.heroSurface,
            border: Border.all(color: palette.heroSurfaceBorder, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  // Slightly stronger than the field background so the
                  // icon chip reads as a separate element.
                  color: palette.onHero.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.search_rounded, color: palette.onHero, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search courses · Python · AI…',
                  style: TextStyle(
                    color: palette.onHeroMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: palette.brandGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary500.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: -1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '⌘K',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.3,
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

// ─── Language icon — opens the LanguageSheet on tap ──────────────────
//
// Compact 42 × 42 circle (matches the drawer button's footprint) so the
// app-bar action cluster stays within the viewport even on narrow
// Android devices where the wordmark + tagline take most of the width.
//
// The active ISO is intentionally NOT shown here — it'd push the chip
// to ~60 px and clip on tight phones. The sheet itself, plus the drawer
// "Language" row, both surface the active language. This trigger is
// purely an entry point.
//
// A tiny brand-coloured dot in the bottom-right confirms the button is
// active / "live" (matches the notification dot pattern on the drawer
// button so the two reads symmetrically).
class _LanguagePillButton extends StatelessWidget {
  const _LanguagePillButton();

  @override
  Widget build(BuildContext context) {
    // Watch so the indicator dot retints with the active theme.
    final palette = context.watch<ThemeController>().palette;
    // Read (not watch) the language controller — the icon shape doesn't
    // depend on the active iso, only on the theme. No rebuilds needed
    // when the user switches language.
    context.read<LanguageController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkResponse(
          onTap: () {
            HapticFeedback.lightImpact();
            LanguageSheet.show(context);
          },
          radius: 24,
          child: Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language_rounded,
                color: AppColors.slate700, size: 22),
          ),
        ),
        // Brand-tinted dot — tiny "live" indicator so the icon doesn't
        // feel inert next to the drawer's pulsing amber notification.
        Positioned(
          bottom: -1, right: -1,
          child: Container(
            width: 9, height: 9,
            decoration: BoxDecoration(
              color: palette.primary500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.enrolled,
    required this.enrolledDelta,
    required this.active,
    required this.certificates,
  });
  final int enrolled;
  final int enrolledDelta;
  final int active;
  final int certificates;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'ENROLLED',
            value: enrolled,
            progress: 0.75,
            progressColor: const Color(0xFFFEF08A),
            footnote: '+$enrolledDelta this week',
            footnoteColor: const Color(0xFFFEF08A),
            ring: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'ACTIVE',
            value: active,
            progress: 0.58,
            progressColor: AppColors.success,
            footnote: '3hr today',
            footnoteColor: const Color(0xFF86EFAC),
            ring: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'CERTS',
            value: certificates,
            progress: 0,
            progressColor: const Color(0xFFFEF08A),
            footnote: 'View →',
            footnoteColor: const Color(0xFFFEF08A),
            ring: false,
            trophy: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.progress,
    required this.progressColor,
    required this.footnote,
    required this.footnoteColor,
    this.ring = true,
    this.trophy = false,
  });

  final String label;
  final int    value;
  final double progress;
  final Color  progressColor;
  final String footnote;
  final Color  footnoteColor;
  final bool   ring;
  final bool   trophy;

  @override
  Widget build(BuildContext context) {
    // Theme-aware foreground — slate on light hero gradients, white on
    // the dark ones. Background tint follows the same logic via
    // `heroSurface` / `heroSurfaceBorder`.
    final palette = context.watch<ThemeController>().palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.onHero.withValues(alpha: 0.22),
                palette.onHero.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: Border.all(color: palette.heroSurfaceBorder, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0, right: 0,
                child: trophy
                    ? const Text('🏆', style: TextStyle(fontSize: 14))
                    : SizedBox(
                        width: 20, height: 20,
                        child: CustomPaint(
                          painter: _RingPainter(progress: progress, color: progressColor),
                        ),
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountUp(
                    value: value,
                    style: TextStyle(
                      color: palette.onHero,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: TextStyle(
                      color: palette.onHeroMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    footnote,
                    style: TextStyle(
                      color: footnoteColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Count-up tween — animates 0 → value on first build ───────────────
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});
  final int value;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.toInt().toString(), style: style),
    );
  }
}

// ─── Progress ring painter ────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bg);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0, 1), false, fg);
  }
  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Background decorations ───────────────────────────────────────────
class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const spacing = 24.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
