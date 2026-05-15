// Theme presets — 13 pre-baked AppPalette instances.
//
// LIGHT (cards + page already read against light text):
//   1. aurora         (DEFAULT — sky → cyan → indigo → violet)
//   2. cyan-lavender  (soft cyan + pastel violet)
//   3. sunshine       (warm yellow + amber)
//   4. champagne      (beige + rose + peach)
//   5. aqua-mint      (cyan → teal → mint)
//   6. ocean          (deep blue + sky)
//   7. spring         (lemon + lime + mint)
//   8. peach-rose     (pink + rose + peach)
//
// DARK (hero + bottom-nav + page bg all dark — cards stay white and
//       pop as elevated surfaces, à la iOS/Android dark mode):
//   9. purple-haze     (navy + violet glow)
//  10. midnight-ocean  (deep textured navy)
//  11. obsidian        (pure black + electric sky accent)
//  12. ember           (black + warm rose / rust)
//  13. royal-sapphire  (deep blue with sparkle highlights)
//
// Each palette overrides only the visible gradients and brand seed.
// Slate / outline / surface / semantic colours are inherited from
// AppColors (never themed — they're neutrals).
//
// `onHero` follows the hero gradient luminance: white on dark themes
// (1, 6, 9–13), slate-900 on light themes (2–5, 7, 8). This keeps
// search-field placeholder, drawer header, splash tagline & stats
// readable regardless of the active palette.

import 'package:flutter/material.dart';
import '../domain/app_palette.dart';

class ThemePresets {
  ThemePresets._();

  // ── Helpers ────────────────────────────────────────────────────────

  static const _diag = Alignment.topLeft;
  static const _diagEnd = Alignment.bottomRight;
  static const _horizStart = Alignment.centerLeft;
  static const _horizEnd   = Alignment.centerRight;
  static const _vertStart = Alignment.topCenter;
  static const _vertEnd   = Alignment.bottomCenter;

