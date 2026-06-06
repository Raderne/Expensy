import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/auth_user.dart';

class AuthStorage {
  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _kUserId = 'auth.user.id';
  static const _kUserEmail = 'auth.user.email';
  static const _kUserName = 'auth.user.name';

  final FlutterSecureStorage _store;
  const AuthStorage(this._store);

  Future<String?> readAccess() => _store.read(key: _kAccess);
  Future<String?> readRefresh() => _store.read(key: _kRefresh);

  Future<AuthUser?> readUser() async {
    final id = await _store.read(key: _kUserId);
    final email = await _store.read(key: _kUserEmail);
    final name = await _store.read(key: _kUserName);
    if (id == null || email == null || name == null) return null;
    return AuthUser(id: id, email: email, name: name);
  }

  Future<void> writeSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await Future.wait([
      _store.write(key: _kAccess, value: accessToken),
      _store.write(key: _kRefresh, value: refreshToken),
      _store.write(key: _kUserId, value: user.id),
      _store.write(key: _kUserEmail, value: user.email),
      _store.write(key: _kUserName, value: user.name),
    ]);
  }

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _store.write(key: _kAccess, value: accessToken),
      _store.write(key: _kRefresh, value: refreshToken),
    ]);
  }

  Future<void> writeUser(AuthUser user) async {
    await Future.wait([
      _store.write(key: _kUserId, value: user.id),
      _store.write(key: _kUserEmail, value: user.email),
      _store.write(key: _kUserName, value: user.name),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _store.delete(key: _kAccess),
      _store.delete(key: _kRefresh),
      _store.delete(key: _kUserId),
      _store.delete(key: _kUserEmail),
      _store.delete(key: _kUserName),
    ]);
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) {
  return const AuthStorage(FlutterSecureStorage());
});
