import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'attendance_provider.dart';
import 'history_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isCheckingSession;
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String? errorMessage;

  bool get requiresOnboarding =>
      isAuthenticated && (user?.mustChangePassword ?? false);

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
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Register auto-logout on unauthorized (401)
    ApiClient.onUnauthorized = () {
      logout();
    };

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
        state = state.copyWith(isAuthenticated: true, user: cachedUser);
      }

      // Refresh latest profile from backend
      final freshProfile = await _repository.getProfile();
      state = state.copyWith(
        isCheckingSession: false,
        isAuthenticated: true,
        user: freshProfile,
      );
    } catch (e) {
      final isUnauthorized = e is ApiException && e.statusCode == 401;
      if (isUnauthorized) {
        // Expired or revoked token: reset session cleanly to login screen
        await logout();
        return;
      }
      state = state.copyWith(
        isCheckingSession: false,
        isAuthenticated: state.user != null,
        errorMessage: state.user == null ? _formatErrorMessage(e) : null,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);

      // Clear image caches from prior sessions
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    // 1. Immediately reset state to unauthenticated so UI redirects to LoginScreen without waiting
    state = const AuthState(
      isCheckingSession: false,
      isAuthenticated: false,
      isLoading: false,
      user: null,
    );

    // 2. Clear image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // 3. Reset in-memory attendance and history states
    try {
      ref.read(todayAttendanceProvider.notifier).reset();
      ref.read(historyProvider.notifier).reset();
    } catch (_) {}

    // 4. Clear storage and notify backend
    try {
      await _repository.logout();
    } catch (_) {}
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
        errorMessage: _formatErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> updateOnboardingPassword({
    required String password,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _repository.updateOnboardingPassword(
        password: password,
        passwordConfirmation: confirmPassword,
      );
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> updateProfile({String? phone, File? avatarFile}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateProfile(
        phone: phone,
        avatarFile: avatarFile,
      );
      state = state.copyWith(isLoading: false, user: updated);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatErrorMessage(e),
      );
      return false;
    }
  }

  void cancelSessionCheck() {
    state = state.copyWith(isCheckingSession: false, isAuthenticated: false);
  }
}

String _formatErrorMessage(Object error) {
  final str = error.toString();
  return str.startsWith('Exception: ') ? str.substring(11) : str;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
