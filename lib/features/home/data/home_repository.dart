// Static seed data for the home screen.
//
// This is a thin abstraction layer so the UI doesn't hardcode lists.
// When the gum_api integration lands, swap these functions for HTTP
// calls and update the return types to `Future<List<…>>` — the
// presentation layer doesn't need to know the difference.

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../i18n/messages.dart';
import '../domain/models/course_bundle.dart';
import '../domain/models/course_offer.dart';
import '../domain/models/instructor.dart';
import '../domain/models/menu_action.dart';
import '../domain/models/review.dart';
import '../domain/models/webinar.dart';

class HomeRepository {
  const HomeRepository();

  // ── Categories ────────────────────────────────────────────────────
  //
  // Removed: categories used to live here as a hardcoded list. They
  // now flow through `CategoriesController` (API-backed, language-aware,
  // English-baseline + per-language overlay). See:
  //   lib/features/catalog/categories_controller.dart
  //   lib/features/catalog/data/catalog_api.dart
  //   lib/features/catalog/data/category_icon_styles.dart  (icon lookup)

  // ── Popular courses — carousel ───────────────────────────────────
  List<CourseOffer> popularCourses() => const [
    CourseOffer(
      title: 'Data Science with Python',
      level: 'Beginner → Pro',
      duration: '6 months · 64 lessons',
      cover: [AppColors.sky700, AppColors.accent, AppColors.violet500],
      rating: 4.9,
      learners: 24000,
      pricePaise: 2999900,
      originalPricePaise: 4999900,
      progress: 0.78,
      instructorAccents: [AppColors.amber, AppColors.rose, AppColors.sky500],
      extraInstructors: 5,
      badge: 'HOT',
    ),
    CourseOffer(
      title: 'AI & Machine Learning Pro',
      level: 'Intermediate',
      duration: '7 months · 86 lessons',
      cover: [AppColors.success, AppColors.sky500, AppColors.accent],
      rating: 4.9,
      learners: 18000,
      pricePaise: 3999900,
      originalPricePaise: 6999900,
      progress: 0.0,
      instructorAccents: [AppColors.violet500, AppColors.success, AppColors.amber],
      extraInstructors: 3,
      badge: 'BESTSELLER',
    ),
    CourseOffer(
      title: 'MERN Full-Stack Engineer',
      level: 'Beginner → Pro',
      duration: '5 months · 92 lessons',
      cover: [AppColors.violet500, AppColors.rose, AppColors.amber],
      rating: 4.7,
      learners: 21000,
      pricePaise: 3499900,
      originalPricePaise: 5999900,
      progress: 0.32,
      instructorAccents: [AppColors.sky500, AppColors.accent],
      extraInstructors: 2,
      badge: 'NEW',
    ),
    CourseOffer(
      title: 'Cloud & DevOps Essentials',
      level: 'Intermediate',
      duration: '5 months · 72 lessons',
      cover: [AppColors.sky800, AppColors.accent],
      rating: 4.8,
      learners: 12000,
      pricePaise: 2999900,
      originalPricePaise: 4999900,
      progress: 0.0,
      instructorAccents: [AppColors.success, AppColors.accent, AppColors.violet500],
      extraInstructors: 1,
    ),
  ];

