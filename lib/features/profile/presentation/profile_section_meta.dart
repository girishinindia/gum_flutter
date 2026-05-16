// Static section catalogue. Drives the home screen's tile list, the
// router's section routes, and the per-section app-bar titles.
//
// One single source of truth so adding a section is a one-line edit.

import 'package:flutter/material.dart';

enum ProfileSectionKind { basic, contact, address, education, experience,
    projects, skills, languages, social, documents, badges, instructorBio,
    kycBank, security }

class ProfileSection {
  const ProfileSection({
    required this.kind,
    required this.path,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.instructorOnly = false,
  });

  final ProfileSectionKind kind;
  /// Sub-path under `/profile/`. No leading slash.
  final String   path;
  final String   title;
  final String   subtitle;
  final IconData icon;
  /// `true` for sections that should only appear for instructors
  /// (max_role_level >= 60). The shell hides these for everyone else.
  final bool     instructorOnly;
}

const profileSections = <ProfileSection>[
  ProfileSection(
    kind: ProfileSectionKind.basic,
    path: 'basic',
    title: 'Basic information',
    subtitle: 'Display name, headline, bio, gender, DOB',
    icon: Icons.person_outline,
  ),
  ProfileSection(
    kind: ProfileSectionKind.contact,
    path: 'contact',
    title: 'Contact',
    subtitle: 'Email, mobile, emergency contact',
    icon: Icons.contact_phone_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.address,
    path: 'address',
    title: 'Address',
    subtitle: 'Current and permanent address',
    icon: Icons.home_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.education,
    path: 'education',
    title: 'Education',
    subtitle: 'Schools, degrees, certifications',
    icon: Icons.school_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.experience,
    path: 'experience',
    title: 'Experience',
    subtitle: 'Work history and roles',
    icon: Icons.work_outline,
  ),
  ProfileSection(
    kind: ProfileSectionKind.projects,
    path: 'projects',
    title: 'Projects',
    subtitle: 'Portfolio and case studies',
    icon: Icons.architecture_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.skills,
    path: 'skills',
    title: 'Skills',
    subtitle: 'Technical and soft skills',
    icon: Icons.stars_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.languages,
    path: 'languages',
    title: 'Languages',
    subtitle: 'Languages you speak, read, write',
    icon: Icons.translate_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.social,
    path: 'social',
    title: 'Social links',
    subtitle: 'LinkedIn, GitHub, X, and more',
    icon: Icons.link,
  ),
  ProfileSection(
    kind: ProfileSectionKind.documents,
    path: 'documents',
    title: 'Documents',
    subtitle: 'KYC, certificates, government IDs',
    icon: Icons.folder_open,
  ),
  ProfileSection(
    kind: ProfileSectionKind.badges,
    path: 'badges',
    title: 'Badges',
    subtitle: 'Awards and achievements',
    icon: Icons.emoji_events_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.instructorBio,
    path: 'instructor',
    title: 'Instructor bio',
    subtitle: 'Expertise, teaching, payouts',
    icon: Icons.workspace_premium_outlined,
    instructorOnly: true,
  ),
  ProfileSection(
    kind: ProfileSectionKind.kycBank,
    path: 'kyc-bank',
    title: 'KYC & Bank',
    subtitle: 'PAN, Aadhaar, bank account',
    icon: Icons.account_balance_outlined,
  ),
  ProfileSection(
    kind: ProfileSectionKind.security,
    path: 'security',
    title: 'Security',
    subtitle: 'Change password, email, mobile',
    icon: Icons.lock_outline,
  ),
];
