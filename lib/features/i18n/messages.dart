// Static UI strings (chrome). Mirrors gum_web's lib/i18n/messages.ts.
//
// Only the bits that aren't API-driven live here — section eyebrows,
// drawer item labels, "See all", "Sign in", etc. Dynamic content
// (categories, courses) comes from the API per-language.
//
// Pattern: every locale falls back to English for any missing key,
// so adding a new language only requires translating the strings
// you care about.

import 'package:flutter/foundation.dart';

@immutable
class Messages {
  // ── Section eyebrows + titles ──────────────────────────────────────
  final String exploreEyebrow;
  final String browseCategoriesTitle;
  final String featuredCohortEyebrow;
  final String topPicksEyebrow;
  final String popularCoursesTitle;
  final String thisWeekEyebrow;
  final String upcomingWebinarsTitle;
  final String bestValueEyebrow;
  final String courseBundlesTitle;
  final String learnFromBestEyebrow;
  final String topInstructorsTitle;
  final String lovedByLearnersEyebrow;
  final String studentReviewsTitle;

  // ── Common ─────────────────────────────────────────────────────────
  final String seeAll;
  final String searchPlaceholder;
  final String signIn;
  final String signOut;
  final String language;
  final String theme;
  final String chooseTheme;
  final String welcome;
  final String trackProgress;

  // ── Drawer items ───────────────────────────────────────────────────
  final String drawerHome;
  final String drawerMyCourses;
  final String drawerWishlist;
  final String drawerCart;
  final String drawerWallet;
  final String drawerNotifications;
  final String drawerDiscussion;
  final String drawerProfile;
  final String drawerSettings;
  final String drawerHelp;

  // ── Bottom nav ─────────────────────────────────────────────────────
  final String navHome;
  final String navLearn;
  final String navSaved;
  final String navProfile;

  // ── Greetings ──────────────────────────────────────────────────────
  final String greetingMorning;
  final String greetingAfternoon;
  final String greetingEvening;
  final String greetingNight;

  const Messages({
    required this.exploreEyebrow,
    required this.browseCategoriesTitle,
    required this.featuredCohortEyebrow,
    required this.topPicksEyebrow,
    required this.popularCoursesTitle,
    required this.thisWeekEyebrow,
    required this.upcomingWebinarsTitle,
    required this.bestValueEyebrow,
    required this.courseBundlesTitle,
    required this.learnFromBestEyebrow,
    required this.topInstructorsTitle,
    required this.lovedByLearnersEyebrow,
    required this.studentReviewsTitle,
    required this.seeAll,
    required this.searchPlaceholder,
    required this.signIn,
    required this.signOut,
    required this.language,
    required this.theme,
    required this.chooseTheme,
    required this.welcome,
    required this.trackProgress,
    required this.drawerHome,
    required this.drawerMyCourses,
    required this.drawerWishlist,
    required this.drawerCart,
    required this.drawerWallet,
    required this.drawerNotifications,
    required this.drawerDiscussion,
    required this.drawerProfile,
    required this.drawerSettings,
    required this.drawerHelp,
    required this.navHome,
    required this.navLearn,
    required this.navSaved,
    required this.navProfile,
    required this.greetingMorning,
    required this.greetingAfternoon,
    required this.greetingEvening,
    required this.greetingNight,
  });

