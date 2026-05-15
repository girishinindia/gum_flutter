// Responsive form-factor classification for the home (and any other
// screen that wants to participate in the same breakpoint system).
//
// Driven purely by `MediaQuery.of(context).size.width` — the same
// signal Material design uses for adaptive layouts. Anything that
// needs a value to change with screen size should reach for
// `AppBreakpoints.of(context)` and switch on the returned `FormFactor`,
// or use the `R<T>` helper in `responsive_value.dart`.
//
// Bands:
//   phoneSmall       < 360   — older Android, narrow viewports
//   phoneNormal      360–599 — default modern phones
//   tabletPortrait   600–899 — iPad portrait, Android tablets portrait
//   tabletLandscape  ≥ 900   — tablets horizontal, foldables open

import 'package:flutter/widgets.dart';

enum FormFactor {
  phoneSmall,
  phoneNormal,
  tabletPortrait,
  tabletLandscape,
}

class AppBreakpoints {
  AppBreakpoints._();

  // ── Width thresholds (logical px) ──────────────────────────────────
  /// Below this, treat as a cramped phone (tighter gutters, smaller cards).
  static const double small  = 360;

  /// At this width or above, treat as tablet.
  static const double tablet = 600;

  /// Tablet-landscape — at this width the layout opens up further.
  static const double wide   = 900;

  // ── Max content-width clamps (so tablet layouts don't stretch) ─────
  /// Max body width in tablet-portrait band.
  static const double clampNormal = 720;

  /// Max body width in tablet-landscape band.
  static const double clampWide   = 960;

  /// Resolve the current FormFactor from the BuildContext.
  static FormFactor of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < small)  return FormFactor.phoneSmall;
    if (w < tablet) return FormFactor.phoneNormal;
    if (w < wide)   return FormFactor.tabletPortrait;
    return FormFactor.tabletLandscape;
  }

  /// True when running on a tablet form factor (portrait or landscape).
  static bool isTablet(BuildContext context) {
    final f = of(context);
    return f == FormFactor.tabletPortrait || f == FormFactor.tabletLandscape;
  }

  /// True when running on a phone form factor.
  static bool isPhone(BuildContext context) => !isTablet(context);
}
