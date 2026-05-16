// Events that drive the AuthBloc state machine.
//
// Only "things that happen in the outside world" become events:
//   • App-level lifecycle (cold start)
//   • User actions (login submit, logout tap)
//   • Side-effect signals (session expired from the interceptor)
//
// Multi-step flows (OTP verify cycle, forgot-password) DON'T fan out
// into bloc events — they live as one-shot async calls on the
// AuthRepository invoked directly by the screen, and only success/
// failure ends up emitted as a high-level event here. This keeps the
// bloc small (3 states, 4 events) and the wide-open OTP screens
// remain plain stateful widgets driven by FutureBuilder-style logic.

import 'package:equatable/equatable.dart';

import '../domain/auth_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => const [];
}

/// Fired once by main() after wiring providers — kicks off bootstrap
/// (hydrate cached user + refresh against the server).
class AuthAppStarted extends AuthEvent {
  const AuthAppStarted();
}

/// Fired by the login screen on a successful API response (or by the
/// OTP-complete branch in verifyRegisterOtp).
class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.user);
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}

/// Fired by the user-menu "Sign out" item and by the AuthInterceptor
/// session-expired stream.
class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut({this.expired = false});
  final bool expired;
  @override
  List<Object?> get props => [expired];
}

/// Fired after PATCH /users/me to keep the bloc's cached user in sync
/// with the source of truth.
class AuthUserRefreshed extends AuthEvent {
  const AuthUserRefreshed(this.user);
  final AuthUser user;
  @override
  List<Object?> get props => [user];
}
