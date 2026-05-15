// Typed asset paths — single source of truth.
//
// Reach for `AppAssets.brandLogoSvg` instead of typing the literal
// path. This catches typos at compile time and makes asset-renames
// a single-file find-and-replace.

class AppAssets {
  AppAssets._();

  // ── Brand mark (vector — flutter_svg) ─────────────────────────────
  /// GM_Logo_Dark.svg — same file the desktop + mobile-web portals use.
  static const String brandLogoSvg = 'assets/images/GM_Logo_Dark.svg';

  // ── Raster logos (legacy / splash bg) ─────────────────────────────
  static const String logoLightPng = 'assets/logo_light.png';
  static const String logoDarkPng  = 'assets/logo_dark.png';
  static const String splashBg     = 'assets/SplashScreen.jpg';

  // ── Category / menu icons (re-used from the original home) ────────
  static const String course      = 'assets/course.png';
  static const String project     = 'assets/project.png';
  static const String exercise    = 'assets/exercise.png';
  static const String exam        = 'assets/exam.png';
  static const String quiz        = 'assets/quiz.png';
  static const String material    = 'assets/material.png';
  static const String wallet      = 'assets/wallet.png';
  static const String review      = 'assets/review.png';
  static const String referral    = 'assets/referral.png';
  static const String suggestion  = 'assets/suggestion.png';
  static const String complaint   = 'assets/complaint.png';
  static const String request     = 'assets/request.png';
  static const String update      = 'assets/update.png';
  static const String workPost    = 'assets/work.png';
  static const String group       = 'assets/group.png';
  static const String instructor  = 'assets/instructor.png';
  static const String community   = 'assets/community.png';
  static const String profile     = 'assets/profile.png';
  static const String settings    = 'assets/setting.png';
  static const String offer       = 'assets/offer.png';

  // ── Course covers ────────────────────────────────────────────────
  static const String aiCover         = 'assets/ai.jpg';
  static const String webDevCover     = 'assets/web_development.jpg';
  static const String dataScienceCvr  = 'assets/data_science.jpg';
  static const String pythonCover     = 'assets/python_programming.jpg';
  static const String dmCover         = 'assets/digital_marketing.jpg';
}
