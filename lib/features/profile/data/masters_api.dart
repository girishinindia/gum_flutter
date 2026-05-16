// Public master / lookup endpoints — no auth required, populate every
// dropdown on the profile page.
//
// Mirrors:
//   listCountries / listStates / listCities
//   listEducationLevels / listDesignations
//   searchMasterSkills / searchMasterLanguages
//   listDocumentTypes / listMasterDocuments
//   listSocialMediaPlatforms

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/master_models.dart';

class MastersApi {
  MastersApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  /// Even though these endpoints are public, we still send the Bearer
  /// when available — backend uses it for personalization (e.g. recently
  /// used). Opt out is unnecessary here.

  // Bug 2 fix — Phase 33.3:
  //
  // Dropped `is_active=true` from countries/states/cities so any row that
  // was later deactivated in admin still appears (otherwise a user who
  // had a since-deactivated city saved on their profile would see the
  // dropdown silently miss it). The page-walking `_getListAll` helper
  // tolerates large datasets — Tamil Nadu (~892 cities) already fits in
  // a single `limit=2000` page, but pagination is free defence against
  // future growth.

  Future<List<Country>> listCountries() => _getListAll<Country>(
        '/countries?sort=name&ascending=true',
        Country.fromJson,
        perPage: 500,
      );

  Future<List<StateRow>> listStates(int countryId) => _getListAll<StateRow>(
        '/states?country_id=$countryId&sort=name&ascending=true',
        StateRow.fromJson,
        perPage: 500,
      );

  Future<List<CityRow>> listCities(int stateId) => _getListAll<CityRow>(
        '/cities?state_id=$stateId&sort=name&ascending=true',
        CityRow.fromJson,
        perPage: 2000,
      );

  Future<List<EducationLevel>> listEducationLevels() => _getList<EducationLevel>(
        '/education-levels?is_active=true&limit=500&sort=level_order&ascending=true',
        EducationLevel.fromJson,
      );

  Future<List<Designation>> listDesignations() => _getList<Designation>(
        '/designations?is_active=true&limit=1000&sort=level&ascending=true',
        Designation.fromJson,
      );

  Future<List<MasterSkill>> searchSkills(String q, {int limit = 20}) {
    final qp = <String, String>{
      if (q.trim().isNotEmpty) 'search': q.trim(),
      'limit': '$limit',
      'is_active': 'true',
      'ascending': 'true',
    };
    return _getList<MasterSkill>(
      '/skills?${Uri(queryParameters: qp).query}',
      MasterSkill.fromJson,
    );
  }

  Future<List<MasterLanguage>> searchLanguages(String q, {int limit = 20}) {
    final qp = <String, String>{
      if (q.trim().isNotEmpty) 'search': q.trim(),
      'limit': '$limit',
      'is_active': 'true',
      'ascending': 'true',
    };
    return _getList<MasterLanguage>(
      '/languages?${Uri(queryParameters: qp).query}',
      MasterLanguage.fromJson,
    );
  }

  Future<List<DocumentType>> listDocumentTypes() => _getList<DocumentType>(
        '/document-types?is_active=true&limit=500&sort=name&ascending=true',
        DocumentType.fromJson,
      );

  Future<List<MasterDocument>> listMasterDocuments(int typeId) => _getList<MasterDocument>(
        '/documents?document_type_id=$typeId&is_active=true&limit=500&sort=name&ascending=true',
        MasterDocument.fromJson,
      );

  Future<List<SocialMediaPlatform>> listSocialMediaPlatforms() => _getList<SocialMediaPlatform>(
        '/social-medias?is_active=true&limit=50&sort=display_order&ascending=true',
        SocialMediaPlatform.fromJson,
      );

  // ── Shared helpers ─────────────────────────────────────────────────

  Future<List<T>> _getList<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(fromJson).toList(growable: false);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// Paginating variant — walks every page until the server reports
  /// we've consumed all rows. Used for the cascading geo dropdowns where
  /// truncation is a real bug rather than a feature. Caller passes the
  /// base path WITHOUT page/limit; this helper appends them per request.
  Future<List<T>> _getListAll<T>(
    String basePath,
    T Function(Map<String, dynamic>) fromJson, {
    int perPage = 500,
  }) async {
    final out = <T>[];
    var page = 1;
    // Safety stop — protects against a misreporting server saying
    // totalPages: 999. We won't realistically have geo lists > 50k rows.
    const hardPageCap = 50;
    try {
      while (page <= hardPageCap) {
        final sep = basePath.contains('?') ? '&' : '?';
        final path = '$basePath${sep}page=$page&limit=$perPage';
        final res = await _dio.get<Map<String, dynamic>>(path);
        final body = res.data;
        final rows = (body?['data'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(fromJson)
            .toList(growable: false);
        out.addAll(rows);

        final pagination = body?['pagination'] as Map<String, dynamic>?;
        final totalPages = (pagination?['totalPages'] as num?)?.toInt();
        final total      = (pagination?['total']      as num?)?.toInt();
        if (totalPages != null) {
          if (page >= totalPages) break;
        } else if (total != null) {
          if (out.length >= total) break;
        } else if (rows.length < perPage) {
          break;
        }
        page += 1;
      }
      return out;
    } catch (e) {
      throw ApiError.from(e);
    }
  }
}
