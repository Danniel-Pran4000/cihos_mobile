import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/user.dart';

/// Keeps the patient's bearer token and user profile data between launches.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'cihos_auth_token';
  static const _userKey = 'cihos_user_data';

  final FlutterSecureStorage _storage;

  /// Cached in memory so repeated calls do not hit the keystore each request.
  String? _cached;
  bool _hasRead = false;

  AppUser? _cachedUser;
  bool _hasReadUser = false;

  Future<String?> read() async {
    if (_hasRead) return _cached;
    _cached = await _storage.read(key: _key);
    _hasRead = true;
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _hasRead = true;
    await _storage.write(key: _key, value: token);
  }

  Future<AppUser?> readUser() async {
    if (_hasReadUser) return _cachedUser;
    final jsonStr = await _storage.read(key: _userKey);
    if (jsonStr != null) {
      try {
        _cachedUser = AppUser.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    _hasReadUser = true;
    return _cachedUser;
  }

  Future<void> writeUser(AppUser user) async {
    _cachedUser = user;
    _hasReadUser = true;
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    _cachedUser = null;
    _hasRead = true;
    _hasReadUser = true;
    await _storage.delete(key: _key);
    await _storage.delete(key: _userKey);
  }
}
