// Brand colour tokens — single source of truth for the whole app.
//
// Ported 1:1 from gum_web/app/globals.css and extended with the
// "Premium Aurora" refinements:
//   • 4-stop aurora gradient (sky → cyan → indigo → violet)
//   • Violet/purple stops for the right-edge accent
//   • Per-tile coloured radial-glow palette
//
// Token groups:
//   • brand / sky         — primary brand-sky palette (CTAs, links)
//   • accent              — indigo, gradient endpoint
//   • violet              — aurora accent (NEW for Premium)
//   • slate               — neutral greys
//   • semantic            — success / warn / danger / amber
//   • gradients           — pre-baked LinearGradients
//   • tile palettes       — per-category accent colours

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand sky ─────────────────────────────────────────────────────
  static const Color sky50  = Color(0xFFF0F9FF);
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky200 = Color(0xFFBAE6FD);
  static const Color sky300 = Color(0xFF7DD3FC);
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky600 = Color(0xFF0284C7);
  static const Color sky700 = Color(0xFF0369A1);
  static const Color sky800 = Color(0xFF075985);
  static const Color sky900 = Color(0xFF0C4A6E);

  static const Color brand50  = sky50;
  static const Color brand100 = sky100;
  static const Color brand200 = sky200;
  static const Color brand300 = sky300;
  static const Color brand400 = sky400;
  static const Color brand500 = sky500;
  static const Color brand600 = sky600;
  static const Color brand700 = sky700;
  static const Color brand800 = sky800;
  static const Color brand900 = sky900;

  // ── Accent (indigo) ───────────────────────────────────────────────
  static const Color accent      = Color(0xFF6366F1);
  static const Color accent400   = Color(0xFF818CF8);
  static const Color accent600   = Color(0xFF4F46E5);
  static const Color accentLight = Color(0xFF818CF8);

  // ── Violet — NEW for Premium Aurora ───────────────────────────────
  static const Color violet300 = Color(0xFFD8B4FE);
  static const Color violet500 = Color(0xFFA855F7);
  static const Color violet600 = Color(0xFF9333EA);
  static const Color violet700 = Color(0xFF7E22CE);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color amber   = Color(0xFFF59E0B);
  static const Color rose    = Color(0xFFF43F5E);
  static const Color warn    = Color(0xFFF59E0B);

  // ── Slate ─────────────────────────────────────────────────────────
  static const Color slate50  = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // ── Surfaces ──────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF8FAFC);
  static const Color surface       = Colors.white;
  static const Color surfaceMuted  = Color(0xFFF1F5F9);
  static const Color outline       = Color(0xFFE2E8F0);
  static const Color outlineSoft   = Color(0x66E2E8F0);

  static const Color glassBg     = Color(0x8CFFFFFF);
  static const Color glassBorder = Color(0xA6FFFFFF);
  static const Color glassShadow = Color(0x140EA5E9);

  // ══════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ══════════════════════════════════════════════════════════════════

  /// 2-stop hero CTA / FAB gradient (brand sky → indigo).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [sky500, accent],
  );

  /// **Premium Aurora gradient** — the hero header backdrop.
  /// 4 stops, top-left → bottom-right, sweeps from brand sky through
  /// bright cyan into indigo and resolves into a soft violet — gives
  /// the page a recognisable signature without leaving the brand.
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [sky500, sky400, accent, violet500],
    stops:  [0.0, 0.25, 0.65, 1.0],
  );

  /// Bottom-nav curve fill — horizontal sweep with violet end stop.
  static const LinearGradient bottomNavGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end:   Alignment.centerRight,
    colors: [sky800, sky700, accent, violet500],
    stops:  [0.0, 0.35, 0.7, 1.0],
  );

  /// Legacy 3-stop hero (kept for callers that explicitly want
  /// the no-violet variant — not used by the premium home).
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [sky500, sky700, accent],
    stops:  [0.0, 0.6, 1.0],
  );

  /// Subtle background tint applied to the scaffold — keeps the white
  /// page from feeling flat. Used on the body bg behind the hero.
  static const LinearGradient pageBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end:   Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF0F9FF), Color(0xFFFAF5FF)],
    stops:  [0.0, 0.4, 1.0],
  );

  // ══════════════════════════════════════════════════════════════════
  // TILE / SECTION ACCENT PALETTES
  // ══════════════════════════════════════════════════════════════════

  /// Soft pastel pairs for category tile backgrounds.
  static const List<List<Color>> tilePalettes = [
    [sky100,           sky50],
    [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
    [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
    [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
    [Color(0xFFFFE4E6), Color(0xFFFFF1F2)],
    [Color(0xFFE0E7FF), Color(0xFFEEF2FF)],
  ];

  /// Icon-chip gradient pairs per category family. Matched to the
  /// tile pastels so each category has a coherent two-tone identity.
  /// Index correspondence:
  ///   0 brand-sky  1 emerald  2 amber-rose  3 violet-indigo
  ///   4 rose-amber 5 indigo-sky
  static const List<List<Color>> tileIconGradients = [
    [sky500,     accent],          // 0 — brand
    [success,    sky500],          // 1 — AI/ML
    [amber,      rose],             // 2 — Web Dev
    [violet500,  accent],           // 3 — Cyber
    [rose,       amber],            // 4 — Marketing
    [accent,     sky400],           // 5 — Cloud
  ];

  /// Per-tile shadow tint — drives the soft coloured glow under each
  /// category icon. Same index order as `tileIconGradients`.
  static const List<Color> tileShadowTints = [
    Color(0x4D0EA5E9), // sky-500 @ 30%
    Color(0x4D10B981), // emerald
    Color(0x4DF59E0B), // amber
    Color(0x4DA855F7), // violet
    Color(0x4DF43F5E), // rose
    Color(0x4D6366F1), // indigo
  ];
}
