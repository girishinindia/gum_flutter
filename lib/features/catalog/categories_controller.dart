// CategoriesController — owns the home's category list.
//
// Pattern (mirrors gum_web's CategoriesGrid client component):
//   1. Boot → fetch English baseline from /sub-categories
//   2. Listen to LanguageController.
//   3. On language change:
//        • iso === 'en' → reset displayed list to baseline (no fetch)
//        • else → fetch translations, build Map<id, name>, overlay
//          names onto the BASELINE list (preserves position).
//   4. UI consumes `displayed` via Consumer<CategoriesController>.

import 'package:flutter/foundation.dart';

import 'data/catalog_api.dart';
import 'domain/sub_category.dart';
import '../i18n/language_controller.dart';

class CategoriesController extends ChangeNotifier {
  CategoriesController({required this.languageController}) {
    // React to language changes.
    languageController.addListener(_onLanguageChanged);
  }

  final LanguageController languageController;

  List<SubCategory> _english   = const []; // baseline (English-ordered)
  List<SubCategory> _displayed = const []; // what the UI renders
  bool _loaded = false;
  bool _switching = false;
  int  _switchToken = 0; // guards against out-of-order responses

  /// True once the English baseline has been fetched at least once.
  bool get isLoaded => _loaded;

  /// True while a per-language translation fetch is in flight.
  bool get isSwitching => _switching;

  /// The list the UI should render. Always in English display order.
  List<SubCategory> get displayed => _displayed;

  // ── Boot ───────────────────────────────────────────────────────────

  /// Called once from main.dart after LanguageController.load(). Fetches
  /// the English baseline and applies any in-flight language overlay.
  Future<void> load() async {
    final baseline = await CatalogApi.subCategories();
    _english = baseline;
    _displayed = baseline;
    _loaded = true;

    // If the user's persisted language isn't English, apply the overlay.
    if (languageController.iso.toLowerCase() != 'en') {
      // Don't await — let the UI render English first, then swap in
      // the translated names as soon as they arrive.
      // ignore: unawaited_futures
      _applyOverlay(languageController.active.id);
    }
    notifyListeners();
  }

  // ── Reactivity ─────────────────────────────────────────────────────

  void _onLanguageChanged() {
    if (!_loaded) return; // baseline not in yet, load() will handle
    if (languageController.iso.toLowerCase() == 'en') {
      _displayed = _english;
      notifyListeners();
      return;
    }
    // ignore: unawaited_futures
    _applyOverlay(languageController.active.id);
  }

  Future<void> _applyOverlay(int languageId) async {
    _switching = true;
    notifyListeners();

    final token = ++_switchToken;
    final overlay = await CatalogApi.subCategoryTranslations(languageId);

    // If the user switched again while we were fetching, ignore stale result.
    if (token != _switchToken) return;

    _displayed = _english
        .map((c) => c.copyWith(translatedName: overlay[c.id]))
        .toList(growable: false);
    _switching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    languageController.removeListener(_onLanguageChanged);
    super.dispose();
  }
}
