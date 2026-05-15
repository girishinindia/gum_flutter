// Single source of truth for ALL spacing on the home (and any other
// screen that wants to participate in the same rhythm).
//
// Every section, card, header, carousel and grid should reach for
// these constants instead of hard-coding a number. If we ever want
// to tighten or loosen the whole product, we change it in one place.
//
//   Hero        ──┐
//                 │  AppSpacing.section
//   Categories  ──┤
//                 │  AppSpacing.section
//   Featured    ──┤
//                 │  AppSpacing.section
//   Popular     ──┤
//   ...

import 'package:flutter/widgets.dart';

class AppSpacing {
  AppSpacing._();

  // ── Inter-section ──────────────────────────────────────────────────
  /// Standard gap between two top-level home sections (Featured →
  /// Popular Courses → Webinars → Bundles → Instructors → Reviews).
  ///
  /// 30 px is the **phone** default. Use [sectionFor] inside builds
  /// to get a per-breakpoint value (40 on tablet-portrait, 48 on
  /// tablet-landscape). The constant exists so const sites still
  /// compile.
  static const double section = 30;

  /// Per-breakpoint section gap — phones standard, tablets a touch
  /// more breathing room. Use from widget builds:
  ///
  ///   padding: EdgeInsets.only(top: AppSpacing.sectionFor(context))
  static double sectionFor(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 48; // tablet-landscape
    if (w >= 600) return 40; // tablet-portrait
    return section;          // phones → 30
  }

  /// Custom top-margin for sections that sit DIRECTLY under the
  /// aurora hero (currently just `CategoriesGrid`). Tighter than
  /// `section` because the gradient already provides separation.
  static const double sectionTight = 10;

  /// Per-breakpoint version of `sectionTight`.
  static double sectionTightFor(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 900) return 20; // tablet-landscape
    if (w >= 600) return 16; // tablet-portrait
    return sectionTight;     // phones → 10
  }

  // ── Intra-section ──────────────────────────────────────────────────
  /// Standard gap between a section header (title row) and the
  /// content below it (cards, carousel).
  static const double headerToContent = 16;

  /// Per-breakpoint header→content gap (a bit more breathing on tablets).
  static double headerToContentFor(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 600) return 20;
    return headerToContent; // phones → 16
  }

  /// Header-to-content gap for sections that pair with
  /// `sectionTight` (CategoriesGrid). Tighter so EXPLORE/Browse
  /// Categories sit close to the tile grid.
  static const double headerToContentTight = 6;

  /// Tight gap inside a section header — between the small EYEBROW
  /// label and the larger title beneath it.
  static const double eyebrowToTitle = 4;

  // ── Grid / carousel ────────────────────────────────────────────────
  /// Gap between adjacent cards in a horizontal carousel.
  static const double cardGap = 12;

  /// Gap between adjacent tiles in a 2D grid (categories grid),
  /// applied to BOTH main and cross axes.
  static const double tileGap = 12;

  // ── Page chrome ────────────────────────────────────────────────────
  /// Horizontal gutter from screen edge to content.
  static const double pageGutter = 16;

  /// Slightly larger horizontal inset for section headers.
  static const double sectionHeaderGutter = 20;
}
