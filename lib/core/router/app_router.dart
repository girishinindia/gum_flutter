// Declarative routes + auth-gate redirect.
//
// Public:
//   /             splash (held until AuthBloc finishes bootstrap)
//   /login        login form
//   /register     register form
//   /register/verify  dual register OTP
//   /forgot       forgot password
//   /forgot/verify    dual reset OTP
//   /forgot/reset     new password
//
// Authed:
//   /home         existing home shell
//   /profile      profile home (section list)
//   /profile/<s>  per-section screens (basic / contact / … / security)
//
// The whole /profile tree lives under a ShellRoute that provides a
// single ProfileBloc + ProfileRepository instance — so navigating
// between sections doesn't re-fetch the bundle on every push.
//
// `refreshListenable` rebuilds the auth redirect when AuthBloc emits.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_otp_screen.dart';
import '../../features/auth/presentation/register_pending_state.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_otp_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/reset_pending_state.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/bloc/profile_bloc.dart';
import '../../features/profile/data/profile_repository.dart';
import '../../features/profile/presentation/profile_home_screen.dart';
import '../../features/profile/presentation/profile_section_meta.dart';
import '../../features/profile/presentation/sections/address_section.dart';
import '../../features/profile/presentation/sections/badges_section.dart';
import '../../features/profile/presentation/sections/basic_info_section.dart';
import '../../features/profile/presentation/sections/contact_section.dart';
import '../../features/profile/presentation/sections/documents_section.dart';
import '../../features/profile/presentation/sections/education_section.dart';
import '../../features/profile/presentation/sections/experience_section.dart';
import '../../features/profile/presentation/sections/instructor_bio_section.dart';
import '../../features/profile/presentation/sections/kyc_bank_section.dart';
import '../../features/profile/presentation/sections/languages_section.dart';
import '../../features/profile/presentation/sections/projects_section.dart';
import '../../features/profile/presentation/sections/security_section.dart';
import '../../features/profile/presentation/sections/skills_section.dart';
import '../../features/profile/presentation/sections/social_links_section.dart';
// NOTE: `section_placeholder.dart` is intentionally not imported now
// that all 14 sections ship. The file is left in the tree so that any
// future deferred-section work can re-import it without scaffolding.
import '../../features/splash/presentation/splash_screen.dart';

/// Public (unauthenticated-allowed) route locations.
const _publicLocations = {
  '/',
  '/login',
  '/register',
  '/register/verify',
  '/forgot',
  '/forgot/verify',
  '/forgot/reset',
};

GoRouter buildAppRouter(AuthBloc bloc) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _BlocChangeListenable(bloc.stream),
    redirect: (ctx, st) {
      final state = bloc.state;
      final going = st.matchedLocation;

      // Bootstrap not done yet — keep showing splash.
      if (state.status == AuthStatus.unknown) {
        return going == '/' ? null : '/';
      }

      final isPublic = _publicLocations.contains(going);

      if (state.status == AuthStatus.unauthenticated) {
        if (going == '/') return '/login';
        return isPublic ? null : '/login';
      }

      // Authenticated.
      if (isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/',         builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            builder: (ctx, st) {
              final extra = st.extra;
              if (extra is! RegisterPendingState) {
                WidgetsBinding.instance.addPostFrameCallback((_) => ctx.go('/register'));
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return RegisterOtpScreen(pending: extra);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            builder: (ctx, st) {
              final extra = st.extra;
              if (extra is! ResetPendingState) {
                WidgetsBinding.instance.addPostFrameCallback((_) => ctx.go('/forgot'));
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return ResetOtpScreen(pending: extra);
            },
          ),
          GoRoute(
            path: 'reset',
            builder: (ctx, st) {
              final extra = st.extra;
              if (extra is! ResetPendingState) {
                WidgetsBinding.instance.addPostFrameCallback((_) => ctx.go('/forgot'));
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return ResetPasswordScreen(pending: extra);
            },
          ),
        ],
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

      // ── Profile tree ───────────────────────────────────────────
      // ShellRoute provides a single ProfileBloc + ProfileRepository
      // instance scoped to /profile/*, so section pushes don't re-
      // fetch the bundle. The bloc is constructed lazily on first
      // access using the current isInstructor flag from AuthBloc.
      ShellRoute(
        builder: (ctx, st, child) {
          return BlocProvider<ProfileBloc>(
            create: (innerCtx) {
              final isInstructor = innerCtx.read<AuthBloc>().state.user?.isInstructor ?? false;
              return ProfileBloc(
                repository:   ProfileRepository(),
                isInstructor: isInstructor,
              );
            },
            child: child,
          );
        },
        routes: _profileRoutes(),
      ),
    ],
  );
}

List<GoRoute> _profileRoutes() {
  // All 14 sections are fully shipped (Phases D + E + F + G).
  Widget builderFor(ProfileSection s) {
    switch (s.kind) {
      case ProfileSectionKind.basic:         return const BasicInfoSection();
      case ProfileSectionKind.contact:       return const ContactSection();
      case ProfileSectionKind.address:       return const AddressSection();
      case ProfileSectionKind.education:     return const EducationSection();
      case ProfileSectionKind.experience:    return const ExperienceSection();
      case ProfileSectionKind.projects:      return const ProjectsSection();
      case ProfileSectionKind.skills:        return const SkillsSection();
      case ProfileSectionKind.languages:     return const LanguagesSection();
      case ProfileSectionKind.social:        return const SocialLinksSection();
      case ProfileSectionKind.documents:     return const DocumentsSection();
      case ProfileSectionKind.badges:        return const BadgesSection();
      case ProfileSectionKind.instructorBio: return const InstructorBioSection();
      case ProfileSectionKind.kycBank:       return const KycBankSection();
      case ProfileSectionKind.security:      return const SecuritySection();
    }
  }

  return [
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileHomeScreen(),
      routes: [
        for (final s in profileSections)
          GoRoute(
            path: s.path,
            builder: (_, __) => builderFor(s),
          ),
      ],
    ),
  ];
}

/// Bridge: turn a `Stream<AuthState>` into a `Listenable` that go_router
/// can call `addListener` on.
class _BlocChangeListenable extends ChangeNotifier {
  _BlocChangeListenable(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
