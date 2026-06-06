import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/auth_storage.dart';
import '../domain/auth_state.dart';
import '../domain/auth_user.dart';

/// Owns the AuthState lifecycle. Persists tokens via [AuthStorage] and exposes
/// signup/login/logout entry points. Initial build() rehydrates from storage,
/// so the app stays logged in across restarts.
class AuthController extends AsyncNotifier<AuthState> {
  AuthStorage get _storage => ref.read(authStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final access = await _storage.readAccess();
    final user = await _storage.readUser();
    if (access == null || user == null) return const AuthUnauthenticated();
    return AuthAuthenticated(user);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    try {
      final session = await _repo.signup(
        email: email,
        password: password,
        name: name,
      );
      await _storage.writeSession(
        accessToken: session.tokens.accessToken,
        refreshToken: session.tokens.refreshToken,
        user: session.user,
      );
      state = AsyncData(AuthAuthenticated(session.user));
    } catch (e, st) {
      state = const AsyncData(AuthUnauthenticated());
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final session = await _repo.login(email: email, password: password);
      await _storage.writeSession(
        accessToken: session.tokens.accessToken,
        refreshToken: session.tokens.refreshToken,
        user: session.user,
      );
      state = AsyncData(AuthAuthenticated(session.user));
    } catch (e, st) {
      state = const AsyncData(AuthUnauthenticated());
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> logout() async {
    await _storage.clear();
    state = const AsyncData(AuthUnauthenticated());
  }

  /// Replaces the cached user (e.g. after a profile edit). Persists the new
  /// values to secure storage so the next cold-start sees the updated name.
  Future<void> updateUser(AuthUser user) async {
    await _storage.writeUser(user);
    state = AsyncData(AuthAuthenticated(user));
  }

  /// Called by the auth interceptor when refresh fails and the user must
  /// be bounced back to /login.
  Future<void> onTokensInvalidated() async {
    state = const AsyncData(AuthUnauthenticated());
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