  // ── English baseline (every other locale falls back to these) ──────
  static const Messages en = Messages(
    exploreEyebrow:        'EXPLORE',
    browseCategoriesTitle: 'Browse Categories',
    featuredCohortEyebrow: 'FEATURED COHORT',
    topPicksEyebrow:       'TOP PICKS',
    popularCoursesTitle:   'Popular Courses',
    thisWeekEyebrow:       'THIS WEEK',
    upcomingWebinarsTitle: 'Upcoming Webinars',
    bestValueEyebrow:      'BEST VALUE',
    courseBundlesTitle:    'Course Bundles',
    learnFromBestEyebrow:  'LEARN FROM THE BEST',
    topInstructorsTitle:   'Top Instructors',
    lovedByLearnersEyebrow:'LOVED BY LEARNERS',
    studentReviewsTitle:   'Student Reviews',
    seeAll:                'See all',
    searchPlaceholder:     'Search courses · Python · AI…',
    signIn:                'Sign in',
    signOut:               'Sign out',
    language:              'Language',
    theme:                 'Theme',
    chooseTheme:           'Choose theme',
    welcome:               'Welcome to Grow Up More',
    trackProgress:         'Sign in to track your progress',
    drawerHome:            'Home',
    drawerMyCourses:       'My Courses',
    drawerWishlist:        'Wishlist',
    drawerCart:            'Cart',
    drawerWallet:          'Wallet',
    drawerNotifications:   'Notifications',
    drawerDiscussion:      'Discussion',
    drawerProfile:         'Profile',
    drawerSettings:        'Settings',
    drawerHelp:            'Help & Support',
    navHome:               'Home',
    navLearn:              'Learn',
    navSaved:              'Saved',
    navProfile:            'Profile',
    greetingMorning:       'Good morning,',
    greetingAfternoon:     'Good afternoon,',
    greetingEvening:       'Good evening,',
    greetingNight:         'Working late,',
  );

  // ── Hindi (partial translations; everything else falls back to en) ─
  static const Messages hi = Messages(
    exploreEyebrow:        'खोजें',
    browseCategoriesTitle: 'श्रेणियाँ देखें',
    featuredCohortEyebrow: 'फ़ीचर्ड कोहोर्ट',
    topPicksEyebrow:       'टॉप पिक्स',
    popularCoursesTitle:   'लोकप्रिय कोर्स',
    thisWeekEyebrow:       'इस हफ्ते',
    upcomingWebinarsTitle: 'आने वाले वेबिनार',
    bestValueEyebrow:      'सबसे अच्छा मूल्य',
    courseBundlesTitle:    'कोर्स बंडल',
    learnFromBestEyebrow:  'सर्वश्रेष्ठ से सीखें',
    topInstructorsTitle:   'शीर्ष प्रशिक्षक',
    lovedByLearnersEyebrow:'सीखने वालों का पसंदीदा',
    studentReviewsTitle:   'छात्र समीक्षाएँ',
    seeAll:                'सभी देखें',
    searchPlaceholder:     'कोर्स खोजें · Python · AI…',
    signIn:                'साइन इन करें',
    signOut:               'साइन आउट',
    language:              'भाषा',
    theme:                 'थीम',
    chooseTheme:           'थीम चुनें',
    welcome:               'Grow Up More में आपका स्वागत है',
    trackProgress:         'अपनी प्रगति ट्रैक करने के लिए साइन इन करें',
    drawerHome:            'होम',
    drawerMyCourses:       'मेरे कोर्स',
    drawerWishlist:        'विशलिस्ट',
    drawerCart:            'कार्ट',
    drawerWallet:          'वॉलेट',
    drawerNotifications:   'सूचनाएँ',
    drawerDiscussion:      'चर्चा',
    drawerProfile:         'प्रोफ़ाइल',
    drawerSettings:        'सेटिंग्स',
    drawerHelp:            'सहायता',
    navHome:               'होम',
    navLearn:              'सीखें',
    navSaved:              'सहेजे गए',
    navProfile:            'प्रोफ़ाइल',
    greetingMorning:       'सुप्रभात,',
    greetingAfternoon:     'नमस्ते,',
    greetingEvening:       'शुभ संध्या,',
    greetingNight:         'देर रात,',
  );

  /// Resolve the Messages instance for a given ISO code. Unknown codes
  /// fall back to English.
  static Messages forIso(String iso) {
    switch (iso.toLowerCase()) {
      case 'hi':  return hi;
      default:    return en;
    }
  }
}
