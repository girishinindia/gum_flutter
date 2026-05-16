// Aggregates the profile sub-resource APIs into a single repository
// the ProfileBloc can call. Mirrors what the web side does in
// `gum_web/lib/users/client.ts` (one top-level call layer, multiple
// resource-scoped functions inside).
//
// Loads:
//   • UserProfile               via /user-profiles/me
//   • UserEducation[]           via /user-education/me
//   • UserExperience[]          via /user-experience/me
//   • UserProject[]             via /user-projects/me
//   • UserSkill[]               via /user-skills/me
//   • UserLanguage[]            via /user-languages/me
//   • UserSocialMedia[]         via /user-social-medias/me
//   • UserDocument[]            via /user-documents/me
//   • UserBadge[]               via /user-badges/me
//   • InstructorProfile?        via /instructor-profiles/me (instructor only)
//
// The repo deliberately swallows per-resource errors during the
// initial load so that one failing endpoint (e.g. instructor profile
// 404 for non-instructors) doesn't take down the whole page. Errors
// are surfaced field-by-field on save instead.

import '../domain/user_profile.dart';
import '../domain/user_sub_resources.dart';
import 'profile_api.dart';

class ProfileRepository {
  ProfileRepository({
    ProfileApi?           profileApi,
    EducationApi?         educationApi,
    ExperienceApi?        experienceApi,
    ProjectsApi?          projectsApi,
    SkillsApi?            skillsApi,
    LanguagesApi?         languagesApi,
    SocialMediaApi?       socialMediaApi,
    DocumentsApi?         documentsApi,
    BadgesApi?            badgesApi,
    InstructorProfileApi? instructorApi,
  })  : _profileApi     = profileApi     ?? ProfileApi(),
        _educationApi   = educationApi   ?? EducationApi(),
        _experienceApi  = experienceApi  ?? ExperienceApi(),
        _projectsApi    = projectsApi    ?? ProjectsApi(),
        _skillsApi      = skillsApi      ?? SkillsApi(),
        _languagesApi   = languagesApi   ?? LanguagesApi(),
        _socialMediaApi = socialMediaApi ?? SocialMediaApi(),
        _documentsApi   = documentsApi   ?? DocumentsApi(),
        _badgesApi      = badgesApi      ?? BadgesApi(),
        _instructorApi  = instructorApi  ?? InstructorProfileApi();

  final ProfileApi           _profileApi;
  final EducationApi         _educationApi;
  final ExperienceApi        _experienceApi;
  final ProjectsApi          _projectsApi;
  final SkillsApi            _skillsApi;
  final LanguagesApi         _languagesApi;
  final SocialMediaApi       _socialMediaApi;
  final DocumentsApi         _documentsApi;
  final BadgesApi            _badgesApi;
  final InstructorProfileApi _instructorApi;

  /// Direct API access for sections that need finer-grained calls
  /// (e.g. multipart uploads). Exposed so per-section screens don't
  /// have to be funneled through the repo's narrower interface.
  ProfileApi           get profileApi    => _profileApi;
  EducationApi         get educationApi  => _educationApi;
  ExperienceApi        get experienceApi => _experienceApi;
  ProjectsApi          get projectsApi   => _projectsApi;
  SkillsApi            get skillsApi     => _skillsApi;
  LanguagesApi         get languagesApi  => _languagesApi;
  SocialMediaApi       get socialMediaApi=> _socialMediaApi;
  DocumentsApi         get documentsApi  => _documentsApi;
  BadgesApi            get badgesApi     => _badgesApi;
  InstructorProfileApi get instructorApi => _instructorApi;