  // ══════════════════════════════════════════════════════════════════
  // 1. AURORA — the original/default
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette aurora = AppPalette(
    id:      'aurora',
    name:    'Aurora',
    tagline: 'sky → cyan → indigo → violet',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFFA855F7)],
      stops:  [0.0, 0.25, 0.65, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF075985), Color(0xFF0369A1), Color(0xFF6366F1), Color(0xFFA855F7)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFF8FAFC), Color(0xFFF0F9FF), Color(0xFFFAF5FF)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF9333EA), Color(0xFF6366F1), Color(0xFF0EA5E9)],
    ),
    primary500: Color(0xFF0EA5E9),
    primary700: Color(0xFF0369A1),
    primary50:  Color(0xFFF0F9FF),
    primary200: Color(0xFFBAE6FD),
    // Aurora is a deep, saturated gradient — white reads great on it.
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF), // white @ 90 %
    heroSurface:        Color(0x2EFFFFFF), // white @ 18 %
    heroSurfaceBorder:  Color(0x52FFFFFF), // white @ 32 %
    // Aurora's pageBg is light → slate-900 reads on it.
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 2. CYAN LAVENDER — soft cyan + pastel violet
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette cyanLavender = AppPalette(
    id:      'cyan-lavender',
    name:    'Cyan Lavender',
    tagline: 'soft cyan + pastel violet',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF67E8F9), Color(0xFFA5F3FC), Color(0xFFC7D2FE), Color(0xFFE9D5FF)],
      stops:  [0.0, 0.3, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF0891B2), Color(0xFF8B5CF6)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF0E7490), Color(0xFF0891B2), Color(0xFF8B5CF6), Color(0xFFC084FC)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFF8FAFC), Color(0xFFECFEFF), Color(0xFFF5F3FF)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF8B5CF6), Color(0xFF67E8F9), Color(0xFFA5F3FC)],
    ),
    primary500: Color(0xFF0891B2),
    primary700: Color(0xFF155E75),
    primary50:  Color(0xFFECFEFF),
    primary200: Color(0xFFA5F3FC),
    // Cyan Lavender is a pale pastel — dark text reads on it.
    onHero:             Color(0xFF0F172A), // slate-900
    onHeroMuted:        Color(0xCC0F172A), // slate-900 @ 80 %
    heroSurface:        Color(0x1F0F172A), // slate @ 12 %
    heroSurfaceBorder:  Color(0x330F172A), // slate @ 20 %
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9),
    chromeOutline:       Color(0xFFE2E8F0),
    onChrome:            Color(0xFF0F172A),
    onChromeMuted:       Color(0xFF64748B),
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 3. SUNSHINE — warm yellow + amber
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette sunshine = AppPalette(
    id:      'sunshine',
    name:    'Sunshine',
    tagline: 'soft yellow + amber',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFFDE68A), Color(0xFFFEF3C7), Color(0xFFFBBF24), Color(0xFFF59E0B)],
      stops:  [0.0, 0.25, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFEA580C), Color(0xFFF59E0B)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFFFFBEB), Color(0xFFFEF9C3), Color(0xFFFFF7ED)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFEA580C), Color(0xFFF59E0B), Color(0xFFFBBF24)],
    ),
    primary500: Color(0xFFF59E0B),
    primary700: Color(0xFFB45309),
    primary50:  Color(0xFFFFFBEB),
    primary200: Color(0xFFFDE68A),
    onHero:             Color(0xFF0F172A),
    onHeroMuted:        Color(0xCC0F172A),
    heroSurface:        Color(0x1F0F172A),
    heroSurfaceBorder:  Color(0x330F172A),
    // Light pastel page-bg → dark text reads on it.
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 4. CHAMPAGNE — beige + warm peach
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette champagne = AppPalette(
    id:      'champagne',
    name:    'Champagne',
    tagline: 'beige + warm peach',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFFAE8D8), Color(0xFFFEF3E2), Color(0xFFFED7AA), Color(0xFFFDBA74)],
      stops:  [0.0, 0.3, 0.75, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFFB923C), Color(0xFFD97706)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF7C2D12), Color(0xFFC2410C), Color(0xFFD97706), Color(0xFFFB923C)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3E2), Color(0xFFFFF1F2)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFC2410C), Color(0xFFFB923C), Color(0xFFFED7AA)],
    ),
    primary500: Color(0xFFFB923C),
    primary700: Color(0xFFC2410C),
    primary50:  Color(0xFFFFF7ED),
    primary200: Color(0xFFFED7AA),
    onHero:             Color(0xFF0F172A),
    onHeroMuted:        Color(0xCC0F172A),
    heroSurface:        Color(0x1F0F172A),
    heroSurfaceBorder:  Color(0x330F172A),
    // Light pastel page-bg → dark text reads on it.
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 5. AQUA MINT — cyan → teal → mint
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette aquaMint = AppPalette(
    id:      'aqua-mint',
    name:    'Aqua Mint',
    tagline: 'cyan → teal → mint',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF67E8F9), Color(0xFF22D3EE), Color(0xFF5EEAD4), Color(0xFF86EFAC)],
      stops:  [0.0, 0.3, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF155E75), Color(0xFF0E7490), Color(0xFF0D9488), Color(0xFF10B981)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFF8FAFC), Color(0xFFECFEFF), Color(0xFFECFDF5)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF0D9488), Color(0xFF06B6D4), Color(0xFF5EEAD4)],
    ),
    primary500: Color(0xFF06B6D4),
    primary700: Color(0xFF0E7490),
    primary50:  Color(0xFFECFEFF),
    primary200: Color(0xFFA5F3FC),
    onHero:             Color(0xFF0F172A),
    onHeroMuted:        Color(0xCC0F172A),
    heroSurface:        Color(0x1F0F172A),
    heroSurfaceBorder:  Color(0x330F172A),
    // Light pastel page-bg → dark text reads on it.
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 6. OCEAN — deep blue + sky
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette ocean = AppPalette(
    id:      'ocean',
    name:    'Ocean',
    tagline: 'deep blue + sky',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF93C5FD)],
      stops:  [0.0, 0.3, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF93C5FD)],
    ),
    primary500: Color(0xFF2563EB),
    primary700: Color(0xFF1D4ED8),
    primary50:  Color(0xFFEFF6FF),
    primary200: Color(0xFFBFDBFE),
    // Ocean is dark like Aurora — white wins.
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF),
    heroSurface:        Color(0x2EFFFFFF),
    heroSurfaceBorder:  Color(0x52FFFFFF),
    // Page bg stays light (Ocean is light-mode with a dark hero only).
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 7. SPRING — lemon + lime + mint
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette spring = AppPalette(
    id:      'spring',
    name:    'Spring',
    tagline: 'lemon + lime + mint',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFFEF9C3), Color(0xFFD9F99D), Color(0xFFA7F3D0), Color(0xFF6EE7B7)],
      stops:  [0.0, 0.3, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF65A30D), Color(0xFF10B981)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF365314), Color(0xFF4D7C0F), Color(0xFF65A30D), Color(0xFF10B981)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFF7FEE7), Color(0xFFFEFCE8), Color(0xFFECFDF5)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF65A30D), Color(0xFF84CC16), Color(0xFFA7F3D0)],
    ),
    primary500: Color(0xFF65A30D),
    primary700: Color(0xFF3F6212),
    primary50:  Color(0xFFF7FEE7),
    primary200: Color(0xFFD9F99D),
    onHero:             Color(0xFF0F172A),
    onHeroMuted:        Color(0xCC0F172A),
    heroSurface:        Color(0x1F0F172A),
    heroSurfaceBorder:  Color(0x330F172A),
    // Light pastel page-bg → dark text reads on it.
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 8. PEACH ROSE — pink + rose + peach
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette peachRose = AppPalette(
    id:      'peach-rose',
    name:    'Peach Rose',
    tagline: 'pink + rose + peach',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFFBCFE8), Color(0xFFFECACA), Color(0xFFFED7AA), Color(0xFFFDBA74)],
      stops:  [0.0, 0.3, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFEC4899), Color(0xFFFB923C)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFFBE185D), Color(0xFFDB2777), Color(0xFFEC4899), Color(0xFFFB923C)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFFFDF2F8), Color(0xFFFFF1F2), Color(0xFFFFF7ED)],
      stops:  [0.0, 0.4, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFDB2777), Color(0xFFEC4899), Color(0xFFFED7AA)],
    ),
    primary500: Color(0xFFEC4899),
    primary700: Color(0xFFBE185D),
    primary50:  Color(0xFFFDF2F8),
    primary200: Color(0xFFFBCFE8),
    onHero:             Color(0xFF0F172A),
    onHeroMuted:        Color(0xCC0F172A),
    heroSurface:        Color(0x1F0F172A),
    heroSurfaceBorder:  Color(0x330F172A),
    // Light pastel page-bg → dark text reads on it.
    onPageBg:           Color(0xFF0F172A),
    onPageBgMuted:      Color(0xFF64748B),
    // Light theme — chrome stays white so the drawer + app bar look
    // exactly as they did before themes existed (Aurora identity).
    chromeSurface:       Colors.white,
    chromeSurfaceMuted:  Color(0xFFF1F5F9), // slate-100
    chromeOutline:       Color(0xFFE2E8F0), // slate-200
    onChrome:            Color(0xFF0F172A), // slate-900
    onChromeMuted:       Color(0xFF64748B), // slate-500
    isDark:              false,
  );

  // ══════════════════════════════════════════════════════════════════
  // 9. PURPLE HAZE — navy → violet (dark)
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette purpleHaze = AppPalette(
    id:      'purple-haze',
    name:    'Purple Haze',
    tagline: 'navy + violet glow',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF000814), Color(0xFF0F0820), Color(0xFF2D1B69), Color(0xFF7E22CE)],
      stops:  [0.0, 0.35, 0.75, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF000814), Color(0xFF1E1B4B), Color(0xFF4338CA), Color(0xFF7C3AED)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFF0A0A0F), Color(0xFF1A0F2E), Color(0xFF0F0820)],
      stops:  [0.0, 0.5, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF9333EA), Color(0xFF6366F1), Color(0xFF2563EB)],
    ),
    // Brand scale stays light-pastel-on-white so "See all" / badge pills
    // still read on the (still-white) card surfaces inside the home.
    primary500: Color(0xFF8B5CF6),
    primary700: Color(0xFF6D28D9),
    primary50:  Color(0xFFF5F3FF),
    primary200: Color(0xFFDDD6FE),
    // Hero is dark → white text + white-tinted glass surface.
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF),
    heroSurface:        Color(0x2EFFFFFF),
    heroSurfaceBorder:  Color(0x52FFFFFF),
    // Dark page-bg → near-white text + soft slate-300 secondary.
    onPageBg:           Color(0xFFF8FAFC),
    onPageBgMuted:      Color(0xFFCBD5E1),
    // Dark theme — chrome flips to deep slate so the drawer + app bar
    // read as "dark mode" alongside the dark hero. SVG wordmark + all
    // foreground text/icons switch to near-white via `onChrome`.
    chromeSurface:       Color(0xFF0F172A), // slate-900
    chromeSurfaceMuted:  Color(0xFF1E293B), // slate-800
    chromeOutline:       Color(0xFF334155), // slate-700
    onChrome:            Color(0xFFF8FAFC), // slate-50
    onChromeMuted:       Color(0xFF94A3B8), // slate-400
    isDark:              true,
  );

  // ══════════════════════════════════════════════════════════════════
  // 10. MIDNIGHT OCEAN — deep textured navy (dark)
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette midnightOcean = AppPalette(
    id:      'midnight-ocean',
    name:    'Midnight Ocean',
    tagline: 'deep textured navy',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
      stops:  [0.0, 0.35, 0.75, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF020617), Color(0xFF0C1E4A), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFF0A0F1A), Color(0xFF0F172A), Color(0xFF1E293B)],
      stops:  [0.0, 0.5, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
    ),
    primary500: Color(0xFF2563EB),
    primary700: Color(0xFF1D4ED8),
    primary50:  Color(0xFFEFF6FF),
    primary200: Color(0xFFBFDBFE),
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF),
    heroSurface:        Color(0x2EFFFFFF),
    heroSurfaceBorder:  Color(0x52FFFFFF),
    // Dark page-bg → near-white text + soft slate-300 secondary.
    onPageBg:           Color(0xFFF8FAFC),
    onPageBgMuted:      Color(0xFFCBD5E1),
    // Dark theme — chrome flips to deep slate so the drawer + app bar
    // read as "dark mode" alongside the dark hero. SVG wordmark + all
    // foreground text/icons switch to near-white via `onChrome`.
    chromeSurface:       Color(0xFF0F172A), // slate-900
    chromeSurfaceMuted:  Color(0xFF1E293B), // slate-800
    chromeOutline:       Color(0xFF334155), // slate-700
    onChrome:            Color(0xFFF8FAFC), // slate-50
    onChromeMuted:       Color(0xFF94A3B8), // slate-400
    isDark:              true,
  );

  // ══════════════════════════════════════════════════════════════════
  // 11. OBSIDIAN — pure black + electric sky accent (dark)
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette obsidian = AppPalette(
    id:      'obsidian',
    name:    'Obsidian',
    tagline: 'pure black + electric',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF000000), Color(0xFF0A0A0F), Color(0xFF18181B), Color(0xFF27272A)],
      stops:  [0.0, 0.4, 0.8, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      // Electric sky → indigo so the FAB/buttons POP against the
      // otherwise neutral charcoal hero (without it the brand reads inert).
      colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF000000), Color(0xFF18181B), Color(0xFF27272A), Color(0xFF3F3F46)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFF0A0A0F), Color(0xFF18181B), Color(0xFF0F172A)],
      stops:  [0.0, 0.5, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF18181B), Color(0xFF1E3A8A), Color(0xFF0EA5E9)],
    ),
    primary500: Color(0xFF0EA5E9),
    primary700: Color(0xFF0369A1),
    primary50:  Color(0xFFF0F9FF),
    primary200: Color(0xFFBAE6FD),
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF),
    heroSurface:        Color(0x2EFFFFFF),
    heroSurfaceBorder:  Color(0x52FFFFFF),
    // Dark page-bg → near-white text + soft slate-300 secondary.
    onPageBg:           Color(0xFFF8FAFC),
    onPageBgMuted:      Color(0xFFCBD5E1),
    // Dark theme — chrome flips to deep slate so the drawer + app bar
    // read as "dark mode" alongside the dark hero. SVG wordmark + all
    // foreground text/icons switch to near-white via `onChrome`.
    chromeSurface:       Color(0xFF0F172A), // slate-900
    chromeSurfaceMuted:  Color(0xFF1E293B), // slate-800
    chromeOutline:       Color(0xFF334155), // slate-700
    onChrome:            Color(0xFFF8FAFC), // slate-50
    onChromeMuted:       Color(0xFF94A3B8), // slate-400
    isDark:              true,
  );

  // ══════════════════════════════════════════════════════════════════
  // 12. EMBER — black + warm rose / rust (dark)
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette ember = AppPalette(
    id:      'ember',
    name:    'Ember',
    tagline: 'black + warm rose',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF0F0606), Color(0xFF1F0A0A), Color(0xFF7F1D1D), Color(0xFF9F1239)],
      stops:  [0.0, 0.35, 0.75, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFFDC2626), Color(0xFFE11D48)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF0F0606), Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFFDC2626)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFF1A0F0F), Color(0xFF1F1414), Color(0xFF0F0606)],
      stops:  [0.0, 0.5, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF9F1239), Color(0xFFDC2626), Color(0xFFF87171)],
    ),
    primary500: Color(0xFFDC2626),
    primary700: Color(0xFF991B1B),
    primary50:  Color(0xFFFEF2F2),
    primary200: Color(0xFFFECACA),
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF),
    heroSurface:        Color(0x2EFFFFFF),
    heroSurfaceBorder:  Color(0x52FFFFFF),
    // Dark page-bg → near-white text + soft slate-300 secondary.
    onPageBg:           Color(0xFFF8FAFC),
    onPageBgMuted:      Color(0xFFCBD5E1),
    // Dark theme — chrome flips to deep slate so the drawer + app bar
    // read as "dark mode" alongside the dark hero. SVG wordmark + all
    // foreground text/icons switch to near-white via `onChrome`.
    chromeSurface:       Color(0xFF0F172A), // slate-900
    chromeSurfaceMuted:  Color(0xFF1E293B), // slate-800
    chromeOutline:       Color(0xFF334155), // slate-700
    onChrome:            Color(0xFFF8FAFC), // slate-50
    onChromeMuted:       Color(0xFF94A3B8), // slate-400
    isDark:              true,
  );

  // ══════════════════════════════════════════════════════════════════
  // 13. ROYAL SAPPHIRE — deep blue with sparkle highlights (dark)
  // ══════════════════════════════════════════════════════════════════

  static const AppPalette royalSapphire = AppPalette(
    id:      'royal-sapphire',
    name:    'Royal Sapphire',
    tagline: 'deep blue + sparkle',
    heroGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF020617), Color(0xFF0C1E4A), Color(0xFF1E40AF), Color(0xFF3B82F6)],
      stops:  [0.0, 0.3, 0.7, 1.0],
    ),
    brandGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    ),
    bottomNavGradient: LinearGradient(
      begin: _horizStart, end: _horizEnd,
      colors: [Color(0xFF020617), Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA)],
      stops:  [0.0, 0.35, 0.7, 1.0],
    ),
    pageBgGradient: LinearGradient(
      begin: _vertStart, end: _vertEnd,
      colors: [Color(0xFF0A1428), Color(0xFF102444), Color(0xFF0F1B33)],
      stops:  [0.0, 0.5, 1.0],
    ),
    featureGradient: LinearGradient(
      begin: _diag, end: _diagEnd,
      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA)],
    ),
    primary500: Color(0xFF3B82F6),
    primary700: Color(0xFF1D4ED8),
    primary50:  Color(0xFFEFF6FF),
    primary200: Color(0xFFBFDBFE),
    onHero:             Colors.white,
    onHeroMuted:        Color(0xE6FFFFFF),
    heroSurface:        Color(0x2EFFFFFF),
    heroSurfaceBorder:  Color(0x52FFFFFF),
    // Dark page-bg → near-white text + soft slate-300 secondary.
    onPageBg:           Color(0xFFF8FAFC),
    onPageBgMuted:      Color(0xFFCBD5E1),
    // Dark theme — chrome flips to deep slate so the drawer + app bar
    // read as "dark mode" alongside the dark hero. SVG wordmark + all
    // foreground text/icons switch to near-white via `onChrome`.
    chromeSurface:       Color(0xFF0F172A), // slate-900
    chromeSurfaceMuted:  Color(0xFF1E293B), // slate-800
    chromeOutline:       Color(0xFF334155), // slate-700
    onChrome:            Color(0xFFF8FAFC), // slate-50
    onChromeMuted:       Color(0xFF94A3B8), // slate-400
    isDark:              true,
  );

  // ══════════════════════════════════════════════════════════════════
  // Registry
  // ══════════════════════════════════════════════════════════════════

  /// All themes in picker order. Aurora is first (= default). Lights
  /// come before darks so the picker reads as a natural light → dark
  /// spectrum from top-left to bottom-right.
  static const List<AppPalette> all = [
    // Light
    aurora,
    cyanLavender,
    sunshine,
    champagne,
    aquaMint,
    ocean,
    spring,
    peachRose,
    // Dark
    purpleHaze,
    midnightOcean,
    obsidian,
    ember,
    royalSapphire,
  ];

  /// Look up a palette by its persisted id. Unknown ids fall back to
  /// Aurora so a corrupted preference can never brick the UI.
  static AppPalette byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return aurora;
  }
}
