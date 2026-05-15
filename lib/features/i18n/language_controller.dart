// LanguageController — single source of truth for "what language is
// the user looking at right now". Mirrors gum_web's LanguageProvider.
//
// Lifecycle:
//   1. `load()` is called once at app boot from main.dart
//   2. We hit /languages → populate `languages`
//   3. Read persisted ISO from SharedPreferences (key `gum_flutter.lang`)
//   4. Resolve to a Language object (fallback to English if not found)
//   5. notifyListeners → CategoriesController + UI react
//
// User action: `setActive(iso)` → updates state, persists, notifies.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../catalog/data/catalog_api.dart';
import '../catalog/domain/language.dart';
import 'messages.dart';

class LanguageController extends ChangeNotifier {
  /// SharedPreferences key — matches gum_web's `gum_web.lang` convention.
  static const String _prefsKey = 'gum_flutter.lang';

  List<Language> _languages = const [Language.english];
  Language       _active    = Language.english;
  bool           _loaded    = false;

  /// All pickable languages (only `for_material=true` after API load).
  List<Language> get languages => _languages;

  /// Currently active language. Never null — defaults to English.
  Language get active => _active;

  /// True once `load()` has fetched the languages list at least once.
  bool get isLoaded => _loaded;

  /// Active iso shortcut.
  String get iso => _active.isoCode;

  /// Static translations for the active language.
  Messages get t => Messages.forIso(_active.isoCode);

  // ── Load + persist ─────────────────────────────────────────────────

  /// Called once from main.dart before runApp.
  Future<void> load() async {
    // 1) Hit the API for the languages list.
    final remote = await CatalogApi.languages();
    if (remote.isNotEmpty) {
      _languages = remote;
    }

    // 2) Read the persisted active ISO, default to 'en'.
    final prefs = await SharedPreferences.getInstance();
    final savedIso = prefs.getString(_prefsKey) ?? 'en';

    // 3) Resolve to a Language, fallback to first available, then English.
    _active = _languages.firstWhere(
      (l) => l.isoCode.toLowerCase() == savedIso.toLowerCase(),
      orElse: () => _languages.firstWhere(
        (l) => l.isoCode == 'en',
        orElse: () => Language.english,
      ),
    );

    _loaded = true;
    notifyListeners();
  }

  /// Switch the active language. Persists silently in the background;
  /// listeners are notified immediately (UI updates without waiting).
  Future<void> setActive(String iso) async {
    if (iso.toLowerCase() == _active.isoCode.toLowerCase()) return;

    final next = _languages.firstWhere(
      (l) => l.isoCode.toLowerCase() == iso.toLowerCase(),
      orElse: () => _active, // unknown iso → no-op
    );
    if (next.isoCode == _active.isoCode) return;

    _active = next;
    notifyListeners();

    // Persist after notifying so UI is fast; failure here is silent.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, next.isoCode);
    } catch (_) {/* ignore */}
  }
}
