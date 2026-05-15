// CatalogApi — three typed fetch methods that hit the public catalog
// endpoints. Mirrors gum_web's `lib/api.ts`.
//
// All three are public (no auth) and degrade gracefully on error:
// returning an empty list rather than throwing keeps the home from
// breaking when the dev API is offline.

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../domain/language.dart';
import '../domain/sub_category.dart';

class CatalogApi {
  CatalogApi._();

  /// GET /languages?is_active=true&for_material=true
  /// Returns the languages the user can pick in the switcher.
  static Future<List<Language>> languages() async {
    try {
      final res = await ApiClient.dio.get(
        '/languages',
        queryParameters: {
          'is_active':    'true',
          'for_material': 'true',
          'limit':        100,
          'sort':         'name',
          'order':        'asc',
        },
      );
      final list = _extractList(res.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(Language.fromJson)
          .where((l) => l.isActive && l.forMaterial)
          .toList();
    } catch (e) {
      debugPrint('CatalogApi.languages failed: $e');
      return const [];
    }
  }

  /// GET /sub-categories?is_active=true&limit=100&sort=display_order&order=asc
  /// English baseline — fetched once at boot.
  static Future<List<SubCategory>> subCategories() async {
    try {
      final res = await ApiClient.dio.get(
        '/sub-categories',
        queryParameters: {
          'is_active': 'true',
          'limit':     100,
          'sort':      'display_order',
          'order':     'asc',
        },
      );
      final list = _extractList(res.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(SubCategory.fromJson)
          .toList();
    } catch (e) {
      debugPrint('CatalogApi.subCategories failed: $e');
      return const [];
    }
  }

  /// GET /sub-category-translations?language_id={id}&is_active=true&limit=200
  /// Returns a Map keyed by sub_category_id → translated name. We don't
  /// need the full record — only the name overlay.
  static Future<Map<int, String>> subCategoryTranslations(int languageId) async {
    try {
      final res = await ApiClient.dio.get(
        '/sub-category-translations',
        queryParameters: {
          'language_id': languageId,
          'is_active':   'true',
          'limit':       200,
        },
      );
      final list = _extractList(res.data);
      final out = <int, String>{};
      for (final row in list) {
        if (row is! Map<String, dynamic>) continue;
        final id   = (row['sub_category_id'] as num?)?.toInt();
        final name = row['name'] as String?;
        if (id != null && name != null && name.isNotEmpty) {
          out[id] = name;
        }
      }
      return out;
    } catch (e) {
      debugPrint('CatalogApi.subCategoryTranslations failed: $e');
      return const {};
    }
  }

  /// gum_api wraps list endpoints in `{ items: [...] }` or sometimes
  /// `{ data: [...] }`. Handle both shapes plus raw arrays.
  static List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final items = body['items'] ?? body['data'] ?? body['rows'];
      if (items is List) return items;
    }
    return const [];
  }
}
