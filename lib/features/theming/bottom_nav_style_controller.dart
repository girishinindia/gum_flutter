// BottomNavStyleController — single source of truth for "which bottom
// nav style is active" on the home tab.
//
// Mirrors ThemeController's lifecycle exactly:
//   1. `load()` is called once at app boot from main.dart
//   2. Read persisted style id from SharedPreferences (key
//      `gum_flutter.bottom_nav_style`); default to `curved`.
//   3. notifyListeners → all `context.watch<BottomNavStyleController>()`
//      rebuild.
//
// User action: `setStyle(s)` → update state immediately, persist
// silently in the background (failures are non-fatal).
//
// Why a separate controller (not a flag on ThemeController):
//   • Theme is about COLOR palette; this is about nav LAYOUT shape.
//   • Keeping them apart means users can mix any palette with either
//     nav silhouette — 8 themes × 2 navs = 16 combinations, no extra
//     work.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The bottom-nav silhouettes the home screen can render.
enum BottomNavStyle {
  /// Phase 20.4 — branded curve with gradient fill, central circular
  /// FAB. The historical default. Kept as the default for new users.
  curved,

  /// Phase 43.15 — flat opaque pill with brand-tinted active state and
  /// a rotated-square ("diamond") central FAB.
  flatPill,

  /// Phase 43.16 — solid color bar with a concave dip carved under the
  /// active tab. The selected icon pops out above the dip in a small
  /// floating circle.
  notchedActive,

  /// Phase 43.16 — flat bar where the selected tab physically lifts
  /// above the surface inside a colored card. Other tabs stay flat.
  liftedCard,
}

extension BottomNavStyleX on BottomNavStyle {
  /// Human-readable label for picker UI.
  String get label {
    switch (this) {
      case BottomNavStyle.curved:        return 'Curved gradient';
      case BottomNavStyle.flatPill:      return 'Flat pill';
      case BottomNavStyle.notchedActive: return 'Notched active';
      case BottomNavStyle.liftedCard:    return 'Lifted card';
    }
  }

  /// One-line description shown under the label in the chooser.
  String get description {
    switch (this) {
      case BottomNavStyle.curved:
        return 'Branded curve · circular basket FAB';
      case BottomNavStyle.flatPill:
        return 'Flat surface · diamond FAB';
      case BottomNavStyle.notchedActive:
        return 'Concave dip under the active tab';
      case BottomNavStyle.liftedCard:
        return 'Active tab lifts into a colored card';
    }
  }

  /// Stable persistence id — DON'T rename, it's saved in user prefs.
  String get id {
    switch (this) {
      case BottomNavStyle.curved:        return 'curved';
      case BottomNavStyle.flatPill:      return 'flat_pill';
      case BottomNavStyle.notchedActive: return 'notched_active';
      case BottomNavStyle.liftedCard:    return 'lifted_card';
    }
  }
}

class BottomNavStyleController extends ChangeNotifier {
  /// SharedPreferences key — matches the `gum_flutter.<setting>`
  /// convention used by ThemeController / LanguageController.
  static const String _prefsKey = 'gum_flutter.bottom_nav_style';

  BottomNavStyle _style = BottomNavStyle.curved;
  bool           _loaded = false;

  /// Currently active style. Defaults to `curved` before `load()` runs.
  BottomNavStyle get style => _style;

  /// True once `load()` has finished resolving the persisted choice.
  bool get isLoaded => _loaded;

  // ── Load + persist ─────────────────────────────────────────────────

  /// Called once from main.dart at app boot.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefsKey);
      if (savedId != null) {
        _style = BottomNavStyle.values.firstWhere(
          (s) => s.id == savedId,
          orElse: () => BottomNavStyle.curved,
        );
      }
    } catch (_) {
      // Any SharedPreferences failure → fall back to default.
      _style = BottomNavStyle.curved;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Switch the active style. UI updates immediately; persistence
  /// happens after the notify so the swap feels instant. A persistence
  /// failure is silent — the in-memory choice still wins this session.
  Future<void> setStyle(BottomNavStyle next) async {
    if (next == _style) return;
    _style = next;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, next.id);
    } catch (_) {/* ignore */}
  }
}
