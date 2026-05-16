// Events for the ProfileBloc.
//
// Coarse-grained on purpose: each maps to a user action or an
// external signal, not to a screen interaction. The two main ones
// are Load (initial fetch + Refresh repeat) and the per-section
// Updated events that let any save flow inject its new server row
// back into the bundle without forcing a full reload.

import 'package:equatable/equatable.dart';

import '../data/profile_repository.dart';
import '../domain/user_profile.dart';
import '../domain/user_sub_resources.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => const [];
}

/// Initial load on first mount. Idempotent — calling twice while
/// loading is a no-op.
class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested({this.force = false});
  final bool force;
  @override
  List<Object?> get props => [force];
}

/// Pull-to-refresh — re-fetch every section in parallel.
class ProfileRefreshRequested extends ProfileEvent {
  const ProfileRefreshRequested();
}

/// Repository finished an `updateProfile()` — swap the cached
/// UserProfile in the bundle so any section reading it picks up the
/// fresh values without a round-trip.
class ProfileProfileUpdated extends ProfileEvent {
  const ProfileProfileUpdated(this.profile);
  final UserProfile profile;
  @override
  List<Object?> get props => [profile];
}

/// Replace the full education list (after an add / update / delete).
class ProfileEducationReplaced extends ProfileEvent {
  const ProfileEducationReplaced(this.list);
  final List<UserEducation> list;
  @override
  List<Object?> get props => [list];
}

class ProfileExperienceReplaced extends ProfileEvent {
  const ProfileExperienceReplaced(this.list);
  final List<UserExperience> list;
  @override
  List<Object?> get props => [list];
}

class ProfileProjectsReplaced extends ProfileEvent {
  const ProfileProjectsReplaced(this.list);
  final List<UserProject> list;
  @override
  List<Object?> get props => [list];
}

class ProfileSkillsReplaced extends ProfileEvent {
  const ProfileSkillsReplaced(this.list);
  final List<UserSkill> list;
  @override
  List<Object?> get props => [list];
}

class ProfileLanguagesReplaced extends ProfileEvent {
  const ProfileLanguagesReplaced(this.list);
  final List<UserLanguage> list;
  @override
  List<Object?> get props => [list];
}

class ProfileSocialMediasReplaced extends ProfileEvent {
  const ProfileSocialMediasReplaced(this.list);
  final List<UserSocialMedia> list;
  @override
  List<Object?> get props => [list];
}

class ProfileDocumentsReplaced extends ProfileEvent {
  const ProfileDocumentsReplaced(this.list);
  final List<UserDocument> list;
  @override
  List<Object?> get props => [list];
}

class ProfileInstructorReplaced extends ProfileEvent {
  const ProfileInstructorReplaced(this.profile);
  final InstructorProfile profile;
  @override
  List<Object?> get props => [profile];
}

/// Internal — fires when `loadAll` resolves.
class ProfileBundleLoaded extends ProfileEvent {
  const ProfileBundleLoaded(this.bundle);
  final ProfileBundle bundle;
  @override
  List<Object?> get props => [bundle];
}

/// Internal — fires when `loadAll` throws.
class ProfileLoadFailed extends ProfileEvent {
  const ProfileLoadFailed(this.error);
  final String error;
  @override
  List<Object?> get props => [error];
}
