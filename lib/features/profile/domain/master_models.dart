// Master / lookup table rows. Public GETs that populate the profile
// page dropdowns. Each shape mirrors `gum_web/lib/users/client.ts`.

import 'package:equatable/equatable.dart';

// ── Geography ──────────────────────────────────────────────────────────

class Country extends Equatable {
  const Country({required this.id, required this.name, this.iso2, this.iso3});
  final int id;
  final String name;
  final String? iso2;
  final String? iso3;
  factory Country.fromJson(Map<String, dynamic> j) => Country(
        id:   (j['id'] as num).toInt(),
        name: (j['name'] ?? '') as String,
        iso2: j['iso2'] as String?,
        iso3: j['iso3'] as String?,
      );
  @override List<Object?> get props => [id, name, iso2, iso3];
}

class StateRow extends Equatable {
  const StateRow({required this.id, required this.countryId, required this.name, this.stateCode});
  final int id;
  final int countryId;
  final String name;
  final String? stateCode;
  factory StateRow.fromJson(Map<String, dynamic> j) => StateRow(
        id:        (j['id'] as num).toInt(),
        countryId: (j['country_id'] as num).toInt(),
        name:      (j['name'] ?? '') as String,
        stateCode: j['state_code'] as String?,
      );
  @override List<Object?> get props => [id, countryId, name, stateCode];
}

class CityRow extends Equatable {
  const CityRow({required this.id, required this.stateId, required this.name});
  final int id;
  final int stateId;
  final String name;
  factory CityRow.fromJson(Map<String, dynamic> j) => CityRow(
        id:      (j['id'] as num).toInt(),
        stateId: (j['state_id'] as num).toInt(),
        name:    (j['name'] ?? '') as String,
      );
  @override List<Object?> get props => [id, stateId, name];
}

// ── Education ladder ─────────────────────────────────────────────────

class EducationLevel extends Equatable {
  const EducationLevel({
    required this.id,
    required this.name,
    this.abbreviation,
    this.levelOrder,
    this.levelCategory,
  });
  final int     id;
  final String  name;
  final String? abbreviation;
  final int?    levelOrder;
  final String? levelCategory;
  factory EducationLevel.fromJson(Map<String, dynamic> j) => EducationLevel(
        id:            (j['id'] as num).toInt(),
        name:          (j['name'] ?? '') as String,
        abbreviation:  j['abbreviation'] as String?,
        levelOrder:    (j['level_order'] as num?)?.toInt(),
        levelCategory: j['level_category'] as String?,
      );
  @override List<Object?> get props => [id, name, abbreviation, levelOrder, levelCategory];
}

// ── Designation ──────────────────────────────────────────────────────

class Designation extends Equatable {
  const Designation({
    required this.id,
    required this.name,
    this.code,
    this.level,
    this.levelBand,
  });
  final int     id;
  final String  name;
  final String? code;
  final int?    level;
  final String? levelBand;
  factory Designation.fromJson(Map<String, dynamic> j) => Designation(
        id:        (j['id'] as num).toInt(),
        name:      (j['name'] ?? '') as String,
        code:      j['code'] as String?,
        level:     (j['level'] as num?)?.toInt(),
        levelBand: j['level_band'] as String?,
      );
  @override List<Object?> get props => [id, name, code, level, levelBand];
}

// ── Skills + Languages master rows ───────────────────────────────────

class MasterSkill extends Equatable {
  const MasterSkill({required this.id, required this.name, this.category});
  final int id;
  final String name;
  final String? category;
  factory MasterSkill.fromJson(Map<String, dynamic> j) => MasterSkill(
        id:       (j['id'] as num).toInt(),
        name:     (j['name'] ?? '') as String,
        category: j['category'] as String?,
      );
  @override List<Object?> get props => [id, name, category];
}

class MasterLanguage extends Equatable {
  const MasterLanguage({
    required this.id,
    required this.name,
    this.nativeName,
    this.isoCode,
  });
  final int     id;
  final String  name;
  final String? nativeName;
  final String? isoCode;
  factory MasterLanguage.fromJson(Map<String, dynamic> j) => MasterLanguage(
        id:         (j['id'] as num).toInt(),
        name:       (j['name'] ?? '') as String,
        nativeName: j['native_name'] as String?,
        isoCode:    j['iso_code'] as String?,
      );
  @override List<Object?> get props => [id, name, nativeName, isoCode];
}

// ── Document types + documents ───────────────────────────────────────

class DocumentType extends Equatable {
  const DocumentType({required this.id, required this.name, this.description});
  final int id;
  final String name;
  final String? description;
  factory DocumentType.fromJson(Map<String, dynamic> j) => DocumentType(
        id:          (j['id'] as num).toInt(),
        name:        (j['name'] ?? '') as String,
        description: j['description'] as String?,
      );
  @override List<Object?> get props => [id, name, description];
}

class MasterDocument extends Equatable {
  const MasterDocument({
    required this.id,
    required this.documentTypeId,
    required this.name,
    this.description,
  });
  final int     id;
  final int     documentTypeId;
  final String  name;
  final String? description;
  factory MasterDocument.fromJson(Map<String, dynamic> j) => MasterDocument(
        id:             (j['id'] as num).toInt(),
        documentTypeId: (j['document_type_id'] as num).toInt(),
        name:           (j['name'] ?? '') as String,
        description:    j['description'] as String?,
      );
  @override List<Object?> get props => [id, documentTypeId, name, description];
}

// ── Social media platform ────────────────────────────────────────────

class SocialMediaPlatform extends Equatable {
  const SocialMediaPlatform({
    required this.id,
    required this.name,
    required this.code,
    this.baseUrl,
    this.icon,
    this.placeholder,
    this.platformType,
  });
  final int     id;
  final String  name;
  final String  code;
  final String? baseUrl;
  final String? icon;
  final String? placeholder;
  final String? platformType;
  factory SocialMediaPlatform.fromJson(Map<String, dynamic> j) => SocialMediaPlatform(
        id:           (j['id'] as num).toInt(),
        name:         (j['name'] ?? '') as String,
        code:         (j['code'] ?? '') as String,
        baseUrl:      j['base_url']      as String?,
        icon:         j['icon']          as String?,
        placeholder:  j['placeholder']   as String?,
        platformType: j['platform_type'] as String?,
      );
  @override List<Object?> get props => [id, name, code, baseUrl, icon, placeholder, platformType];
}
