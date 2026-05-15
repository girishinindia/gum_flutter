// PageConstraint — clamps the body's max width on tablet form factors
// so the home doesn't stretch to 1100+ logical px on iPad-landscape
// and end up looking like an ill-fitting suit.
//
// On phones, this is a no-op (it just returns the child unchanged).
// On tablet-portrait it clamps to 720 px; on tablet-landscape to 960.
// The clamped child is centred horizontally inside the available
// space — the page background still paints edge-to-edge, only the
// foreground content respects the clamp.

import 'package:flutter/widgets.dart';
import '../../core/responsive/app_breakpoints.dart';

class PageConstraint extends StatelessWidget {
  const PageConstraint({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final factor = AppBreakpoints.of(context);
    final maxWidth = switch (factor) {
      FormFactor.tabletPortrait  => AppBreakpoints.clampNormal, // 720
      FormFactor.tabletLandscape => AppBreakpoints.clampWide,   // 960
      _                          => double.infinity,            // phones — no clamp
    };

    if (maxWidth == double.infinity) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