  /// Load every section in parallel. Wraps each in a safety try/catch
  /// so a single failing endpoint becomes `null` / `[]` instead of
  /// blowing up the whole page.
  Future<ProfileBundle> loadAll({required bool isInstructor}) async {
    final results = await Future.wait<Object?>([
      _safe(_profileApi.getMyProfile),
      _safe(_educationApi.list),
      _safe(_experienceApi.list),
      _safe(_projectsApi.list),
      _safe(_skillsApi.list),
      _safe(_languagesApi.list),
      _safe(_socialMediaApi.list),
      _safe(_documentsApi.list),
      _safe(_badgesApi.list),
      isInstructor ? _safe(_instructorApi.get) : Future.value(null),
    ]);

    return ProfileBundle(
      profile:      results[0] as UserProfile? ?? const UserProfile(),
      education:    (results[1] as List<UserEducation>?)  ?? const [],
      experience:   (results[2] as List<UserExperience>?) ?? const [],
      projects:     (results[3] as List<UserProject>?)    ?? const [],
      skills:       (results[4] as List<UserSkill>?)      ?? const [],
      languages:    (results[5] as List<UserLanguage>?)   ?? const [],
      socialMedias: (results[6] as List<UserSocialMedia>?) ?? const [],
      documents:    (results[7] as List<UserDocument>?)   ?? const [],
      badges:       (results[8] as List<UserBadge>?)      ?? const [],
      instructorProfile: results[9] as InstructorProfile?,
    );
  }

  /// Update the extended UserProfile row. Used by Basic Info, Contact,
  /// Address, KYC + Bank sections (each posts a partial patch).
  Future<UserProfile> updateProfile(Map<String, dynamic> patch) =>
      _profileApi.updateMyProfile(patch);

  /// Multipart variant — used by the avatar picker in Basic Info to upload
  /// `profile_image` (or `cover_image`) alongside any text patch fields.
  /// Forwarding helper; the API method does the FormData assembly.
  Future<UserProfile> updateProfileWithImage({
    Map<String, dynamic>? patch,
    String? profileImagePath,
    String? profileImageFilename,
    String? profileImageMimeType,
    String? coverImagePath,
    String? coverImageFilename,
    String? coverImageMimeType,
  }) =>
      _profileApi.updateMyProfileWithImage(
        patch: patch,
        profileImagePath:     profileImagePath,
        profileImageFilename: profileImageFilename,
        profileImageMimeType: profileImageMimeType,
        coverImagePath:       coverImagePath,
        coverImageFilename:   coverImageFilename,
        coverImageMimeType:   coverImageMimeType,
      );

  static Future<T?> _safe<T>(Future<T> Function() fn) async {
    try { return await fn(); } catch (_) { return null; }
  }
}

/// Aggregate response returned by `loadAll`.
class ProfileBundle {
  const ProfileBundle({
    required this.profile,
    required this.education,
    required this.experience,
    required this.projects,
    required this.skills,
    required this.languages,
    required this.socialMedias,
    required this.documents,
    required this.badges,
    required this.instructorProfile,
  });

  final UserProfile           profile;
  final List<UserEducation>   education;
  final List<UserExperience>  experience;
  final List<UserProject>     projects;
  final List<UserSkill>       skills;
  final List<UserLanguage>    languages;
  final List<UserSocialMedia> socialMedias;
  final List<UserDocument>    documents;
  final List<UserBadge>       badges;
  final InstructorProfile?    instructorProfile;

  ProfileBundle copyWith({
    UserProfile?              profile,
    List<UserEducation>?      education,
    List<UserExperience>?     experience,
    List<UserProject>?        projects,
    List<UserSkill>?          skills,
    List<UserLanguage>?       languages,
    List<UserSocialMedia>?    socialMedias,
    List<UserDocument>?       documents,
    List<UserBadge>?          badges,
    InstructorProfile?        instructorProfile,
  }) =>
      ProfileBundle(
        profile:           profile           ?? this.profile,
        education:         education         ?? this.education,
        experience:        experience        ?? this.experience,
        projects:          projects          ?? this.projects,
        skills:            skills            ?? this.skills,
        languages:         languages         ?? this.languages,
        socialMedias:      socialMedias      ?? this.socialMedias,
        documents:         documents         ?? this.documents,
        badges:            badges            ?? this.badges,
        instructorProfile: instructorProfile ?? this.instructorProfile,
      );
}
