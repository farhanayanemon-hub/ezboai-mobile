import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/credit_balance.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool requiresOtp;
  final String? pendingOtpEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.requiresOtp = false,
    this.pendingOtpEmail,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? requiresOtp,
    String? pendingOtpEmail,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      requiresOtp: requiresOtp ?? this.requiresOtp,
      pendingOtpEmail: pendingOtpEmail ?? this.pendingOtpEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api = ApiClient();

  AuthNotifier() : super(const AuthState()) {
    checkSession();
  }

  // Check persisted session on app startup
  Future<void> checkSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final hasToken = await SecureStorageService.hasToken();
    if (!hasToken) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return;
    }

    try {
      final response = await _api.get(ApiEndpoints.mobileMe);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'];
        final creditsData = response.data['credits'];
        final user = UserModel.fromJson(
          userData,
          creditsData != null ? CreditBalance.fromJson(creditsData) : null,
        );
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
      } else {
        await SecureStorageService.clearAuth();
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      // Offline fallback: keep token but set error
      state = state.copyWith(isLoading: false, isAuthenticated: true);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.mobileLogin,
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] as String;
        await SecureStorageService.saveToken(token);

        final user = UserModel.fromJson(
          data['user'],
          data['credits'] != null ? CreditBalance.fromJson(data['credits']) : null,
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data?['error'] ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      String msg = 'Login failed. Please check your credentials.';
      if (e.toString().contains('requiresOtp') || e.toString().contains('Email verification required')) {
        state = state.copyWith(
          isLoading: false,
          requiresOtp: true,
          pendingOtpEmail: email.trim(),
        );
        return false;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  // Google OAuth Login
  Future<bool> loginWithGoogle({
    String? idToken,
    String? email,
    String? name,
    String? picture,
    String? googleId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.mobileGoogleLogin,
        data: {
          if (idToken != null) 'idToken': idToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (picture != null) 'picture': picture,
          if (googleId != null) 'googleId': googleId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final token = data['token'] as String;
        await SecureStorageService.saveToken(token);

        final user = UserModel.fromJson(
          data['user'],
          data['credits'] != null ? CreditBalance.fromJson(data['credits']) : null,
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data?['error'] ?? 'Google authentication failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign in failed. Please try again.',
      );
      return false;
    }
  }

  // Register
  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.mobileRegister,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['requiresOtp'] == true) {
          state = state.copyWith(
            isLoading: false,
            requiresOtp: true,
            pendingOtpEmail: email.trim(),
          );
          return false;
        }

        final token = data['token'] as String;
        await SecureStorageService.saveToken(token);
        final user = UserModel.fromJson(
          data['user'],
          data['credits'] != null ? CreditBalance.fromJson(data['credits']) : null,
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data?['error'] ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration error. Please try again.');
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.mobileVerifyOtp,
        data: {'email': email.trim(), 'code': code.trim()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] as String;
        await SecureStorageService.saveToken(token);

        final user = UserModel.fromJson(
          data['user'],
          data['credits'] != null ? CreditBalance.fromJson(data['credits']) : null,
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          requiresOtp: false,
          pendingOtpEmail: null,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data?['error'] ?? 'Invalid verification code',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed. Try again.');
      return false;
    }
  }

  // Resend OTP
  Future<bool> resendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.mobileResendOtp,
        data: {'email': email.trim()},
      );

      state = state.copyWith(isLoading: false);
      if (response.statusCode == 200) {
        return true;
      } else {
        state = state.copyWith(
          error: response.data?['error'] ?? 'Failed to resend verification code',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send new code. Try again.');
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.post(
        ApiEndpoints.mobileForgotPassword,
        data: {'email': email.trim()},
      );

      state = state.copyWith(isLoading: false);
      if (response.statusCode == 200) {
        return true;
      } else {
        state = state.copyWith(
          error: response.data?['error'] ?? 'Failed to send password reset instructions',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error. Please try again later.',
      );
      return false;
    }
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? profession,
    String? personalInstructions,
    String? image,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _api.patch(
        ApiEndpoints.mobileMe,
        data: {
          if (name != null) 'name': name,
          if (profession != null) 'profession': profession,
          if (personalInstructions != null) 'personalInstructions': personalInstructions,
          if (image != null) 'image': image,
        },
      );

      if (response.statusCode == 200 && response.data['user'] != null) {
        final updated = UserModel.fromJson(response.data['user'], state.user?.credits);
        state = state.copyWith(isLoading: false, user: updated);
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false, error: 'Failed to update profile');
    return false;
  }

  // Refresh profile & credits
  Future<void> refreshProfile() async {
    try {
      final response = await _api.get(ApiEndpoints.mobileMe);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['user'];
        final creditsData = response.data['credits'];
        final user = UserModel.fromJson(
          userData,
          creditsData != null ? CreditBalance.fromJson(creditsData) : null,
        );
        state = state.copyWith(user: user);
      }
    } catch (_) {}
  }

  // Logout
  Future<void> logout() async {
    await SecureStorageService.clearAuth();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
