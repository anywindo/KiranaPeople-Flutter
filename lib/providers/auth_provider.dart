import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isCheckingSession;
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    this.isCheckingSession = true,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isCheckingSession,
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isCheckingSession: isCheckingSession ?? this.isCheckingSession,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    // Asynchronously check session on initialization
    Future.microtask(() => checkSession());
    return const AuthState(isCheckingSession: true);
  }

  Future<void> checkSession() async {
    state = state.copyWith(isCheckingSession: true, clearError: true);
    try {
      final hasToken = await _repository.hasValidToken();
      if (!hasToken) {
        state = state.copyWith(
          isCheckingSession: false,
          isAuthenticated: false,
          user: null,
        );
        return;
      }

      // Check cached user first for instant display
      final cachedUser = await _repository.getCachedUser();
      if (cachedUser != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: cachedUser,
        );
      }

      // Refresh latest profile from backend
      final freshProfile = await _repository.getProfile();
      state = state.copyWith(
        isCheckingSession: false,
        isAuthenticated: true,
        user: freshProfile,
      );
    } catch (e) {
      state = state.copyWith(
        isCheckingSession: false,
        isAuthenticated: state.user != null,
        errorMessage: state.user == null ? e.toString() : null,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(
      isCheckingSession: false,
      isAuthenticated: false,
      isLoading: false,
      user: null,
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    String? phone,
    File? avatarFile,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateProfile(
        phone: phone,
        avatarFile: avatarFile,
      );
      state = state.copyWith(
        isLoading: false,
        user: updated,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void cancelSessionCheck() {
    state = state.copyWith(
      isCheckingSession: false,
      isAuthenticated: false,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
