// Language model — mirrors the gum_api `languages` table shape.
//
// We keep this tight: only the fields the UI cares about. Native name
// is what shows in the switcher (e.g., "हिन्दी"), iso_code is the
// stable identifier we persist to SharedPreferences.

class Language {
  final int     id;
  final String  name;          // "Hindi"
  final String  isoCode;       // "hi"
  final String? nativeName;    // "हिन्दी"
  final bool    isActive;
  final bool    forMaterial;   // only true ones show in the switcher

  const Language({
    required this.id,
    required this.name,
    required this.isoCode,
    this.nativeName,
    this.isActive    = true,
    this.forMaterial = true,
  });

  /// Display label for the switcher row — prefers native name.
  String get label => (nativeName?.isNotEmpty ?? false) ? nativeName! : name;

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id:           (json['id'] as num?)?.toInt() ?? 0,
      name:         (json['name'] ?? '') as String,
      isoCode:      (json['iso_code'] ?? '') as String,
      nativeName:   json['native_name'] as String?,
      isActive:     json['is_active']    as bool? ?? true,
      forMaterial:  json['for_material'] as bool? ?? true,
    );
  }

  /// Built-in fallback used when the API hasn't responded yet — so
  /// the home doesn't show "Untitled" categories before the languages
  /// list arrives.
  static const Language english = Language(
    id: 1, name: 'English', isoCode: 'en', nativeName: 'English',
  );
}
