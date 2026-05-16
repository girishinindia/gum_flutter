// The profile state machine. Owns the loaded ProfileBundle and
// re-emits a fresh state every time a section save reports back via
// a `*Replaced` event.
//
// Why dispatch events for saves (vs. mutating directly)?
//   • Single source of truth — every consumer sees the same bundle.
//   • Testability — fake out the repo and drive the bloc events.
//   • Cheap rebuilds — Equatable on the bundle's sub-lists means
//     BlocBuilder only fires when something actually changed.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required ProfileRepository repository,
    required this.isInstructor,
  })  : _repo = repository,
        super(const ProfileState.initial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileRefreshRequested>(_onRefresh);
    on<ProfileBundleLoaded>(_onBundleLoaded);
    on<ProfileLoadFailed>(_onLoadFailed);

    on<ProfileProfileUpdated>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(profile: e.profile)));
    });

    on<ProfileEducationReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(education: e.list)));
    });
    on<ProfileExperienceReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(experience: e.list)));
    });
    on<ProfileProjectsReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(projects: e.list)));
    });
    on<ProfileSkillsReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(skills: e.list)));
    });
    on<ProfileLanguagesReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(languages: e.list)));
    });
    on<ProfileSocialMediasReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(socialMedias: e.list)));
    });
    on<ProfileDocumentsReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(documents: e.list)));
    });
    on<ProfileInstructorReplaced>((e, emit) {
      final b = state.bundle;
      if (b == null) return;
      emit(ProfileState.loaded(b.copyWith(instructorProfile: e.profile)));
    });
  }

  final ProfileRepository _repo;
  /// Drives whether `/instructor-profiles/me` gets fetched on Load.
  /// Read from `AuthBloc.state.user.isInstructor` when constructing.
  final bool isInstructor;

  Future<void> _onLoad(ProfileLoadRequested e, Emitter<ProfileState> emit) async {
    if (state.status == ProfileStatus.loading && !e.force) return;
    emit(const ProfileState.loading());
    try {
      final bundle = await _repo.loadAll(isInstructor: isInstructor);
      add(ProfileBundleLoaded(bundle));
    } catch (err) {
      add(ProfileLoadFailed(err.toString()));
    }
  }

  Future<void> _onRefresh(ProfileRefreshRequested e, Emitter<ProfileState> emit) async {
    try {
      final bundle = await _repo.loadAll(isInstructor: isInstructor);
      emit(ProfileState.loaded(bundle));
    } catch (err) {
      // Refresh-failed shouldn't clobber a previously-loaded bundle
      // — keep the last good state visible.
      if (state.bundle != null) return;
      emit(ProfileState.error(err.toString()));
    }
  }

  void _onBundleLoaded(ProfileBundleLoaded e, Emitter<ProfileState> emit) {
    emit(ProfileState.loaded(e.bundle));
  }

  void _onLoadFailed(ProfileLoadFailed e, Emitter<ProfileState> emit) {
    emit(ProfileState.error(e.error));
  }

  ProfileRepository get repository => _repo;
}
