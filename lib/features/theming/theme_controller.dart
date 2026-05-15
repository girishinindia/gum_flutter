// ThemeController — single source of truth for "which theme is active".
//
// Mirrors LanguageController's lifecycle exactly so behaviour is
// predictable & debuggable:
//   1. `load()` is called once at app boot from main.dart
//   2. Read persisted theme id from SharedPreferences (key
//      `gum_flutter.theme`); default to `'aurora'`.
//   3. Resolve to an AppPalette via ThemePresets.byId (unknown ids
//      fall back to Aurora).
//   4. notifyListeners → all `context.watch<ThemeController>()` rebuild.
//
// User action: `setActive(id)` → update state immediately, persist
// silently in the background (failures are non-fatal).

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/theme_presets.dart';
import 'domain/app_palette.dart';

class ThemeController extends ChangeNotifier {
  /// SharedPreferences key — matches the `gum_flutter.lang` convention.
  static const String _prefsKey = 'gum_flutter.theme';

  AppPalette _palette = ThemePresets.aurora;
  bool       _loaded  = false;

  /// All pickable themes (constant — comes from ThemePresets.all).
  List<AppPalette> get themes => ThemePresets.all;

  /// Currently active palette. Defaults to Aurora before `load()` runs.
  AppPalette get palette => _palette;

  /// Currently active id shortcut (handy for picker check marks).
  String get activeId => _palette.id;

  /// True once `load()` has finished resolving the persisted choice.
  bool get isLoaded => _loaded;

  // ── Load + persist ─────────────────────────────────────────────────

  /// Called once from main.dart at app boot.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefsKey) ?? ThemePresets.aurora.id;
      _palette = ThemePresets.byId(savedId);
    } catch (_) {
      // Any SharedPreferences failure → fall back to default theme.
      _palette = ThemePresets.aurora;
    }
    _loaded = true;
    notifyListeners();
  }

  /// Switch the active theme. UI updates immediately; persistence
  /// happens after the notify so the swap feels instant. A persistence
  /// failure is silent — the in-memory choice still wins this session.
  Future<void> setActive(String id) async {
    if (id == _palette.id) return;

    final next = ThemePresets.byId(id);
    if (next.id == _palette.id) return; // unknown id resolved to current → no-op

    _palette = next;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, next.id);
    } catch (_) {/* ignore */}
  }
}
