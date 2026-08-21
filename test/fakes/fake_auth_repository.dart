import 'package:cihos_mobile/core/network/api_exception.dart';
import 'package:cihos_mobile/features/auth/data/auth_repository.dart';
import 'package:cihos_mobile/features/auth/domain/user.dart';

/// An [AuthRepository] that answers from memory instead of the network.
///
/// Widget tests must not depend on a reachable server: the hospital API is on
/// an internal network, and a test that fails when the VPN is down tells you
/// nothing about the code. This stands in for it, reproducing the server's
/// contract closely enough that the screens behave the same — including the
/// deliberate ambiguity between "wrong password" and "no such account".
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.startSignedIn = false});

  /// When true, [restore] returns a user, as if a valid token were stored.
  final bool startSignedIn;

  /// The one account these tests can sign into.
  static const email = 'pasien@example.com';
  static const password = 'password123';

  static final user = AppUser(
    id: '1',
    fullName: 'Pasien Cihos',
    email: email,
    phone: '081234567890',
    medicalNo: 'APP-000001',
    birthDate: DateTime(1998, 5, 14),
    gender: Gender.female,
  );

  /// Records what was sent, so tests can assert on the request.
  final List<Map<String, Object?>> registrations = [];

  bool _signedOut = false;
  AppUser _currentUser = user;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim() != FakeAuthRepository.email ||
        password != FakeAuthRepository.password) {
      throw const ApiException(
        message: 'Email atau password salah.',
        code: 'invalid_credentials',
        statusCode: 401,
      );
    }
    _signedOut = false;
    return _currentUser;
  }

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String nik,
    required String phone,
    required DateTime birthDate,
    Gender? gender,
  }) async {
    if (email.trim() == FakeAuthRepository.email) {
      throw const ApiException(
        message: 'Data yang dikirim tidak valid.',
        code: 'validation_failed',
        statusCode: 422,
        fieldErrors: {
          'email': ['Email sudah terdaftar.'],
        },
      );
    }

    registrations.add({
      'name': fullName,
      'email': email,
      'nik': nik,
      'phone': phone,
      'dob': birthDate,
      'gender': gender,
    });

    _currentUser = _currentUser.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
    );
    return _currentUser;
  }

  @override
  Future<AppUser?> restore() async =>
      startSignedIn && !_signedOut ? _currentUser : null;

  @override
  Future<AppUser> updateProfile(AppUser updatedUser) async {
    _currentUser = updatedUser;
    return _currentUser;
  }

  @override
  Future<void> signOut() async => _signedOut = true;
}
