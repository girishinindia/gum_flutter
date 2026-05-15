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
            // Page background — subtle vertical tint sandwich.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.pageBackgroundGradient,
                ),
              ),
            ),
            CustomScrollView(
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

                // 5️⃣..9️⃣  All sections BELOW the FeaturedCard, wrapped
                // in a single Transform.translate(-100) that matches the
                // FeaturedCard's own -100 internal pull-up. Why?
                //
                // The FeaturedCard renders 100 px ABOVE its layout slot
                // (Transform.translate moves pixels, not layout). So if
                // these next sections stay at their natural layout
                // positions, a 100 px "ghost gap" opens up between the
                // FeaturedCard's visible bottom and the OffersCarousel's
                // header above. Pulling them up by the same amount keeps
                // the entire bottom stack visually tight.
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -100),
                    child: Column(
                      children: [
                        OffersCarousel(courses: courses),
                        WebinarsSection(items: _repo.upcomingWebinars()),
                        BundlesSection(items: _repo.courseBundles()),
                        InstructorsSection(items: _repo.topInstructors()),
                        ReviewsSection(items: _repo.studentReviews()),
                      ],
                    ),
                  ),
                ),

                // Trailing space so the BNB doesn't cover content.
                // Reduced 120 → 20 because the lifted Column above is
                // already pulled 100 px upward (Transform.translate),
                // which leaves a 100 px "phantom" layout slot below it.
                // 20 px is the minimum safety clearance from the curved
                // nav + FAB (which together block ~90 px from screen
                // bottom — extendBody is on, so this trailing prevents
                // the last visible review card from being clipped).
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
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
