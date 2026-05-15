// Student-review card data.
//
// Keeps `comment` short (under ~140 chars) because the review card is
// fixed-height and uses ellipsis on overflow. For longer reviews,
// click-through to the full review page.

import 'package:flutter/material.dart';

class Review {
  final String studentName;
  final String studentInitial;
  final String courseName;
  final double rating;        // 0.0 – 5.0
  final String comment;
  final Color  avatarColor;

  const Review({
    required this.studentName,
    required this.studentInitial,
    required this.courseName,
    required this.rating,
    required this.comment,
    required this.avatarColor,
  });
}
