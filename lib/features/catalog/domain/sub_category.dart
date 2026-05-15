// SubCategory — the unit of the categories grid on the home.
//
// Two-phase shape:
//   1. English baseline from /sub-categories → englishName populated
//   2. Per-language overlay from /sub-category-translations →
//      translatedName populated
//
// `displayName` does the gum_web fallback chain:
//   translatedName → englishName → titlecase(slug) → code → 'Untitled'

class SubCategory {
  final int     id;
  final String  slug;             // "ai-ml", "web-dev"
  final String? code;             // "AI/ML"
  final String? englishName;      // "AI / ML"
  final String? translatedName;   // overlaid after language switch
  final String? imageUrl;
  final int?    parentCategoryId;
  final String? parentSlug;
  final int     displayOrder;
  final int     courseCount;

  const SubCategory({
    required this.id,
    required this.slug,
    this.code,
    this.englishName,
    this.translatedName,
    this.imageUrl,
    this.parentCategoryId,
    this.parentSlug,
    this.displayOrder = 0,
    this.courseCount  = 0,
  });

  /// Resolved display label using the fallback chain.
  String get displayName {
    final t = translatedName;
    if (t != null && t.isNotEmpty) return t;
    final e = englishName;
    if (e != null && e.isNotEmpty) return e;
    final c = code;
    if (c != null && c.isNotEmpty) return c;
    final s = _titleCase(slug);
    return s.isNotEmpty ? s : 'Untitled';
  }

  SubCategory copyWith({String? translatedName}) => SubCategory(
        id:               id,
        slug:             slug,
        code:             code,
        englishName:      englishName,
        translatedName:   translatedName ?? this.translatedName,
        imageUrl:         imageUrl,
        parentCategoryId: parentCategoryId,
        parentSlug:       parentSlug,
        displayOrder:     displayOrder,
        courseCount:      courseCount,
      );

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    // Parent category may arrive as a nested object on /sub-categories.
    final cat = json['categories'];
    final parentSlug = cat is Map<String, dynamic>
        ? cat['slug'] as String?
        : null;

    return SubCategory(
      id:               (json['id'] as num?)?.toInt() ?? 0,
      slug:             (json['slug'] ?? '') as String,
      code:             json['code']        as String?,
      englishName:      json['english_name'] as String?,
      imageUrl:         json['image_url']    as String?,
      parentCategoryId: (json['category_id'] as num?)?.toInt(),
      parentSlug:       parentSlug,
      displayOrder:     (json['display_order'] as num?)?.toInt() ?? 0,
      courseCount:      (json['course_count']  as num?)?.toInt() ?? 0,
    );
  }

  /// Convert "web-dev" → "Web Dev".
  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r'[-_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }
}
