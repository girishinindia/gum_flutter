// ProfileBloc state machine.
//
// Three terminal states:
//   • initial / loading  — first fetch in flight
//   • loaded(bundle)     — every section populated (possibly empty
//                          lists for endpoints that 4xx'd)
//   • error(message)     — the load wholly failed (bundle never landed)
//
// Saves don't pass through here — they live on the per-section screens
// and only emit "replaced" events after success.

import 'package:equatable/equatable.dart';

import '../data/profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  const ProfileState._({
    required this.status,
    this.bundle,
    this.errorMessage,
  });

  const ProfileState.initial()       : this._(status: ProfileStatus.initial);
  const ProfileState.loading()       : this._(status: ProfileStatus.loading);
  const ProfileState.loaded(ProfileBundle b)
      : this._(status: ProfileStatus.loaded, bundle: b);
  const ProfileState.error(String msg)
      : this._(status: ProfileStatus.error, errorMessage: msg);

  final ProfileStatus    status;
  final ProfileBundle?   bundle;
  final String?          errorMessage;

  bool get isLoaded => status == ProfileStatus.loaded && bundle != null;

  ProfileState copyWith({ProfileBundle? bundle}) =>
      ProfileState._(status: status, bundle: bundle ?? this.bundle, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, bundle, errorMessage];
}
