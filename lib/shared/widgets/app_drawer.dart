// Premium end-drawer.
//
// Aurora-gradient header with the user's avatar, name + email and a
// quick "Learning streak" pill, followed by a clean list of MenuAction
// rows from the home repository. Badged rows render a small coloured
// chip on the right (e.g. Cart · 2, Notifications · 4).
//
// Footer holds "Sign out" — destructive action visually separated so
// it can't be mistaken for a regular menu row.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../features/home/domain/models/menu_action.dart';
import '../../features/i18n/language_controller.dart';
import '../../features/i18n/messages.dart';
import '../../features/theming/theme_controller.dart';
import 'language_sheet.dart';
import 'theme_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.initial,
    required this.items,
    required this.t,
    this.isLoggedIn = true,
    this.email,
    this.streakDays = 7,
    this.onItemTap,
    this.onSignOut,
    this.onSignIn,
  });

  final bool        isLoggedIn;
  final String      firstName;
  final String      lastName;
  final String      initial;
  final String?     email;
  final int         streakDays;
  final List<MenuAction> items;
  /// Translated UI strings. Used for the welcome card, sign-in/out CTAs,
  /// and the "Language" row label below the regular menu.
  final Messages    t;
  final ValueChanged<MenuAction>? onItemTap;
  final VoidCallback? onSignOut;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    // Drawer chrome (body bg, dividers, row text + chevrons) all pull
    // from the active palette so dark themes paint the entire drawer
    // dark instead of leaving a white panel against the dark hero.
    // Aurora + every other light theme set chromeSurface = white, so
    // the existing look is preserved.
    final palette = context.watch<ThemeController>().palette;

    return Drawer(
      backgroundColor: palette.chromeSurface,
      elevation: 12,
      width: 312,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft:    Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Logged-in → user card; otherwise → "Sign in" CTA card.
            if (isLoggedIn)
              _DrawerHeader(
                firstName:  firstName,
                lastName:   lastName,
                initial:    initial,
                email:      email,
                streakDays: streakDays,
              )
            else
              _SignInCta(
                t: t,
                onSignIn: onSignIn,
              ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                // +2 for the Language + Theme rows appended at the end.
                // Language sits first (locale is more "global"), Theme
                // sits second (visual personalisation).
                itemCount: items.length + 2,
                itemBuilder: (context, i) {
                  if (i == items.length)     return _LanguageRow(t: t);
                  if (i == items.length + 1) return _ThemeRow(t: t);
                  final m = items[i];
                  return _DrawerRow(
                    action: m,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                      onItemTap?.call(m);
                    },
                  );
                },
              ),
            ),
            Divider(height: 1, color: palette.chromeOutline),
            if (isLoggedIn)
              _SignOutButton(label: t.signOut, onTap: onSignOut),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.firstName,
    required this.lastName,
    required this.initial,
    required this.streakDays,
    this.email,
  });

  final String  firstName;
  final String  lastName;
  final String  initial;
  final int     streakDays;
  final String? email;

  @override
  Widget build(BuildContext context) {
    // Pull from active theme so the drawer header retints with the rest
    // of the chrome (matches the hero gradient on the home behind it).
    final palette = context.watch<ThemeController>().palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: AppRadius.rXl,
        boxShadow: AppRadius.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.amber, AppColors.rose],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTypography.h2.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: AppTypography.h2.copyWith(
                        color: palette.onHero,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? 'View profile',
                      style: AppTypography.captionOnGradient.copyWith(
                        color: palette.onHeroMuted,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.heroSurface,
              borderRadius: AppRadius.rPill,
              border: Border.all(
                color: palette.heroSurfaceBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: palette.onHero, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$streakDays-day streak',
                  style: AppTypography.caption.copyWith(
                    color: palette.onHero,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Drawer row
// ─────────────────────────────────────────────────────────────────────

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({required this.action, required this.onTap});

  final MenuAction   action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Row labels + chevron flip to near-white on dark chrome. The
    // per-category icon colours (sky, accent, rose, etc.) stay as-is —
    // they're visual category identifiers and read well on both
    // light and dark surfaces.
    final palette = context.watch<ThemeController>().palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  // Slightly stronger tint on dark themes so the icon
                  // chip still reads as a distinct surface.
                  color: action.iconColor.withValues(
                    alpha: palette.isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: AppTypography.h3.copyWith(
                    fontSize: 14,
                    color: palette.onChrome,
                  ),
                ),
              ),
              if (action.badgeCount != null && action.badgeCount! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: action.iconColor,
                    borderRadius: AppRadius.rPill,
                    boxShadow: [
                      BoxShadow(
                        color: action.iconColor.withValues(alpha: 0.40),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Text(
                    '${action.badgeCount}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: palette.onChromeMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sign-out footer
// ─────────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.label, this.onTap});
  final String        label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded,
                  color: AppColors.rose, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTypography.h3.copyWith(
                  color: AppColors.rose,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Language row — opens the LanguageSheet on tap. Lives at the bottom
// of the drawer list so it's reachable in both signed-in and
// signed-out states without crowding the user actions above.
// ─────────────────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.t});
  final Messages t;

  @override
  Widget build(BuildContext context) {
    // Watch so the trailing "(native name)" updates immediately when the
    // user picks a new language inside the sheet.
    final lang     = context.watch<LanguageController>();
    final palette  = context.watch<ThemeController>().palette;
    final trailing = lang.active.label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: () {
          HapticFeedback.selectionClick();
          // Close the drawer first so the sheet animates over the home,
          // not the drawer (matches the rest of the menu actions).
          Navigator.pop(context);
          LanguageSheet.show(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.sky500.withValues(
                    alpha: palette.isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.language_rounded,
                    color: AppColors.sky500, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.language,
                  style: AppTypography.h3.copyWith(
                    fontSize: 14,
                    color: palette.onChrome,
                  ),
                ),
              ),
              Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: palette.onChromeMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: palette.onChromeMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Theme row — opens ThemeSheet on tap. Same shape as `_LanguageRow`,
// trailing slot shows a live gradient swatch + active theme name so
// the user can confirm what's applied without opening the picker.
// ─────────────────────────────────────────────────────────────────────

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.t});
  final Messages t;

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final palette   = themeCtrl.palette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.pop(context);
          ThemeSheet.show(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // Themed icon chip — wears the active palette so the row
              // itself doubles as a preview.
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: palette.primary500.withValues(
                    alpha: palette.isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_rounded,
                    color: palette.primary500, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t.theme,
                  style: AppTypography.h3.copyWith(
                    fontSize: 14,
                    color: palette.onChrome,
                  ),
                ),
              ),
              // Mini gradient swatch — 16×16 disc with a soft outline.
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  gradient: palette.heroGradient,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary500.withValues(alpha: 0.30),
                      blurRadius: 6,
                      spreadRadius: -2,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                palette.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: palette.onChromeMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: palette.onChromeMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Signed-out CTA — replaces the user header when isLoggedIn = false
// ─────────────────────────────────────────────────────────────────────

class _SignInCta extends StatelessWidget {
  const _SignInCta({required this.t, this.onSignIn});
  final Messages      t;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeController>().palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: AppRadius.rXl,
        boxShadow: AppRadius.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: palette.heroSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.heroSurfaceBorder,
                    width: 1.2,
                  ),
                ),
                child: Icon(Icons.person_rounded,
                    color: palette.onHero, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.welcome,
                      style: AppTypography.h2.copyWith(
                        color: palette.onHero,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.trackProgress,
                      style: AppTypography.captionOnGradient.copyWith(
                        color: palette.onHeroMuted,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white,
              borderRadius: AppRadius.rPill,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  onSignIn?.call();
                },
                borderRadius: AppRadius.rPill,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded,
                          size: 16, color: palette.primary700),
                      const SizedBox(width: 6),
                      Text(
                        t.signIn,
                        style: AppTypography.buttonLabel.copyWith(
                          color: palette.primary700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
