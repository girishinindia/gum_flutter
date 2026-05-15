// Single source of truth for ALL spacing on the home (and any other
// screen that wants to participate in the same rhythm).
//
// Every section, card, header, carousel and grid should reach for
// these constants instead of hard-coding a number. If we ever want
// to tighten or loosen the whole product, we change it in one place.
//
//   Hero        ──┐
//                 │  AppSpacing.section  (50)
//   Categories  ──┤
//                 │  AppSpacing.section  (50)
//   Featured    ──┤
//                 │  AppSpacing.section  (50)
//   Popular     ──┤
//   ...
//
// Inside a section:
//
//   ┌── eyebrow ──────────────────────────┐
//   │       AppSpacing.eyebrowToTitle (4) │
//   │   title                             │
//   │       AppSpacing.headerToContent(30)│
//   │   tile  tile  tile  tile            │
//   │       AppSpacing.tileGap        (12)│
//   │   tile  tile  tile  tile            │
//   └─────────────────────────────────────┘

class AppSpacing {
  AppSpacing._();

  // ── Inter-section ──────────────────────────────────────────────────
  /// Standard gap between two top-level home sections on white
  /// background (Featured → Popular Courses → Webinars → Bundles →
  /// Instructors → Reviews). Gives each section room to feel
  /// distinct on a flat surface.
  static const double section = 30;

  /// Custom top-margin for sections that sit DIRECTLY under the
  /// aurora hero (currently just `CategoriesGrid`). 20 px is enough
  /// breathing room from the hero gradient without leaving a dead
  /// band — the section's eyebrow text reads ~20 px below the
  /// gradient's bottom edge.
  static const double sectionTight = 20;

  // ── Intra-section ──────────────────────────────────────────────────
  /// Standard gap between a section header (title row) and the
  /// content below it (cards, carousel).
  static const double headerToContent = 20;

  /// Header-to-content gap for sections that pair with
  /// `sectionTight` (CategoriesGrid). Set to 14 because the h2
  /// title's 1.25 line-height adds ~5 px of leading below the
  /// visible glyph — so 14 px of padding renders as ~20 px of
  /// visible gap between "Browse Categories" and the first tile.
  static const double headerToContentTight = 14;

  /// Tight gap inside a section header — between the small EYEBROW
  /// label and the larger title beneath it.
  static const double eyebrowToTitle = 4;

  // ── Grid / carousel ────────────────────────────────────────────────
  /// Gap between adjacent cards in a horizontal carousel (offers,
  /// webinars, bundles, instructors, reviews).
  static const double cardGap = 12;

  /// Gap between adjacent tiles in a 2D grid (categories grid),
  /// applied to BOTH main and cross axes for visual uniformity.
  static const double tileGap = 12;

  // ── Page chrome ────────────────────────────────────────────────────
  /// Horizontal gutter from screen edge to content.
  static const double pageGutter = 16;

  /// Slightly larger horizontal inset for section headers (eyebrow +
  /// title), so they sit a touch further off the screen edge than the
  /// carousel cards. Equivalent to `pageGutter + 4`, but exposed as
  /// its own const so it can be used inside other const expressions.
  static const double sectionHeaderGutter = 20;
}
