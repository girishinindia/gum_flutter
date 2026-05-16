// The auth state machine. Wires AuthRepository events to AuthState
// transitions and subscribes to:
//   • the repository's session changes (login / logout / mutation)
//   • the AuthInterceptor's session-expired stream
//
// Single instance is created in main() and provided to the widget
// tree via BlocProvider so screens can `context.read<AuthBloc>()` /
// `BlocBuilder<AuthBloc, AuthState>`.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repo = repository,
        super(const AuthState.unknown()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLoggedOut>(_onLoggedOut);
    on<AuthUserRefreshed>(_onUserRefreshed);

    // Listen for explicit session changes from the repository (e.g. on
    // updateMe success) — emit a refreshed event into our own queue.
    _sessionSub = _repo.sessionChanges.listen((u) {
      if (u != null) add(AuthUserRefreshed(u));
    });

    // The AuthInterceptor fires this stream when refresh fails — wipe
    // and bounce to /login with `expired: true`.
    _expiredSub = ApiClient.authInterceptor.onSessionExpired.listen((_) {
      add(const AuthLoggedOut(expired: true));
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription _sessionSub;
  late final StreamSubscription _expiredSub;

  Future<void> _onAppStarted(AuthAppStarted e, Emitter<AuthState> emit) async {
    final user = await _repo.bootstrap();
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  void _onLoggedIn(AuthLoggedIn e, Emitter<AuthState> emit) {
    emit(AuthState.authenticated(e.user));
  }

  Future<void> _onLoggedOut(AuthLoggedOut e, Emitter<AuthState> emit) async {
    if (!e.expired) await _repo.logout();
    emit(AuthState.unauthenticated(expired: e.expired));
  }

  void _onUserRefreshed(AuthUserRefreshed e, Emitter<AuthState> emit) {
    // Only meaningful if we're already authenticated — otherwise ignore.
    if (state.status == AuthStatus.authenticated) {
      emit(AuthState.authenticated(e.user));
    }
  }

  @override
  Future<void> close() async {
    await _sessionSub.cancel();
    await _expiredSub.cancel();
    await _repo.dispose();
    return super.close();
  }

  /// Direct accessor for screens that need to call into the repo
  /// without going through the event bus (e.g. login form submit).
  AuthRepository get repository => _repo;
}
