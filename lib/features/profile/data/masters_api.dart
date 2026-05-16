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

  Future<List<Country>> listCountries() => _getList<Country>(
        '/countries?is_active=true&limit=500&sort=name&ascending=true',
        Country.fromJson,
      );

  Future<List<StateRow>> listStates(int countryId) => _getList<StateRow>(
        '/states?country_id=$countryId&is_active=true&limit=500&sort=name&ascending=true',
        StateRow.fromJson,
      );

  Future<List<CityRow>> listCities(int stateId) => _getList<CityRow>(
        '/cities?state_id=$stateId&is_active=true&limit=2000&sort=name&ascending=true',
        CityRow.fromJson,
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

  // ── Shared helper ──────────────────────────────────────────────────

  Future<List<T>> _getList<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(fromJson).toList(growable: false);
    } catch (e) {
      throw ApiError.from(e);
    }
  }
}
