// slug → visual treatment (icon + gradient + glow). The API doesn't
// return Material icon code-points or hex colours, so we keep a small
// table on the frontend keyed by sub-category slug. Unknown slugs get
// a generic fallback so new categories don't break the home.
//
// Add a new slug → icon mapping here whenever the catalog team adds
// a new sub-category. The fallback keeps the app shippable in the
// meantime.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

@immutable
class CategoryIconStyle {
  final IconData icon;
  final List<Color> iconGradient;  // 2-stop chip gradient
  final Color glowTint;            // radial glow + bottom accent line

  const CategoryIconStyle({
    required this.icon,
    required this.iconGradient,
    required this.glowTint,
  });
}

class CategoryIconStyles {
  CategoryIconStyles._();

  /// Generic fallback used for slugs we don't have a mapping for yet.
  static const CategoryIconStyle fallback = CategoryIconStyle(
    icon:         Icons.category_rounded,
    iconGradient: [AppColors.sky500, AppColors.accent],
    glowTint:     AppColors.sky500,
  );

  /// Map keyed by sub-category slug. Normalised to lower-case at
  /// lookup time so the API can return any casing.
  static const Map<String, CategoryIconStyle> _bySlug = {
    'courses': CategoryIconStyle(
      icon: Icons.menu_book_rounded,
      iconGradient: [AppColors.sky500, AppColors.accent],
      glowTint: AppColors.sky500,
    ),
    'ai-ml': CategoryIconStyle(
      icon: Icons.psychology_alt_rounded,
      iconGradient: [AppColors.success, AppColors.sky500],
      glowTint: AppColors.success,
    ),
    'ai': CategoryIconStyle(
      icon: Icons.psychology_alt_rounded,
      iconGradient: [AppColors.success, AppColors.sky500],
      glowTint: AppColors.success,
    ),
    'web-dev': CategoryIconStyle(
      icon: Icons.code_rounded,
      iconGradient: [AppColors.amber, AppColors.rose],
      glowTint: AppColors.amber,
    ),
    'cyber': CategoryIconStyle(
      icon: Icons.shield_rounded,
      iconGradient: [AppColors.violet500, AppColors.accent],
      glowTint: AppColors.violet500,
    ),
    'cyber-security': CategoryIconStyle(
      icon: Icons.shield_rounded,
      iconGradient: [AppColors.violet500, AppColors.accent],
      glowTint: AppColors.violet500,
    ),
    'cloud': CategoryIconStyle(
      icon: Icons.cloud_rounded,
      iconGradient: [AppColors.accent, AppColors.sky400],
      glowTint: AppColors.accent,
    ),
    'database': CategoryIconStyle(
      icon: Icons.storage_rounded,
      iconGradient: [AppColors.rose, AppColors.amber],
      glowTint: AppColors.rose,
    ),
    'design': CategoryIconStyle(
      icon: Icons.palette_rounded,
      iconGradient: [AppColors.violet500, AppColors.rose],
      glowTint: AppColors.violet500,
    ),
    'marketing': CategoryIconStyle(
      icon: Icons.trending_up_rounded,
      iconGradient: [AppColors.success, AppColors.accent],
      glowTint: AppColors.success,
    ),
    'mobile': CategoryIconStyle(
      icon: Icons.phone_iphone_rounded,
      iconGradient: [AppColors.sky500, AppColors.violet500],
      glowTint: AppColors.sky500,
    ),
    'devops': CategoryIconStyle(
      icon: Icons.settings_input_component_rounded,
      iconGradient: [AppColors.accent, AppColors.success],
      glowTint: AppColors.accent,
    ),
    'data-science': CategoryIconStyle(
      icon: Icons.insights_rounded,
      iconGradient: [AppColors.sky500, AppColors.violet500],
      glowTint: AppColors.sky500,
    ),
    'business': CategoryIconStyle(
      icon: Icons.business_center_rounded,
      iconGradient: [AppColors.amber, AppColors.success],
      glowTint: AppColors.amber,
    ),
  };

  static CategoryIconStyle forSlug(String slug) {
    return _bySlug[slug.toLowerCase()] ?? fallback;
  }
}
