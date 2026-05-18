// Premium Aurora home — entire screen composition.
//
// Slivers (in order):
//   1. BrandSliverAppBar   — sticky white app bar (logo + drawer)
//   2. HeroBody            — aurora panel (search + optional stats)
//   3. CategoriesGrid      — 4-column tile grid
//   4. FeaturedCard + OffersCarousel — pulled together with one
//      Transform.translate so they sit tight under the categories.
//
// Auth state now comes from the AuthBloc — the home is only mounted
// when AuthStatus.authenticated, so we read the user via
// `context.watch<AuthBloc>().state.user` and treat its presence as
// the source of truth. When `user == null` (we reached the home in
// some edge case before the redirect lands), we degrade gracefully:
//   • the stats row in the hero is hidden
//   • the drawer shows a "Sign in" CTA instead of the user header

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/bloc/auth_state.dart';
import '../../../features/catalog/categories_controller.dart';
import '../../../features/i18n/language_controller.dart';
import '../../../features/theming/bottom_nav_style_controller.dart';
import '../../../features/theming/theme_controller.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/curved_bottom_nav.dart';
import '../../../shared/widgets/flat_pill_bottom_nav.dart';
import '../../../shared/widgets/lifted_card_bottom_nav.dart';
import '../../../shared/widgets/notched_active_bottom_nav.dart';
import '../../../shared/widgets/page_constraint.dart';
import '../data/home_repository.dart';
import 'widgets/bundles_section.dart';
import 'widgets/categories_grid.dart';
import 'widgets/featured_card.dart';
import 'widgets/hero_header.dart';
import 'widgets/instructors_section.dart';
import 'widgets/offers_carousel.dart';
import 'widgets/reviews_section.dart';
import 'widgets/webinars_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _repo = HomeRepository();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _navIndex = 0;

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final size       = MediaQuery.of(context).size;
    // i18n + API + theme state — watch so language/theme flips rebuild
    // the whole tree (cheap because most descendants are const subtrees).
    final lang       = context.watch<LanguageController>();
    final cats       = context.watch<CategoriesController>();
    final themeCtrl  = context.watch<ThemeController>();
    final palette    = themeCtrl.palette;
    final t          = lang.t;
    final courses    = _repo.popularCourses();
    final menu       = _repo.drawerMenu(t);

    // Real auth state, sourced from the bloc. Drawer/hero gating below
    // checks `isLoggedIn` exclusively against this.
    final authState  = context.watch<AuthBloc>().state;
    final authUser   = authState.user;
    final isLoggedIn = authState.status == AuthStatus.authenticated && authUser != null;
    final firstName  = authUser?.firstName ?? _repo.userFirstName;
    final lastName   = authUser?.lastName  ?? _repo.userLastName;
    final initial    = (firstName.isNotEmpty ? firstName[0] : _repo.userInitial).toUpperCase();
    final email      = authUser?.email ?? '';

    // Bottom-nav items — labels come from `t` so they translate too.
    final navItems = <CurvedNavItem>[
      CurvedNavItem(icon: Icons.home_rounded,      label: t.navHome),
      CurvedNavItem(icon: Icons.menu_book_rounded, label: t.navLearn),
      CurvedNavItem(icon: Icons.bookmark_rounded,  label: t.navSaved, badge: true),
      CurvedNavItem(icon: Icons.person_rounded,    label: t.navProfile),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        extendBody: true,
        endDrawer: AppDrawer(
          isLoggedIn: isLoggedIn,
          firstName:  firstName,
          lastName:   lastName,
          initial:    initial,
          email:      email.isNotEmpty ? email : 'manshi.khunt@gmail.com',
          streakDays: 7,
          items: menu,
          t:     t,
          onItemTap: (m) {
            // The Profile entry is identified by its icon (label is
            // localised so matching on string would break under i18n).
            if (m.icon == Icons.person_rounded) {
              _scaffoldKey.currentState?.closeEndDrawer();
              context.push('/profile');
            }
          },
          onSignOut:  () {
            // AuthBloc handles repo.logout + emits unauthenticated;
            // go_router's redirect bounces us to /login.
            context.read<AuthBloc>().add(const AuthLoggedOut());
          },
          onSignIn: () {
            // Close the end-drawer first, then deep-link to /login. A
            // Drawer isn't on the Navigator stack, so it has to be
            // closed via the Scaffold state explicitly.
            _scaffoldKey.currentState?.closeEndDrawer();
            context.push('/login');
          },
        ),
        body: Stack(
          children: [
            // Page background — subtle vertical tint sandwich (paints
            // edge-to-edge, even when the foreground is width-clamped
            // by PageConstraint on tablets). Gradient is theme-aware so
            // each palette's body tint matches its hero.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: palette.pageBgGradient,
                ),
              ),
            ),
            // PageConstraint = no-op on phones; clamps max width to
            // 720 (tablet-portrait) / 960 (tablet-landscape) so the
            // home doesn't stretch awkwardly on iPad.
            PageConstraint(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                // 1️⃣  Sticky white brand app bar
                BrandSliverAppBar(onMenuTap: _openDrawer),

                // 2️⃣  Aurora panel (search + optional stats)
                //     Bottom padding = 0; every following section owns
                //     its own top gap so the rhythm stays uniform.
                SliverToBoxAdapter(
                  child: HeroBody(
                    isLoggedIn:        isLoggedIn,
                    enrolledCount:     _repo.enrolledCount,
                    enrolledDelta:     _repo.enrolledDelta,
                    activeCount:       _repo.activeCount,
                    certificateCount:  _repo.certificateCount,
                  ),
                ),

                // 3️⃣  Category tiles — items + isLoading flow from
                //     CategoriesController. The tile renders English
                //     first and swaps to translated names when the
                //     overlay fetch completes (zero flicker).
                SliverToBoxAdapter(
                  child: CategoriesGrid(
                    items: cats.displayed,
                    t: t,
                    isLoading: !cats.isLoaded,
                  ),
                ),

                // 4️⃣  Featured cohort (own outer top padding = 18).
                //     Eyebrow + gradient flow from `t` + palette so the
                //     card retints alongside the rest of the chrome.
                SliverToBoxAdapter(
                  child: FeaturedCard(
                    eyebrow:  t.featuredCohortEyebrow,
                    title:    'AI & Machine Learning Pro',
                    subtitle:
                        'Live mentor sessions · placement support · 7-month cohort',
                    cta:      'Reserve your seat',
                    gradient: palette.featureGradient.colors,
                    icon:  Icons.psychology_alt_rounded,
                    badge: 'LIMITED',
                  ),
                ),

                // 5️⃣..9️⃣  All sections below FeaturedCard, wrapped
                // in a matching Transform.translate(-100) so they
                // cascade with the FeaturedCard's own -100 internal
                // pull-up. Keeps the visual rhythm tight.
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -100),
                    child: Column(
                      children: [
                        // 16 px spacer that lifts the visible
                        // Featured → Popular Courses gap to a clean
                        // 30 px (compensates for the FeaturedCard's
                        // 16 px internal bottom padding being
                        // absorbed by the section header padding).
                        const SizedBox(height: 16),
                        OffersCarousel(courses: courses),
                        WebinarsSection(items: _repo.upcomingWebinars()),
                        BundlesSection(items: _repo.courseBundles()),
                        InstructorsSection(items: _repo.topInstructors()),
                        ReviewsSection(items: _repo.studentReviews()),
                      ],
                    ),
                  ),
                ),

                // Trailing space — phase 43.13: bumped from 20 → 50 px
                // so the last review card has a ~30 px breathing gap
                // between it and the top edge of the curved bottom nav
                // (was butting right up against the curve on tall
                // screens where the Transform offset didn't leave
                // enough phantom slack).
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
              ),
            ),
          ],
        ),
        // Phase 43.15/43.16 — swap between the four nav silhouettes
        // based on the persisted user choice. All widgets share the
        // same public API so this is a single switch; everything else
        // (the 4 nav items, the basket FAB, the local _navIndex state)
        // is unchanged.
        bottomNavigationBar: _buildBottomNav(context, size, navItems),
      ),
    );
  }

  // Phase 43.16 — single switch that maps the persisted style to its
  // widget. Each option keeps the same callbacks/items so the home
  // screen's state plumbing is identical no matter which one renders.
  Widget _buildBottomNav(BuildContext context, Size size, List<CurvedNavItem> navItems) {
    final style = context.watch<BottomNavStyleController>().style;
    final onTap = (int i) => setState(() => _navIndex = i);
    switch (style) {
      case BottomNavStyle.flatPill:
        return FlatPillBottomNav(
          size: size,
          selectedIndex: _navIndex,
          onItemTapped: onTap,
          onFabTapped: () {},
          items: navItems,
        );
      case BottomNavStyle.notchedActive:
        return NotchedActiveBottomNav(
          size: size,
          selectedIndex: _navIndex,
          onItemTapped: onTap,
          onFabTapped: () {},
          items: navItems,
        );
      case BottomNavStyle.liftedCard:
        return LiftedCardBottomNav(
          size: size,
          selectedIndex: _navIndex,
          onItemTapped: onTap,
          onFabTapped: () {},
          items: navItems,
        );
      case BottomNavStyle.curved:
        return CurvedBottomNav(
          size: size,
          selectedIndex: _navIndex,
          onItemTapped: onTap,
          onFabTapped: () {},
          items: navItems,
        );
    }
  }
}
