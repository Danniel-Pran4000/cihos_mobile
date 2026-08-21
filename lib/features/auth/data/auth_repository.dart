import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_store.dart';
import '../domain/user.dart';

/// Sign-in, registration, and session restore against `/api/app/*`.
///
/// Owns the bearer token: it is written on a successful sign-in and cleared on
/// sign-out, so nothing above this layer has to think about it.
class AuthRepository {
  const AuthRepository({required ApiClient client, required TokenStore tokens})
    : _client = client,
      _tokens = tokens;

  final ApiClient _client;
  final TokenStore _tokens;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Signs in with email and password. Throws [ApiException] on failure.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/app/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _persist(response);
  }

  /// Creates an account. [nik] is only collected here — sign-in uses email.
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String nik,
    required String phone,
    required DateTime birthDate,
    Gender? gender,
  }) async {
    final response = await _client.post(
      '/app/register',
      body: {
        'name': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
        'nik': nik.trim(),
        'phone': phone.trim(),
        'dob': _dateFormat.format(birthDate),
        if (gender != null)
          'gender': gender == Gender.male ? 'Laki-laki' : 'Perempuan',
      },
    );
    return _persist(response);
  }

  /// Returns the signed-in patient, or null when there is no valid session.
  ///
  /// Called at startup to decide whether to show the app or the sign-in screen.
  Future<AppUser?> restore() async {
    if (await _tokens.read() == null) return null;

    try {
      final response = await _client.get('/app/me', authenticated: true);
      final user = AppUser.fromJson(
        (response['patient'] as Map).cast<String, dynamic>(),
      );
      final localUser = await _tokens.readUser();
      final mergedUser = user.copyWith(
        photoUrl: localUser?.photoUrl ?? user.photoUrl,
        address: localUser?.address ?? user.address,
      );
      await _tokens.writeUser(mergedUser);
      return mergedUser;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await _tokens.clear();
        return null;
      }
      return await _tokens.readUser();
    } catch (_) {
      return await _tokens.readUser();
    }
  }

  /// Updates the user's profile and persists it locally.
  Future<AppUser> updateProfile(AppUser user) async {
    await _tokens.writeUser(user);
    return user;
  }

  /// Revokes the token server-side, then forgets it locally.
  Future<void> signOut() async {
    try {
      await _client.post('/app/logout', authenticated: true);
    } on ApiException {
      // The local session must end even when the call fails — the user asked
      // to sign out, and an expired token would fail here anyway.
    } finally {
      await _tokens.clear();
    }
  }

  Future<AppUser> _persist(Map<String, dynamic> response) async {
    final token = response['token'] as String?;
    if (token != null) await _tokens.write(token);
    final user = AppUser.fromJson(
      (response['patient'] as Map).cast<String, dynamic>(),
    );
    await _tokens.writeUser(user);
    return user;
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    client: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
  ),
);
