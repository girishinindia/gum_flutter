// Typography tokens.
//
// Mirrors the desktop / mobile-web setup where Sora is the display
// face and Outfit is the body face — both loaded via Google Fonts.
// Every text style the app uses should reach for one of these named
// styles rather than instantiating TextStyle inline.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Base font families.
  static TextStyle get _sora   => GoogleFonts.sora();
  static TextStyle get _outfit => GoogleFonts.outfit();

  // ── Display & headings — Sora ──────────────────────────────────────
  static TextStyle display = _sora.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
    color: AppColors.slate900,
  );

  static TextStyle h1 = _sora.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.2,
    color: AppColors.slate900,
  );

  static TextStyle h2 = _sora.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
    color: AppColors.slate900,
  );

  static TextStyle h3 = _sora.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.slate900,
  );

  // ── Body — Outfit ──────────────────────────────────────────────────
  static TextStyle body = _outfit.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.slate700,
  );

  static TextStyle bodyMd = _outfit.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.slate600,
  );

  static TextStyle bodySm = _outfit.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.slate500,
  );

  static TextStyle caption = _outfit.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.slate500,
    letterSpacing: 0.1,
  );

  // Strong call-to-action / button label.
  static TextStyle buttonLabel = _outfit.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  // Eyebrow — uppercase tag above section headings.
  static TextStyle eyebrow = _outfit.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.brand700,
    height: 1.2,
  );

  // ── On-gradient (white) variants ───────────────────────────────────
  // For text placed over the hero gradient — same Sora/Outfit, white.
  static TextStyle h1OnGradient   = h1.copyWith(color: Colors.white);
  static TextStyle h2OnGradient   = h2.copyWith(color: Colors.white);
  static TextStyle bodyOnGradient = body.copyWith(color: Colors.white.withValues(alpha: 0.92));
  static TextStyle captionOnGradient = caption.copyWith(color: Colors.white.withValues(alpha: 0.85));
}
