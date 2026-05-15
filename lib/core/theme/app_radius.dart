// Shape tokens — radius + elevation primitives.
//
// Matches the desktop CSS tokens (--radius-sm, --radius-md, etc.) and
// extends them with the "Premium Aurora" 3-layer shadow system:
//
//   layer 1 — sharp 1px contact edge for crisp definition
//   layer 2 — ambient soft blur for natural depth
//   layer 3 — brand-tinted glow that bleeds the colour story onto
//             the surrounding surface
//
// Every elevated surface in the app should reach for one of the
// `*Shadow` constants below rather than rolling its own BoxShadow.

import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double xs   = 6;
  static const double sm   = 10;
  static const double md   = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double pill = 999;

  static BorderRadius get rXs   => BorderRadius.circular(xs);
  static BorderRadius get rSm   => BorderRadius.circular(sm);
  static BorderRadius get rMd   => BorderRadius.circular(md);
  static BorderRadius get rLg   => BorderRadius.circular(lg);
  static BorderRadius get rXl   => BorderRadius.circular(xl);
  static BorderRadius get rPill => BorderRadius.circular(pill);

  // ══════════════════════════════════════════════════════════════════
  // PREMIUM 3-LAYER SHADOW SYSTEM
  // ══════════════════════════════════════════════════════════════════

  /// Card default — neutral 3-layer shadow.
  /// Use on every white card / surface that should "lift" off the page.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2,  offset: Offset(0, 1)),
    BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -8),
    BoxShadow(color: Color(0x1F0EA5E9), blurRadius: 48, offset: Offset(0, 16), spreadRadius: -16),
  ];

  /// Hero / featured surface — exaggerated brand glow.
  /// Used on the gradient aurora hero card and large feature blocks.
  static const List<BoxShadow> heroShadow = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 2,  offset: Offset(0, 1)),
    BoxShadow(color: Color(0x33A855F7), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -8),
    BoxShadow(color: Color(0x336366F1), blurRadius: 48, offset: Offset(0, 24), spreadRadius: -16),
  ];

  /// FAB / floating call-to-action — punchy coloured shadow that
  /// sells the "this is the primary action" affordance.
  static const List<BoxShadow> brandShadow = [
    BoxShadow(color: Color(0x4D0EA5E9), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -2),
    BoxShadow(color: Color(0x336366F1), blurRadius: 32, offset: Offset(0, 16), spreadRadius: -8),
  ];

  /// Category icon chip — pass a tint colour so each tile owns its
  /// own family colour without us bloating the constants list.
  static List<BoxShadow> tintedChipShadow(Color tint) => [
    BoxShadow(color: tint.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -3),
    BoxShadow(color: tint.withValues(alpha: 0.15), blurRadius: 32, offset: const Offset(0, 12), spreadRadius: -6),
  ];

  /// Pressed-in / sunken state for chips and pills.
  static const List<BoxShadow> insetShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
