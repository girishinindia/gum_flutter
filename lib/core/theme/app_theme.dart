// Global ThemeData — the single MaterialApp.theme entrypoint.
//
// Composes brand colours, Google-font typography, shape tokens and
// component-level defaults so individual widgets don't have to
// repeat themselves. New widgets should reach for `Theme.of(context)`
// where possible rather than hardcoding values.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  /// Light theme — the only theme today; dark variant can be added
  /// later by mirroring this method.
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.sky500,
      brightness: Brightness.light,
      primary:    AppColors.sky500,
      onPrimary:  Colors.white,
      secondary:  AppColors.accent,
      onSecondary: Colors.white,
      surface:    AppColors.surface,
      onSurface:  AppColors.slate900,
      error:      AppColors.rose,
      onError:    Colors.white,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: Colors.transparent,

      // Outfit body + Sora display, fetched once at app boot.
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.slate700,
        displayColor: AppColors.slate900,
      ).copyWith(
        // Display-family headings switch to Sora.
        displayLarge:  GoogleFonts.sora(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.slate900),
        displayMedium: GoogleFonts.sora(fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.slate900),
        displaySmall:  GoogleFonts.sora(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: AppColors.slate900),
        headlineLarge: GoogleFonts.sora(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: AppColors.slate900),
        headlineMedium: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.slate900),
        headlineSmall: GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.slate900),
        titleLarge:    GoogleFonts.sora(fontWeight: FontWeight.w700, color: AppColors.slate900),
        titleMedium:   GoogleFonts.sora(fontWeight: FontWeight.w600, color: AppColors.slate900),
      ),

      // ── Component defaults ─────────────────────────────────────────
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      iconTheme: const IconThemeData(color: AppColors.slate600, size: 20),

      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.sky500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sky700,
          side: const BorderSide(color: AppColors.outline),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: AppColors.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.rMd, borderSide: const BorderSide(color: AppColors.sky500, width: 1.5)),
        hintStyle: GoogleFonts.outfit(color: AppColors.slate400, fontSize: 14),
      ),

      // Phase 36.2 — dropdown menus.
      //
      // Material 3 leaves DropdownButton menu items with a semi-transparent
      // surface that lets the form below bleed through (visible as
      // "Male/Female/Other" rendering on top of "Public profile" toggle
      // and other form fields). Forcing an opaque white background + a
      // soft elevation makes the menu visually solid.
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.outfit(fontSize: 14, color: AppColors.slate900),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(3),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          ),
        ),
      ),
      // PopupMenuButton + DropdownButtonFormField also read this — same
      // opaque-white treatment so all menus look consistent.
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        textStyle: GoogleFonts.outfit(fontSize: 14, color: AppColors.slate900),
      ),

      // Splash / ripple — soft brand tint instead of default grey.
      splashColor:    AppColors.sky100,
      highlightColor: AppColors.sky50,

      // SnackBar — make it match the brand instead of black-with-white.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// System-chrome (status bar / nav bar) recipe. Apply once at app
  /// boot so iOS / Android system bars feel intentional rather than
  /// inheriting the default OEM colour.
  static const SystemUiOverlayStyle systemUiLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // hero is dark gradient → light icons
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}
