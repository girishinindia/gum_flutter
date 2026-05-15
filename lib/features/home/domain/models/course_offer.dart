// Course-offer card data — populates the "Popular courses" horizontal
// carousel. Stays a plain Dart model so it can be swapped to a Supabase
// row mapping later without UI changes.

import 'package:flutter/material.dart';

class CourseOffer {
  final String title;
  final String level;          // "Beginner → Pro" / "Intermediate"
  final String duration;       // "6 months · 64 lessons"
  final List<Color> cover;     // 3-stop cover gradient
  final double rating;         // 0.0 – 5.0
  final int learners;          // e.g. 24000
  final int pricePaise;        // store in paise to avoid fp issues — display as ₹
  final int originalPricePaise;
  final double progress;       // 0.0 – 1.0  · 0 = not started; >0 → shows resume bar
  final List<Color> instructorAccents; // up to 3 stacked avatar colours
  final int extraInstructors;  // "+N" beyond the 3 shown
  final String? badge;         // "HOT", "NEW", "BESTSELLER" — null = no badge

  const CourseOffer({
    required this.title,
    required this.level,
    required this.duration,
    required this.cover,
    required this.rating,
    required this.learners,
    required this.pricePaise,
    required this.originalPricePaise,
    required this.progress,
    required this.instructorAccents,
    required this.extraInstructors,
    this.badge,
  });

  /// "₹29,999" formatted from paise.
  String get displayPrice         => _rupees(pricePaise);
  String get displayOriginalPrice => _rupees(originalPricePaise);

  /// Compact learner count, e.g. "24k+", "1.2k+".
  String get displayLearners {
    if (learners >= 1000) {
      final k = (learners / 1000).toStringAsFixed(learners >= 10000 ? 0 : 1);
      return '${k}k+';
    }
    return '$learners';
  }

  static String _rupees(int paise) {
    final rupees = paise ~/ 100;
    // 1,23,456 (Indian grouping)
    final s = rupees.toString();
    if (s.length <= 3) return '₹$s';
    final last3 = s.substring(s.length - 3);
    var rest    = s.substring(0, s.length - 3);
    final out = StringBuffer();
    while (rest.length > 2) {
      out.write(',');
      out.write(rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    out.write(',$last3');
    return '₹$rest${out.toString()}';
  }
}
