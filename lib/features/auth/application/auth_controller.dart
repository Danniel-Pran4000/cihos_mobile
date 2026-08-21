import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

/// Who is signed in, if anyone. Null means signed out.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
    this.isRestoring = false,
  });

  final AppUser? user;
  final bool isLoading;
  final String? error;

  /// Per-field messages from the server, keyed by API field name
  /// (`email`, `password`, `nik`, `phone`, `dob`, `name`).
  final Map<String, List<String>> fieldErrors;

  /// True while the stored session is being checked at startup.
  final bool isRestoring;

  bool get isSignedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    Map<String, List<String>>? fieldErrors,
    bool? isRestoring,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
      isRestoring: isRestoring ?? this.isRestoring,
    );
  }

  /// The server's message for [field], if it rejected that field.
  String? errorFor(String field) => fieldErrors[field]?.firstOrNull;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  /// Restores a stored session, if the token is still valid.
  Future<void> restoreSession() async {
    state = state.copyWith(isRestoring: true);
    try {
      final user = await _repository.restore();
      state = AuthState(user: user);
    } on ApiException {
      // Startup must not block on a server that is unreachable; the user can
      // still sign in once connectivity returns.
      state = const AuthState();
    }
  }

  /// Signs in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  /// Creates an account. NIK is collected here only, never at sign-in.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String nik,
    required String phone,
    required DateTime birthDate,
    Gender? gender,
  }) async {
    return _run(
      () => _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        nik: nik,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
      ),
    );
  }

  /// Updates the currently signed-in user's profile and persists it.
  Future<bool> updateProfile(AppUser user) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _repository.updateProfile(user);
      state = state.copyWith(user: updatedUser, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }

  /// Shared loading/error handling for the two calls that produce a session.
  Future<bool> _run(Future<AppUser> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = AuthState(user: await action());
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
