// App entrypoint.
//
// Wires AppTheme into MaterialApp, applies the system-chrome recipe so
// the status bar matches the aurora gradient on first paint, and boots
// straight into the splash screen which then routes to home.
//
// State plumbing (mirrors gum_web's React Context tree):
//   LanguageController  — loads /languages, persists pref, exposes `t`
//   CategoriesController — loads /sub-categories baseline, applies
//                          per-language overlay, exposes `displayed`
// Both controllers are constructed in a MultiProvider at the root so
// the entire widget tree can `context.watch<T>()` / `context.read<T>()`.
// Their `.load()` methods are kicked off after `runApp` so the UI
// renders immediately (the home shows shimmer / English fallback until
// the API responds).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/catalog/categories_controller.dart';
import 'features/i18n/language_controller.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/theming/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock the app to portrait orientation only. The home is designed
  // for vertical scrolling and the carousels / sticky app bar don't
  // need landscape — locking here is cleaner than handling rotation.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiLight);

  // Build the controllers up-front so we can pass LanguageController
  // into CategoriesController (which listens to it). They start in
  // their default state and `.load()` fills them in below.
  final languageController   = LanguageController();
  final themeController      = ThemeController();
  final categoriesController = CategoriesController(
    languageController: languageController,
  );

  runApp(GrowUpMoreApp(
    languageController:   languageController,
    themeController:      themeController,
    categoriesController: categoriesController,
  ));

  // Fire-and-forget loads after the first frame is on screen. The UI
  // listens via Consumer/context.watch and rebuilds when the data lands.
  //   1) Theme — resolves the persisted palette so the first repaint
  //      already wears the right gradient (no Aurora → user-choice flash).
  //   2) Languages list + persisted active iso
  //   3) Categories English baseline (then overlay if active != en)
  // ignore: unawaited_futures
  () async {
    await themeController.load();
    await languageController.load();
    await categoriesController.load();
  }();
}

class GrowUpMoreApp extends StatelessWidget {
  const GrowUpMoreApp({
    super.key,
    required this.languageController,
    required this.themeController,
    required this.categoriesController,
  });

  final LanguageController   languageController;
  final ThemeController      themeController;
  final CategoriesController categoriesController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // LanguageController is the source of truth for what locale we
        // render. `value` (not `create`) because we already built it
        // in main() to wire CategoriesController against it.
        ChangeNotifierProvider<LanguageController>.value(
          value: languageController,
        ),
        // ThemeController owns the active AppPalette. Drives every
        // visible gradient (hero, nav, page bg, featured card, FAB).
        ChangeNotifierProvider<ThemeController>.value(
          value: themeController,
        ),
        // CategoriesController reacts to LanguageController changes.
        ChangeNotifierProvider<CategoriesController>.value(
          value: categoriesController,
        ),
      ],
      child: MaterialApp(
        title: 'Grow Up More',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
