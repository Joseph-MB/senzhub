import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient get _client => SupabaseService.client;

  Stream<AuthState> get authStateChanges =>
      SupabaseService.isInitialized
          ? _client.auth.onAuthStateChange
          : const Stream.empty();

  User? get currentUser =>
      SupabaseService.isInitialized ? _client.auth.currentUser : null;

  Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? avatarUrl,
  }) async {
    // Build metadata map — only include avatarUrl when provided.
    final data = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
    };
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    // The database trigger handle_new_user() automatically inserts into
    // public.profiles using raw_user_meta_data. Do NOT manually insert here.
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sends a password reset email to [email].
  /// Optionally accepts [redirectTo] URL (defaults to origin web app URL).
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo ?? (kIsWeb ? Uri.base.origin : null),
    );
  }

  /// Requests an SMS OTP for phone number verification/password recovery.
  Future<void> requestPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
      shouldCreateUser: false, // Ensures we only send to existing users.
    );
  }

  /// Verifies the SMS OTP and establishes a session.
  Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Updates the password for the current user or recovery session user.
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Ensures the signed-in user has a personal organization by calling a
  /// secure server-side RPC. The RPC runs as SECURITY DEFINER on the server,
  /// so no privileged client credentials are needed.
  Future<void> ensurePersonalOrganization() async {
    try {
      await _client.rpc('create_personal_organization');
    } catch (e) {
      debugPrint('[AuthService] ensurePersonalOrganization failed: $e');
    }
  }

  /// Calls the secure edge function to delete the authenticated user's account.
  /// Handles session cleanup on success.
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke(
      'delete-account',
      method: HttpMethod.post,
    );
    // supabase_flutter v2: check HTTP status, not .error
    final status = response.status;
    if (status < 200 || status >= 300) {
      throw Exception(
        'Account deletion failed (HTTP $status). Please try again.',
      );
    }
    await signOut();
  }

  /// Provides clean, user-facing error messages for Auth exceptions.
  static String formatAuthError(dynamic error) {
    if (error is AuthException) {
      final message = error.message;
      if (message.contains('Invalid login credentials')) {
        return 'Invalid email or password. Please check your credentials.';
      }
      if (message.contains('Email not confirmed')) {
        return 'Email not confirmed. Please check your inbox and confirm your account.';
      }
      if (message.contains('User already registered') || message.contains('already exists')) {
        return 'An account with this email address already exists.';
      }
      if (message.contains('Password should be at least')) {
        return 'Password must be at least 6 characters long.';
      }
      if (message.contains('rate limit') || error.statusCode == '429') {
        return 'Too many attempts. Please try again in a few minutes.';
      }
      return message;
    }
    final str = error.toString();
    if (str.contains('SocketException') || str.contains('ClientException')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