  // ── Drawer menu rows ─────────────────────────────────────────────
  //
  // Labels come from the active `Messages` so the drawer switches
  // languages with the rest of the UI. Icons + accent colours stay
  // constant.
  List<MenuAction> drawerMenu(Messages t) => [
    MenuAction(label: t.drawerHome,          icon: Icons.home_rounded,            iconColor: AppColors.sky500),
    MenuAction(label: t.drawerMyCourses,     icon: Icons.menu_book_rounded,       iconColor: AppColors.accent,    badgeCount: 3),
    MenuAction(label: t.drawerWishlist,      icon: Icons.favorite_rounded,        iconColor: AppColors.rose),
    MenuAction(label: t.drawerCart,          icon: Icons.shopping_cart_rounded,   iconColor: AppColors.amber,     badgeCount: 2),
    MenuAction(label: t.drawerWallet,        icon: Icons.account_balance_wallet_rounded, iconColor: AppColors.success),
    MenuAction(label: t.drawerNotifications, icon: Icons.notifications_rounded,   iconColor: AppColors.violet500, badgeCount: 4),
    MenuAction(label: t.drawerDiscussion,    icon: Icons.forum_rounded,           iconColor: AppColors.sky500),
    MenuAction(label: t.drawerProfile,       icon: Icons.person_rounded,          iconColor: AppColors.accent),
    MenuAction(label: t.drawerSettings,      icon: Icons.settings_rounded,        iconColor: AppColors.slate600),
    MenuAction(label: t.drawerHelp,          icon: Icons.help_outline_rounded,    iconColor: AppColors.slate600),
  ];

  // ── User snapshot (fallback only) ────────────────────────────────
  // Real values come from AuthBloc.state.user (read in HomeScreen).
  // These literals are only used when the bloc hasn't loaded yet
  // (e.g. during the brief unknown → authenticated transition).
  String get userFirstName => 'Manshi';
  String get userLastName  => 'Khunt';
  String get userInitial   => userFirstName[0];
  int get enrolledCount    => 12;
  int get enrolledDelta    => 2;     // +N this week
  int get activeCount      => 7;
  int get certificateCount => 4;
  double get learningProgress => 0.62;  // overall % across enrolled courses
  int get unreadNotifications  => 5;

  // ── Upcoming webinars — horizontal carousel ──────────────────────
  List<Webinar> upcomingWebinars() {
    final now = DateTime.now();
    return [
      Webinar(
        title:             'Building Production-Grade RAG with LLMs',
        instructor:        'Dr. Aarav Sharma',
        instructorInitial: 'A',
        startsAt:          now.add(const Duration(hours: 2)),
        durationMinutes:   90,
        cover:             const [AppColors.violet600, AppColors.accent],
        accent:             AppColors.violet500,
        isLive:             true,
        registeredCount:    2840,
      ),
      Webinar(
        title:             'Crack the System Design Interview',
        instructor:        'Riya Mehta',
        instructorInitial: 'R',
        startsAt:          now.add(const Duration(days: 1, hours: 3)),
        durationMinutes:   60,
        cover:             const [AppColors.sky700, AppColors.accent],
        accent:             AppColors.sky500,
        registeredCount:    1240,
      ),
      Webinar(
        title:             'Mastering Flutter Animations',
        instructor:        'Karan Patel',
        instructorInitial: 'K',
        startsAt:          now.add(const Duration(days: 3, hours: 5)),
        durationMinutes:   75,
        cover:             const [AppColors.success, AppColors.sky500],
        accent:             AppColors.success,
        registeredCount:    560,
      ),
      Webinar(
        title:             'Data Science Career Roadmap 2026',
        instructor:        'Priya Verma',
        instructorInitial: 'P',
        startsAt:          now.add(const Duration(days: 5, hours: 1)),
        durationMinutes:   45,
        cover:             const [AppColors.amber, AppColors.rose],
        accent:             AppColors.rose,
        registeredCount:    980,
      ),
    ];
  }

