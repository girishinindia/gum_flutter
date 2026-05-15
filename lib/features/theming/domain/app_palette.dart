// AppPalette — the small set of colour tokens that change per theme.
//
// The app uses a **two-tier colour system**:
//   • Tier 1 (static) — `AppColors` ships fixed slate / outline / surface
//     / semantic (success/amber/rose) tokens that never change regardless
//     of theme. ~140 references continue to work untouched.
//   • Tier 2 (dynamic) — this file. Only the visible signature gradients
//     and the brand seed live here, resolved at runtime from the active
//     `ThemeController.palette`.
//
// If a new gradient ever needs to feel "themed", add a field here and
// fall back to the Aurora value in `theme_presets.dart`.

import 'package:flutter/material.dart';

@immutable
class AppPalette {
  /// Stable identifier persisted to SharedPreferences (e.g. 'aurora',
  /// 'ocean', 'peach-rose'). Lower-case, hyphen-separated.
  final String id;

  /// Human-readable name shown in the picker (e.g. "Cyan Lavender").
  final String name;

  /// Short subtitle for the picker tile (e.g. "sky → cyan → indigo").
  final String tagline;

  // ── Themable gradients ─────────────────────────────────────────────

  /// 4-stop signature gradient. Used by the hero header, drawer header,
  /// the signed-out CTA card, and the splash screen.
  final LinearGradient heroGradient;

  /// 2-stop button / FAB / "Reserve" CTA gradient.
  final LinearGradient brandGradient;

  /// 4-stop horizontal sweep painted as the curved-bottom-nav stroke.
  final LinearGradient bottomNavGradient;

  /// 3-stop subtle vertical tint applied to the scaffold body so the
  /// page isn't flat white behind the hero.
  final LinearGradient pageBgGradient;

  /// 3-stop signature gradient used as the FeaturedCard backdrop.
  final LinearGradient featureGradient;

  // ── Themable solid tokens ──────────────────────────────────────────

  /// Brand primary (500 in the scale). Drives small accents that don't
  /// belong to one of the gradients (e.g. the "See all" pill text).
  final Color primary500;

  /// Brand primary deeper (700). Used by chip text + filled outlines.
  final Color primary700;

  /// Brand primary 50 — used as the tinted background on pills/badges.
  final Color primary50;

  /// Brand primary 200 — used as the border on pills/badges.
  final Color primary200;

  // ── Foreground contrast on the hero gradient ───────────────────────
  //
  // The hero gradient varies wildly across themes — dark blue/violet
  // for Aurora & Ocean, pale pastels for Sunshine/Champagne/Mint/Spring/
  // Peach/Cyan-Lavender. White text only works on the dark gradients;
  // on the pastels it disappears. `onHero` picks the right contrast
  // per theme (white for dark gradients, slate-900 for light ones).
  //
  // Used by: search field placeholder + icon, stats card numbers/labels,
  // drawer welcome card text, splash tagline. Anything painted ON TOP OF
  // `heroGradient` should pull its colour from here.

  /// Primary foreground colour over the hero gradient.
  final Color onHero;

  /// Faded foreground for secondary text (placeholder, sub-labels) over
  /// the hero gradient. Typically `onHero` at 70 – 80 % alpha.
  final Color onHeroMuted;

  /// Tint applied behind glass-style elements (search field, stats
  /// cards) sitting on the hero. White for dark gradients, dark slate
  /// for pale ones — keeps the chip readable either way.
  final Color heroSurface;

  /// Border for the same glass elements. Slightly stronger than the
  /// surface tint so the chip has a visible edge.
  final Color heroSurfaceBorder;

  // ── Foreground contrast on the page background ─────────────────────
  //
  // Anything painted directly onto the scaffold (NOT inside a white
  // card) needs to flip colour on dark themes — section titles, empty
  // states, etc. Cards themselves stay white and continue to use the
  // static `AppColors.slate900` for internal text.
  //
  // For dark themes (`pageBgGradient` is dark) → near-white text.
  // For light themes → slate-900 (the existing default).

  /// Primary foreground colour over the page background (section
  /// titles, "no items" placeholders).
  final Color onPageBg;

  /// Faded variant used for secondary copy directly on the page bg.
  final Color onPageBgMuted;

  // ── Chrome surfaces (drawer + app bar) ─────────────────────────────
  //
  // The two solid panels of "app shell": the end-drawer's body and
  // the sticky `BrandSliverAppBar`. On light themes these stay white
  // (so Aurora and every other light palette look exactly as they did
  // before this token group existed). On dark themes they go deep
  // slate so the chrome reads as "dark mode" alongside the dark hero.

  /// Drawer + app-bar base background.
  final Color chromeSurface;

  /// Slight tint used for inset chips on the chrome (the language
  /// pill / drawer-menu circle / "see all" pill bg variant).
  final Color chromeSurfaceMuted;

  /// Divider + soft outline colour on the chrome.
  final Color chromeOutline;

  /// Primary foreground (text + icons) on the chrome.
  final Color onChrome;

  /// Faded foreground for secondary text on the chrome (trailing
  /// labels in drawer rows, sub-titles, chevron icons).
  final Color onChromeMuted;

  /// True for themes whose chrome surface is dark (Purple Haze,
  /// Midnight Ocean, Obsidian, Ember, Royal Sapphire). Lets widgets
  /// branch on luminance without re-deriving it from `onChrome` —
  /// most importantly, the SVG wordmark needs a `Colors.white` tint
  /// only when this is true (else the brand's original ink stays).
  final bool isDark;

  const AppPalette({
    required this.id,
    required this.name,
    required this.tagline,
    required this.heroGradient,
    required this.brandGradient,
    required this.bottomNavGradient,
    required this.pageBgGradient,
    required this.featureGradient,
    required this.primary500,
    required this.primary700,
    required this.primary50,
    required this.primary200,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroSurface,
    required this.heroSurfaceBorder,
    required this.onPageBg,
    required this.onPageBgMuted,
    required this.chromeSurface,
    required this.chromeSurfaceMuted,
    required this.chromeOutline,
    required this.onChrome,
    required this.onChromeMuted,
    required this.isDark,
  });
}
