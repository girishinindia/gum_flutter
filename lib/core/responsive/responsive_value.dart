// `R<T>` — pick a value per breakpoint with sensible fallbacks.
//
// Usage:
//
//   final h = const R<double>(
//     normal:  208,   // phone-normal (the default fallback)
//     small:   208,   // phone-small  (falls back to normal if omitted)
//     tabletP: 220,   // tablet-portrait (falls back to normal)
//     tabletL: 220,   // tablet-landscape (falls back to tabletP)
//   ).resolve(context);
//
//   SizedBox(height: h, child: ...)
//
// Only `normal` is required. Every other slot falls back gracefully,
// so a callsite that only cares about one breakpoint stays terse.

import 'package:flutter/widgets.dart';
import 'app_breakpoints.dart';

@immutable
class R<T> {
  /// Phone-normal value — the required base. Every other slot falls
  /// back to this if omitted.
  final T normal;

  final T small;     // phone-small  — falls back to `normal`
  final T tabletP;   // tablet-portrait — falls back to `normal`
  final T tabletL;   // tablet-landscape — falls back to `tabletP` then `normal`

  /// All-args const constructor (used internally). Prefer the named
  /// factory `R(...)` below which handles the fallback chain.
  const R._({
    required this.normal,
    required this.small,
    required this.tabletP,
    required this.tabletL,
  });

  /// Public factory with named fallbacks.
  ///
  ///   R(normal: 16)              → all four bands = 16
  ///   R(normal: 16, small: 12)   → small = 12, rest = 16
  ///   R(normal: 16, tabletP: 24) → phone-normal = 16, tablet-portrait/landscape = 24
  factory R({
    required T normal,
    T? small,
    T? tabletP,
    T? tabletL,
  }) {
    final tp = tabletP ?? normal;
    return R<T>._(
      normal:  normal,
      small:   small  ?? normal,
      tabletP: tp,
      tabletL: tabletL ?? tp,
    );
  }

  /// Resolve to the active value for the current FormFactor.
  T resolve(BuildContext context) {
    switch (AppBreakpoints.of(context)) {
      case FormFactor.phoneSmall:      return small;
      case FormFactor.phoneNormal:     return normal;
      case FormFactor.tabletPortrait:  return tabletP;
      case FormFactor.tabletLandscape: return tabletL;
    }
  }
}