  // ── Course bundles — savings-led offer cards ─────────────────────
  List<CourseBundle> courseBundles() => const [
    CourseBundle(
      name:             'Full-Stack Mastery',
      subtitle:         'Frontend → Backend → Deploy',
      courseCount:      5,
      cover:            [AppColors.sky500, AppColors.accent, AppColors.violet500],
      totalPricePaise:  1499900,
      bundlePricePaise:  899900,
      savingsLabel:     'Save 40%',
      icon:             Icons.layers_rounded,
    ),
    CourseBundle(
      name:             'AI & Data Science Pro',
      subtitle:         'Python · ML · DL · MLOps',
      courseCount:      6,
      cover:            [AppColors.violet600, AppColors.accent, AppColors.sky500],
      totalPricePaise:  1799900,
      bundlePricePaise:  999900,
      savingsLabel:     'Save 44%',
      icon:             Icons.psychology_alt_rounded,
    ),
    CourseBundle(
      name:             'Cloud + DevOps Bundle',
      subtitle:         'AWS · Docker · Kubernetes · CI/CD',
      courseCount:      4,
      cover:            [AppColors.success, AppColors.sky500, AppColors.accent],
      totalPricePaise:  1199900,
      bundlePricePaise:  799900,
      savingsLabel:     'Save 33%',
      icon:             Icons.cloud_rounded,
    ),
    CourseBundle(
      name:             'Designer Career Pack',
      subtitle:         'UI · UX · Figma · Prototyping',
      courseCount:      4,
      cover:            [AppColors.rose, AppColors.amber, AppColors.violet500],
      totalPricePaise:   999900,
      bundlePricePaise:  599900,
      savingsLabel:     'Save 40%',
      icon:             Icons.palette_rounded,
    ),
  ];

  // ── Top instructors — horizontal rail ────────────────────────────
  List<Instructor> topInstructors() => const [
    Instructor(
      name:           'Dr. Aarav Sharma',
      initial:        'A',
      specialty:      'AI · ML · Deep Learning',
      rating:         4.9,
      studentCount:   28400,
      courseCount:    8,
      avatarGradient: [AppColors.violet500, AppColors.accent],
    ),
    Instructor(
      name:           'Riya Mehta',
      initial:        'R',
      specialty:      'System Design · DSA',
      rating:         4.8,
      studentCount:   19800,
      courseCount:    6,
      avatarGradient: [AppColors.sky500, AppColors.accent],
    ),
    Instructor(
      name:           'Karan Patel',
      initial:        'K',
      specialty:      'Flutter · iOS · Android',
      rating:         4.9,
      studentCount:   14200,
      courseCount:    5,
      avatarGradient: [AppColors.success, AppColors.sky500],
    ),
    Instructor(
      name:           'Priya Verma',
      initial:        'P',
      specialty:      'Data Science · Analytics',
      rating:         4.7,
      studentCount:   11600,
      courseCount:    4,
      avatarGradient: [AppColors.amber, AppColors.rose],
    ),
    Instructor(
      name:           'Vikram Singh',
      initial:        'V',
      specialty:      'Cyber Security · Ethical Hacking',
      rating:         4.8,
      studentCount:    9300,
      courseCount:    5,
      avatarGradient: [AppColors.rose, AppColors.violet500],
    ),
  ];

  // ── Student reviews — testimonial carousel ───────────────────────
  List<Review> studentReviews() => const [
    Review(
      studentName:    'Ananya Iyer',
      studentInitial: 'A',
      courseName:     'Data Science with Python',
      rating:         5.0,
      comment:
          'Dr. Aarav explained everything from basics to advanced in a structured way. I cracked a data-analyst role in 4 months!',
      avatarColor:    AppColors.sky500,
    ),
    Review(
      studentName:    'Rohan Joshi',
      studentInitial: 'R',
      courseName:     'AI & Machine Learning Pro',
      rating:         5.0,
      comment:
          'Live mentor sessions are a game changer. The hands-on projects gave me a portfolio I actually use in interviews.',
      avatarColor:    AppColors.violet500,
    ),
    Review(
      studentName:    'Sneha Kapoor',
      studentInitial: 'S',
      courseName:     'MERN Full-Stack Engineer',
      rating:         4.8,
      comment:
          'Loved the project-based approach. Built and shipped 3 real apps. Karan sir replies to every doubt within hours.',
      avatarColor:    AppColors.success,
    ),
    Review(
      studentName:    'Aman Khanna',
      studentInitial: 'A',
      courseName:     'Cloud & DevOps Essentials',
      rating:         4.9,
      comment:
          'Best value-for-money cohort I have taken. The AWS labs and the CI/CD pipeline module alone were worth the fee.',
      avatarColor:    AppColors.amber,
    ),
  ];
}
