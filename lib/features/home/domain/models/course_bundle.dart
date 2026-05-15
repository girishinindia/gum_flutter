// Course-bundle card data — a curated set of courses sold together
// at a discount (e.g. "Full-Stack Mastery — 5 courses · 40% off").

import 'package:flutter/material.dart';

class CourseBundle {
  final String       name;             // "Full-Stack Mastery"
  final String       subtitle;         // "Frontend → Backend → Deploy"
  final int          courseCount;      // 5
  final List<Color>  cover;            // 3-stop card cover gradient
  final int          totalPricePaise;  // sum of MRP of all courses, paise
  final int          bundlePricePaise; // discounted bundle price, paise
  final String       savingsLabel;     // "Save 40%"
  final IconData     icon;             // big glyph on the card

  const CourseBundle({
    required this.name,
    required this.subtitle,
    required this.courseCount,
    required this.cover,
    required this.totalPricePaise,
    required this.bundlePricePaise,
    required this.savingsLabel,
    required this.icon,
  });

  String get displayBundlePrice => _rupees(bundlePricePaise);
  String get displayTotalPrice  => _rupees(totalPricePaise);

  /// Discount % derived from the two prices — single source of truth.
  int get discountPercent {
    if (totalPricePaise <= 0) return 0;
    final pct = ((totalPricePaise - bundlePricePaise) * 100) / totalPricePaise;
    return pct.round();
  }

  static String _rupees(int paise) {
    final rupees = paise ~/ 100;
    final s = rupees.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    var rest    = s.substring(0, s.length - 3);
    final out   = StringBuffer();
    while (rest.length > 2) {
      out.write(',');
      out.write(rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    out.write(',$last3');
    return '₹$rest${out.toString()}';
  }
}
