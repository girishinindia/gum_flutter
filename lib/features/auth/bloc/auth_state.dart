// AuthBloc state machine — three terminal states.
//
//   unknown          — bootstrap not yet finished (router shows splash)
//   unauthenticated  — bootstrap done, no valid session (router → /login)
//   authenticated    — live session in hand (router → /home)
//
// The router redirects entirely off `status`. Specific screens that
// need the user object reach into `user` directly.

import 'package:equatable/equatable.dart';

import '../domain/auth_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.expired = false});

  /// Bootstrap not yet finished — router holds at /.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  /// Live session in hand.
  const AuthState.authenticated(AuthUser u)
      : this._(status: AuthStatus.authenticated, user: u);

  /// Bootstrap done, no valid session. `expired: true` signals the
  /// transition came from the AuthInterceptor's refresh-failed stream
  /// (vs. an explicit logout) so the login screen can show a banner.
  const AuthState.unauthenticated({bool expired = false})
      : this._(status: AuthStatus.unauthenticated, expired: expired);

  final AuthStatus status;
  final AuthUser?  user;
  /// True when the last transition to `unauthenticated` was caused by
  /// the server invalidating the refresh token (vs. an explicit logout).
  /// Lets the login screen show "Session expired — please sign in again."
  final bool expired;

  @override
  List<Object?> get props => [status, user, expired];
}
