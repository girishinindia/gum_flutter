// Typed Dio services for every `/user-*/me` sub-resource plus
// `/user-profiles/me` and `/instructor-profiles/me`.
//
// Layout mirrors `gum_web/lib/users/client.ts` — one service per
// resource keeps the API surface predictable.

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/user_profile.dart';
import '../domain/user_sub_resources.dart';

// ═══════════════════════════════════════════════════════════════════════
// /user-profiles/me — extended profile (KYC, address, bio, etc.)
// ═══════════════════════════════════════════════════════════════════════

class ProfileApi {
  ProfileApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<UserProfile> getMyProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-profiles/me');
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return UserProfile.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserProfile> updateMyProfile(Map<String, dynamic> patch) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/user-profiles/me', data: patch);
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return UserProfile.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// Multipart variant of [updateMyProfile] — used when uploading the
  /// avatar (`profile_image`) and/or cover (`cover_image`). The server
  /// route is wrapped with `upload.fields(profile_image, cover_image)`
  /// plus the `coerceNullStrings` middleware (Phase 30.2), so any null
  /// values in [patch] get encoded as the literal "null" and the server
  /// turns them back into real null before update.
  Future<UserProfile> updateMyProfileWithImage({
    Map<String, dynamic>? patch,
    String? profileImagePath,
    String? profileImageFilename,
    String? profileImageMimeType,
    String? coverImagePath,
    String? coverImageFilename,
    String? coverImageMimeType,
  }) async {
    try {
      final fd = FormData();
      (patch ?? const <String, dynamic>{}).forEach((k, v) {
        if (v == null) {
          fd.fields.add(MapEntry(k, 'null'));
        } else if (v is bool) {
          fd.fields.add(MapEntry(k, v ? 'true' : 'false'));
        } else if (v is DateTime) {
          fd.fields.add(MapEntry(k, v.toIso8601String()));
        } else {
          fd.fields.add(MapEntry(k, v.toString()));
        }
      });
      if (profileImagePath != null) {
        fd.files.add(MapEntry(
          'profile_image',
          MultipartFile.fromFileSync(
            profileImagePath,
            filename: profileImageFilename,
            contentType: profileImageMimeType != null ? MediaType.parse(profileImageMimeType) : null,
          ),
        ));
      }
      if (coverImagePath != null) {
        fd.files.add(MapEntry(
          'cover_image',
          MultipartFile.fromFileSync(
            coverImagePath,
            filename: coverImageFilename,
            contentType: coverImageMimeType != null ? MediaType.parse(coverImageMimeType) : null,
          ),
        ));
      }
      final res = await _dio.put<Map<String, dynamic>>(
        '/user-profiles/me',
        data: fd,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return UserProfile.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /user-education — multipart (optional certificate file)
// ═══════════════════════════════════════════════════════════════════════

class EducationApi {
  EducationApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserEducation>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-education/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw
          .whereType<Map<String, dynamic>>()
          .map(UserEducation.fromJson)
          .toList(growable: false);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserEducation> add(
    Map<String, dynamic> payload, {
    EducationCertFile? certificate,
  }) async {
    try {
      final fd = _multipartFor(payload, fileField: 'certificate', file: certificate);
      final res = await _dio.post<Map<String, dynamic>>(
        '/user-education/me',
        data: fd,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return UserEducation.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserEducation> update(
    int id,
    Map<String, dynamic> patch, {
    EducationCertFile? certificate,
  }) async {
    try {
      final fd = _multipartFor(patch, fileField: 'certificate', file: certificate);
      final res = await _dio.patch<Map<String, dynamic>>(
        '/user-education/me/$id',
        data: fd,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = unwrapEnvelope<Map<String, dynamic>>(res);
      return UserEducation.fromJson(data);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/user-education/me/$id');
    } catch (e) {
      throw ApiError.from(e);
    }
  }
}

/// Lightweight wrapper so we can pass either an XFile (image_picker)
/// or a PlatformFile (file_picker) through without leaking framework
/// types into the API layer.
class EducationCertFile {
  EducationCertFile({required this.path, required this.filename, this.mimeType});
  final String  path;
  final String  filename;
  final String? mimeType;
}

// ═══════════════════════════════════════════════════════════════════════
// /user-experience
// ═══════════════════════════════════════════════════════════════════════

class ExperienceApi {
  ExperienceApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserExperience>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-experience/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserExperience.fromJson).toList(growable: false);
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserExperience> add(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/user-experience/me', data: payload);
      return UserExperience.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserExperience> update(int id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/user-experience/me/$id', data: patch);
      return UserExperience.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<void> delete(int id) async {
    try { await _dio.delete<Map<String, dynamic>>('/user-experience/me/$id'); }
    catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /user-projects
// ═══════════════════════════════════════════════════════════════════════

class ProjectsApi {
  ProjectsApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserProject>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-projects/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserProject.fromJson).toList(growable: false);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserProject> add(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/user-projects/me', data: payload);
      return UserProject.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserProject> update(int id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/user-projects/me/$id', data: patch);
      return UserProject.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<void> delete(int id) async {
    try { await _dio.delete<Map<String, dynamic>>('/user-projects/me/$id'); }
    catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /user-skills + /user-languages — FK to master skills/languages
// ═══════════════════════════════════════════════════════════════════════

class SkillsApi {
  SkillsApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserSkill>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-skills/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserSkill.fromJson).toList(growable: false);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserSkill> add(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/user-skills/me', data: body);
      return UserSkill.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserSkill> update(int id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/user-skills/me/$id', data: patch);
      return UserSkill.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<void> delete(int id) async {
    try { await _dio.delete<Map<String, dynamic>>('/user-skills/me/$id'); }
    catch (e) { throw ApiError.from(e); }
  }
}

class LanguagesApi {
  LanguagesApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserLanguage>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-languages/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserLanguage.fromJson).toList(growable: false);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserLanguage> add(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/user-languages/me', data: body);
      return UserLanguage.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserLanguage> update(int id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/user-languages/me/$id', data: patch);
      return UserLanguage.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<void> delete(int id) async {
    try { await _dio.delete<Map<String, dynamic>>('/user-languages/me/$id'); }
    catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /user-social-medias
// ═══════════════════════════════════════════════════════════════════════

class SocialMediaApi {
  SocialMediaApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserSocialMedia>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-social-medias/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserSocialMedia.fromJson).toList(growable: false);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserSocialMedia> add(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/user-social-medias/me', data: body);
      return UserSocialMedia.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserSocialMedia> update(int id, Map<String, dynamic> patch) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>('/user-social-medias/me/$id', data: patch);
      return UserSocialMedia.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<void> delete(int id) async {
    try { await _dio.delete<Map<String, dynamic>>('/user-social-medias/me/$id'); }
    catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /user-documents — multipart (optional file)
// ═══════════════════════════════════════════════════════════════════════

class DocumentsApi {
  DocumentsApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserDocument>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-documents/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserDocument.fromJson).toList(growable: false);
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserDocument> add(Map<String, dynamic> payload, {EducationCertFile? file}) async {
    try {
      final fd = _multipartFor(payload, fileField: 'file', file: file);
      final res = await _dio.post<Map<String, dynamic>>(
        '/user-documents/me',
        data: fd,
        options: Options(contentType: 'multipart/form-data'),
      );
      return UserDocument.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<UserDocument> update(int id, Map<String, dynamic> patch, {EducationCertFile? file}) async {
    try {
      final fd = _multipartFor(patch, fileField: 'file', file: file);
      final res = await _dio.patch<Map<String, dynamic>>(
        '/user-documents/me/$id',
        data: fd,
        options: Options(contentType: 'multipart/form-data'),
      );
      return UserDocument.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<void> delete(int id) async {
    try { await _dio.delete<Map<String, dynamic>>('/user-documents/me/$id'); }
    catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /user-badges (read-only)
// ═══════════════════════════════════════════════════════════════════════

class BadgesApi {
  BadgesApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<List<UserBadge>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user-badges/me');
      final raw = unwrapEnvelope<List<dynamic>>(res);
      return raw.whereType<Map<String, dynamic>>().map(UserBadge.fromJson).toList(growable: false);
    } catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// /instructor-profiles/me — instructor-only extended profile
// ═══════════════════════════════════════════════════════════════════════

class InstructorProfileApi {
  InstructorProfileApi({Dio? dio}) : _dio = dio ?? ApiClient.dio;
  final Dio _dio;

  Future<InstructorProfile> get() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/instructor-profiles/me');
      return InstructorProfile.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }

  Future<InstructorProfile> update(Map<String, dynamic> patch) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>('/instructor-profiles/me', data: patch);
      return InstructorProfile.fromJson(unwrapEnvelope<Map<String, dynamic>>(res));
    } catch (e) { throw ApiError.from(e); }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Multipart helpers
// ═══════════════════════════════════════════════════════════════════════

/// Build a Dio `FormData` from a field map plus an optional file.
/// Same semantics as the web `buildFormData`:
///   • `null`  → "null"      (server's `parseBody()` treats this as "clear column")
///   • bool    → "true"/"false"
///   • DateTime → ISO 8601 string
///   • undefined / missing keys → skipped entirely
FormData _multipartFor(
  Map<String, dynamic> fields, {
  required String fileField,
  EducationCertFile? file,
}) {
  final fd = FormData();
  fields.forEach((k, v) {
    if (v == null) {
      fd.fields.add(MapEntry(k, 'null'));
    } else if (v is bool) {
      fd.fields.add(MapEntry(k, v ? 'true' : 'false'));
    } else if (v is DateTime) {
      fd.fields.add(MapEntry(k, v.toIso8601String()));
    } else {
      fd.fields.add(MapEntry(k, v.toString()));
    }
  });
  if (file != null) {
    fd.files.add(MapEntry(
      fileField,
      MultipartFile.fromFileSync(
        file.path,
        filename: file.filename,
        contentType: file.mimeType != null ? MediaType.parse(file.mimeType!) : null,
      ),
    ));
  }
  return fd;
}
