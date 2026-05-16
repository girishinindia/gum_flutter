// One role assignment surfaced from `v_user_profile` (joined from
// `user_roles` + `roles`). A user can hold multiple roles concurrently;
// `max_role_level` (on AuthUser) collapses them into a single
// comparable number for visibility gating.
//   ≥ 60 = instructor
//   ≥ 80 = admin

import 'package:equatable/equatable.dart';

class AuthRole extends Equatable {
  const AuthRole({
    required this.role,
    required this.displayName,
    required this.level,
  });

  final String role;          // 'student' | 'instructor' | 'admin' | ...
  final String displayName;
  final int    level;         // 0–100 — higher = more privileged

  factory AuthRole.fromJson(Map<String, dynamic> j) => AuthRole(
        role:        (j['role'] ?? '') as String,
        displayName: (j['display_name'] ?? '') as String,
        level:       (j['level'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'role':         role,
        'display_name': displayName,
        'level':        level,
      };

  @override
  List<Object?> get props => [role, displayName, level];
}
