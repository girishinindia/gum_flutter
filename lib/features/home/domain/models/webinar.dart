// Upcoming-webinar card data.
//
// `startsAt` is what the UI uses to compute the date/time chip; the
// `isLive` flag short-circuits that and lights the red "LIVE" badge
// instead — useful for rooms already streaming.

import 'package:flutter/material.dart';

class Webinar {
  final String       title;
  final String       instructor;
  final String       instructorInitial;
  final DateTime     startsAt;
  final int          durationMinutes;
  final List<Color>  cover;            // 2-stop card cover gradient
  final Color        accent;           // dot / chip tint
  final bool         isLive;
  final int          registeredCount;

  const Webinar({
    required this.title,
    required this.instructor,
    required this.instructorInitial,
    required this.startsAt,
    required this.durationMinutes,
    required this.cover,
    required this.accent,
    this.isLive          = false,
    this.registeredCount = 0,
  });

  /// "Tomorrow · 7:30 PM"  /  "LIVE NOW"  /  "Sat 24 May · 6 PM"
  String get whenLabel {
    if (isLive) return 'LIVE NOW';
    final now    = DateTime.now();
    final today  = DateTime(now.year, now.month, now.day);
    final target = DateTime(startsAt.year, startsAt.month, startsAt.day);
    final days   = target.difference(today).inDays;

    final h12   = startsAt.hour == 0 ? 12 : (startsAt.hour > 12 ? startsAt.hour - 12 : startsAt.hour);
    final ampm  = startsAt.hour >= 12 ? 'PM' : 'AM';
    final mins  = startsAt.minute == 0 ? '' : ':${startsAt.minute.toString().padLeft(2, '0')}';
    final time  = '$h12$mins $ampm';

    if (days == 0) return 'Today · $time';
    if (days == 1) return 'Tomorrow · $time';
    if (days < 7)  return '${_weekday(startsAt.weekday)} · $time';
    return '${_weekday(startsAt.weekday)} ${startsAt.day} ${_month(startsAt.month)} · $time';
  }

  /// Compact registered-count: "1.2k registered" / "240 registered".
  String get registeredLabel {
    if (registeredCount >= 1000) {
      final k = (registeredCount / 1000).toStringAsFixed(registeredCount >= 10000 ? 0 : 1);
      return '${k}k registered';
    }
    return '$registeredCount registered';
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months   = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  static String _weekday(int n) => _weekdays[n - 1];
  static String _month(int n)   => _months[n - 1];
}
