// ThemeSheet — modal bottom sheet for picking the home colour scheme.
//
// UX mirrors LanguageSheet: header row (icon + title + close), divider,
// then a grid of swatch tiles. Active tile gets a coloured border and
// a white check-mark badge. Tap to switch; the sheet dismisses
// automatically after `setActive` so the user sees the new theme
// land on the home immediately.
//
// Open with `ThemeSheet.show(context)` from anywhere (today: the
// drawer "Theme" row).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/i18n/language_controller.dart';
import '../../features/theming/domain/app_palette.dart';
import '../../features/theming/theme_controller.dart';

class ThemeSheet {
  ThemeSheet._();

  /// Show the theme picker. Returns when the sheet is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ThemeSheetBody(),
    );
  }
}

class _ThemeSheetBody extends StatelessWidget {
  const _ThemeSheetBody();

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final lang      = context.watch<LanguageController>();
    final t         = lang.t;
    final media     = MediaQuery.of(context);

    // 2 columns on phones, 4 on tablet portrait+, matches the
    // language picker's tablet-aware sizing pattern.
    final cols = AppBreakpoints.isTablet(context) ? 4 : 2;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left:   AppSpacing.pageGutter,
          right:  AppSpacing.pageGutter,
          top:    14,
          bottom: media.viewPadding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 38, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Title row
            Row(
              children: [
                Icon(Icons.palette_rounded,
                    color: themeCtrl.palette.primary500, size: 22),
                const SizedBox(width: 10),
                Text(t.chooseTheme, style: AppTypography.h2),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.slate500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.outline),
            const SizedBox(height: 12),
            // Swatch grid
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: themeCtrl.themes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:  cols,
                  mainAxisSpacing:  12,
                  crossAxisSpacing: 12,
                  // 1.6 makes each tile taller than wide enough to fit
                  // a 64px gradient strip + name + tagline without
                  // overflowing on small phones.
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, i) {
                  final p = themeCtrl.themes[i];
                  final isActive = p.id == themeCtrl.activeId;
                  return _SwatchTile(
                    palette:  p,
                    isActive: isActive,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await themeCtrl.setActive(p.id);
                      if (context.mounted) {
                        Navigator.of(context).maybePop();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({
    required this.palette,
    required this.isActive,
    required this.onTap,
  });

  final AppPalette   palette;
  final bool         isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: isActive ? palette.primary500 : AppColors.outline,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: palette.primary500.withValues(alpha: 0.18),
                      blurRadius: 12,
                      spreadRadius: -4,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient preview strip with check badge ──────────
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: palette.heroGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (isActive)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.check_rounded,
                              size: 14, color: palette.primary500),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ── Name + tagline (cramped on phone → tight sizes) ──
              Text(
                palette.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                palette.tagline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontSize: 10.5,
                  color: AppColors.slate500,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
