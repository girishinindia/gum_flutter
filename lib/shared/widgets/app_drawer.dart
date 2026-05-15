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

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../features/home/domain/models/menu_action.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.initial,
    required this.items,
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
  final ValueChanged<MenuAction>? onItemTap;
  final VoidCallback? onSignOut;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
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
              _SignInCta(onSignIn: onSignIn),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                itemCount: items.length,
                itemBuilder: (context, i) {
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
            const Divider(height: 1, color: AppColors.outline),
            if (isLoggedIn) _SignOutButton(onTap: onSignOut),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: AppColors.auroraGradient,
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
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? 'View profile',
                      style: AppTypography.captionOnGradient.copyWith(
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.rPill,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.32),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$streakDays-day streak',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
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
                  color: action.iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, color: action.iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: AppTypography.h3.copyWith(fontSize: 14),
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
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.slate400, size: 18),
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
  const _SignOutButton({this.onTap});
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
                'Sign out',
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
// Signed-out CTA — replaces the user header when isLoggedIn = false
// ─────────────────────────────────────────────────────────────────────

class _SignInCta extends StatelessWidget {
  const _SignInCta({this.onSignIn});
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: AppColors.auroraGradient,
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
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                    width: 1.2,
                  ),
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Grow Up More',
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sign in to track your progress',
                      style: AppTypography.captionOnGradient.copyWith(
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
                      const Icon(Icons.login_rounded,
                          size: 16, color: AppColors.accent600),
                      const SizedBox(width: 6),
                      Text(
                        'Sign in',
                        style: AppTypography.buttonLabel.copyWith(
                          color: AppColors.accent600,
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
