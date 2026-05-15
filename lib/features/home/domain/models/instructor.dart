// Top-instructor card data — populates the horizontal instructor rail.
//
// Avatar is colour-only (no network image dep) so the home stays
// snappy on cold start; swap to NetworkImage when the profile photos
// land via /instructors API.

import 'package:flutter/material.dart';

class Instructor {
  final String       name;
  final String       initial;         // single letter for the colour avatar
  final String       specialty;       // "AI · ML · Deep Learning"
  final double       rating;          // 4.9
  final int          studentCount;    // 24_000
  final int          courseCount;     // 8
  final List<Color>  avatarGradient;  // 2-stop colour for the chip
  final bool         verified;

  const Instructor({
    required this.name,
    required this.initial,
    required this.specialty,
    required this.rating,
    required this.studentCount,
    required this.courseCount,
    required this.avatarGradient,
    this.verified = true,
  });

  /// "24k+ students" / "1.2k+ students" / "240 students".
  String get studentsLabel {
    if (studentCount >= 1000) {
      final k = (studentCount / 1000).toStringAsFixed(studentCount >= 10000 ? 0 : 1);
      return '${k}k+ students';
    }
    return '$studentCount students';
  }
}
