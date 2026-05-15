// LanguageSheet — modal bottom sheet that lists pickable languages
// and lets the user switch the active one. Mirrors the mobile-web
// `MobileLanguagePopup`.
//
// Open with `LanguageSheet.show(context)` from anywhere (today: the
// drawer "Language" row).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/catalog/domain/language.dart';
import '../../features/i18n/language_controller.dart';

class LanguageSheet {
  LanguageSheet._();

  /// Show the language picker. Returns when the sheet is dismissed.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LanguageSheetBody(),
    );
  }
}

class _LanguageSheetBody extends StatelessWidget {
  const _LanguageSheetBody();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final t    = lang.t;
    final media = MediaQuery.of(context);

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
                const Icon(Icons.language_rounded,
                    color: AppColors.sky500, size: 22),
                const SizedBox(width: 10),
                Text(t.language, style: AppTypography.h2),
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
            const SizedBox(height: 4),
            // Languages list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lang.languages.length,
                itemBuilder: (context, i) {
                  final l = lang.languages[i];
                  final isActive = l.isoCode.toLowerCase() ==
                      lang.iso.toLowerCase();
                  return _LanguageRow(
                    language: l,
                    isActive: isActive,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      await lang.setActive(l.isoCode);
                      if (context.mounted) Navigator.of(context).maybePop();
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

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.isActive,
    required this.onTap,
  });
  final Language language;
  final bool     isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brand50
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppColors.brand200
                        : AppColors.outlineSoft,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  language.isoCode.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: isActive
                        ? AppColors.brand700
                        : AppColors.slate700,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.label,
                      style: AppTypography.h3.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (language.nativeName != null &&
                        language.nativeName != language.name)
                      Text(
                        language.name,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.sky500, size: 20)
              else
                const Icon(Icons.radio_button_unchecked_rounded,
                    color: AppColors.slate300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
