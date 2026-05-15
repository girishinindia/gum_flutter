// Premium Aurora home — entire screen composition.
//
// Slivers (in order):
//   1. BrandSliverAppBar   — sticky white app bar (logo + drawer)
//   2. HeroBody            — aurora panel (search + optional stats)
//   3. CategoriesGrid      — 4-column tile grid
//   4. FeaturedCard + OffersCarousel — pulled together with one
//      Transform.translate so they sit tight under the categories.
//
// Auth state is tracked locally as `_isLoggedIn` (default true while
// we don't yet have a real auth gate). When false:
//   • the stats row in the hero is hidden
//   • the drawer shows a "Sign in" CTA instead of the user header

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/curved_bottom_nav.dart';
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

  /// Local demo flag — default signed-out; opt-in via the drawer's
  /// "Sign in" CTA. Replace with real auth state once the auth layer
  /// lands.
  bool _isLoggedIn = false;
  int  _navIndex   = 0;

  static const _navItems = <CurvedNavItem>[
    CurvedNavItem(icon: Icons.home_rounded,         label: 'Home'),
    CurvedNavItem(icon: Icons.menu_book_rounded,    label: 'Learn'),
    CurvedNavItem(icon: Icons.bookmark_rounded,     label: 'Saved', badge: true),
    CurvedNavItem(icon: Icons.person_rounded,       label: 'Profile'),
  ];

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    final size       = MediaQuery.of(context).size;
    final categories = _repo.categories();
    final courses    = _repo.popularCourses();
    final menu       = _repo.drawerMenu();

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
          isLoggedIn: _isLoggedIn,
          firstName: _repo.userFirstName,
          lastName:  _repo.userLastName,
          initial:   _repo.userInitial,
          email:     'manshi.khunt@gmail.com',
          streakDays: 7,
          items: menu,
          onItemTap:  (_) {},
          onSignOut:  () => setState(() => _isLoggedIn = false),
          onSignIn:   () => setState(() => _isLoggedIn = true),
        ),
        body: Stack(
          children: [
            // Page background — subtle vertical tint sandwich (paints
            // edge-to-edge, even when the foreground is width-clamped
            // by PageConstraint on tablets).
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.pageBackgroundGradient,
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
                    isLoggedIn:        _isLoggedIn,
                    enrolledCount:     _repo.enrolledCount,
                    enrolledDelta:     _repo.enrolledDelta,
                    activeCount:       _repo.activeCount,
                    certificateCount:  _repo.certificateCount,
                  ),
                ),

                // 3️⃣  Category tiles
                SliverToBoxAdapter(
                  child: CategoriesGrid(items: categories),
                ),

                // 4️⃣  Featured cohort (own outer top padding = 18)
                const SliverToBoxAdapter(
                  child: FeaturedCard(
                    eyebrow:  'FEATURED COHORT',
                    title:    'AI & Machine Learning Pro',
                    subtitle:
                        'Live mentor sessions · placement support · 7-month cohort',
                    cta:      'Reserve your seat',
                    gradient: [
                      AppColors.violet600,
                      AppColors.accent,
                      AppColors.sky500,
                    ],
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

                // Trailing space — reduced because the bottom Column
                // above is lifted 100 px via Transform, leaving a
                // matching phantom slot. 20 px gives clearance from
                // the curved nav + FAB protrusion.
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CurvedBottomNav(
          size: size,
          selectedIndex: _navIndex,
          onItemTapped: (i) => setState(() => _navIndex = i),
          onFabTapped: () {},
          items: _navItems,
        ),
      ),
    );
  }
}
