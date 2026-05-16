// The authenticated user as seen by the app. Mirrors `AuthUser` in
// `gum_web/lib/auth/session.ts` — same wire keys. Roles + max_role_level
// are populated by /users/me after login (not from /auth/login itself).

import 'package:equatable/equatable.dart';

import 'auth_role.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    this.roles,
    this.maxRoleLevel,
    this.displayName,
    this.profileImageUrl,
  });

  final int           id;
  final String        firstName;
  final String        lastName;
  final String        email;
  final String        mobile;
  final List<AuthRole>? roles;
  final int?          maxRoleLevel;

  /// `users.display_name` — surfaced through `v_user_profile` as of
  /// phase28 so BasicInfo input rehydrates correctly after a refresh.
  final String? displayName;

  /// Server returns either `profile_image_url` (newer routes) or
  /// `avatar_url` (older). We coalesce on the way in.
  final String? profileImageUrl;

  // ── Convenience ─────────────────────────────────────────────────────

  String get fullName => [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  /// `>= 60` is the instructor band. Used to gate the Instructor Bio
  /// section on the profile page.
  bool get isInstructor => (maxRoleLevel ?? 0) >= 60;

  /// `>= 80` is admin. Reserved for future admin-only UI.
  bool get isAdmin => (maxRoleLevel ?? 0) >= 80;

  // ── JSON ────────────────────────────────────────────────────────────

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id:         (j['id'] as num?)?.toInt() ?? 0,
        firstName:  (j['first_name'] ?? '') as String,
        lastName:   (j['last_name']  ?? '') as String,
        email:      (j['email']      ?? '') as String,
        mobile:     (j['mobile']     ?? '') as String,
        roles: (j['roles'] is List)
            ? (j['roles'] as List)
                .whereType<Map<String, dynamic>>()
                .map(AuthRole.fromJson)
                .toList(growable: false)
            : null,
        maxRoleLevel:    (j['max_role_level'] as num?)?.toInt(),
        displayName:     j['display_name'] as String?,
        profileImageUrl: (j['profile_image_url'] ?? j['avatar_url']) as String?,
      );

  Map<String, dynamic> toJson() => {
        'id':                id,
        'first_name':        firstName,
        'last_name':         lastName,
        'email':             email,
        'mobile':            mobile,
        if (roles != null)            'roles':             roles!.map((r) => r.toJson()).toList(),
        if (maxRoleLevel != null)     'max_role_level':    maxRoleLevel,
        if (displayName != null)      'display_name':      displayName,
        if (profileImageUrl != null)  'profile_image_url': profileImageUrl,
      };

  AuthUser copyWith({
    int?    id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobile,
    List<AuthRole>? roles,
    int?    maxRoleLevel,
    String? displayName,
    String? profileImageUrl,
  }) =>
      AuthUser(
        id:               id              ?? this.id,
        firstName:        firstName       ?? this.firstName,
        lastName:         lastName        ?? this.lastName,
        email:            email           ?? this.email,
        mobile:           mobile          ?? this.mobile,
        roles:            roles           ?? this.roles,
        maxRoleLevel:     maxRoleLevel    ?? this.maxRoleLevel,
        displayName:      displayName     ?? this.displayName,
        profileImageUrl:  profileImageUrl ?? this.profileImageUrl,
      );

  @override
  List<Object?> get props => [
        id, firstName, lastName, email, mobile,
        roles, maxRoleLevel, displayName, profileImageUrl,
      ];
}
