// App entrypoint.
//
// Wires AppTheme into MaterialApp.router, applies the system-chrome
// recipe so the status bar matches the aurora gradient on first paint,
// and routes via go_router driven by AuthBloc state.
//
// State plumbing:
//   • Provider (legacy, still in use for catalog plumbing):
//       LanguageController   — loads /languages, persists pref, exposes `t`
//       ThemeController      — loads the persisted palette
//       CategoriesController — loads /sub-categories baseline, applies
//                              per-language overlay, exposes `displayed`
//   • BLoC (new — drives auth + profile, enterprise-grade):
//       AuthBloc   — owns AuthState (unknown / unauthenticated /
//                    authenticated). go_router redirects on its stream.
//
// Cold start order:
//   1. Construct legacy controllers (catalog still needs them).
//   2. Construct AuthRepository + AuthBloc.
//   3. Build the GoRouter against the bloc's stream.
//   4. runApp.
//   5. Kick `AuthAppStarted` (hydrates secure storage + refreshes
//      /users/me) in parallel with the legacy `.load()` calls.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/catalog/categories_controller.dart';
import 'features/i18n/language_controller.dart';
import 'features/theming/bottom_nav_style_controller.dart';
import 'features/theming/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiLight);

  // ── Legacy (Provider) controllers ─────────────────────────────────
  final languageController   = LanguageController();
  final themeController      = ThemeController();
  // Phase 43.15 — picks between CurvedBottomNav (default) and the new
  // FlatPillBottomNav. Persisted to SharedPreferences so the choice
  // survives app restarts.
  final bottomNavStyleController = BottomNavStyleController();
  final categoriesController = CategoriesController(
    languageController: languageController,
  );

  // ── BLoC (new) — auth ─────────────────────────────────────────────
  final authRepository = AuthRepository();
  final authBloc       = AuthBloc(repository: authRepository);

  // ── Router driven by AuthBloc state ───────────────────────────────
  final router = buildAppRouter(authBloc);

  runApp(GrowUpMoreApp(
    languageController:        languageController,
    themeController:           themeController,
    bottomNavStyleController:  bottomNavStyleController,
    categoriesController:      categoriesController,
    authBloc:                  authBloc,
    router:                    router,
  ));

  // Fire-and-forget loads after the first frame is on screen. The UI
  // listens via Consumer / BlocBuilder and rebuilds when data lands.
  //   1) Theme  — resolves the persisted palette
  //   2) Auth   — hydrates cached user + refreshes /users/me
  //   3) Lang   — languages list + persisted active iso
  //   4) Cats   — categories English baseline (then overlay)
  // ignore: unawaited_futures
  () async {
    await themeController.load();
    await bottomNavStyleController.load();
    authBloc.add(const AuthAppStarted());      // non-blocking; bloc handles async
    await languageController.load();
    await categoriesController.load();
  }();
}

class GrowUpMoreApp extends StatelessWidget {
  const GrowUpMoreApp({
    super.key,
    required this.languageController,
    required this.themeController,
    required this.bottomNavStyleController,
    required this.categoriesController,
    required this.authBloc,
    required this.router,
  });

  final LanguageController         languageController;
  final ThemeController            themeController;
  final BottomNavStyleController   bottomNavStyleController;
  final CategoriesController       categoriesController;
  final AuthBloc                   authBloc;
  final GoRouter                   router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageController>.value(value: languageController),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<BottomNavStyleController>.value(value: bottomNavStyleController),
        ChangeNotifierProvider<CategoriesController>.value(value: categoriesController),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp.router(
          title: 'Grow Up More',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }
}
