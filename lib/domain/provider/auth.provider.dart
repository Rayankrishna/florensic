import 'package:dio/dio.dart';

import '../core/api_response.dart';
import '../core/services_config.dart';

/// `/v1/auth/*` and `/v1/me`.
///
/// Every method has the same shape, as in the lead app: the URL, one Dio
/// call, the body on success, `http!.parseError` on failure. Nothing here
/// throws — the store reads `resp.ok` and `resp.message` — so a breakpoint
/// on any `return` shows exactly what the server sent.
class AuthProvider {
  const AuthProvider();

  Future<ApiResponse> signIn(String email, String password) async {
    const url = '/auth/sign-in';
    try {
      final resp = await http!.authService.post<dynamic>(
        url,
        data: {'email': email, 'password': password},
        options: HttpClient.unauthenticated,
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// Answers 202 with no tokens: the account exists and an OTP is on its way.
  Future<ApiResponse> signUp(String name, String email, String password) async {
    const url = '/auth/sign-up';
    try {
      final resp = await http!.authService.post<dynamic>(
        url,
        data: {'name': name, 'email': email, 'password': password},
        options: HttpClient.unauthenticated,
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// `purpose` is `signup`, `signin` or `reset` — the backend sends a
  /// different code for each.
  Future<ApiResponse> requestOtp(String email, {String purpose = 'signin'}) async {
    const url = '/auth/otp/request';
    try {
      final resp = await http!.authService.post<dynamic>(
        url,
        data: {'email': email, 'purpose': purpose},
        options: HttpClient.unauthenticated,
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// Returns a token pair on success.
  Future<ApiResponse> verifyOtp(String email, String code) async {
    const url = '/auth/otp/verify';
    try {
      final resp = await http!.authService.post<dynamic>(
        url,
        data: {'email': email, 'code': code},
        options: HttpClient.unauthenticated,
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// Consumes a `reset` code and sets the new password. 204, no session.
  Future<ApiResponse> resetPassword(
      String email, String code, String newPassword) async {
    const url = '/auth/password/reset';
    try {
      final resp = await http!.authService.post<dynamic>(
        url,
        data: {'email': email, 'code': code, 'new_password': newPassword},
        options: HttpClient.unauthenticated,
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// Rotates the token pair and saves it, through the client's coalesced
  /// refresh. True when a new pair is in the keychain.
  Future<bool> refreshSession() => http!.refreshSession();

  Future<ApiResponse> signOut(String? refreshToken) async {
    const url = '/auth/sign-out';
    try {
      final resp = await http!.authService.post<dynamic>(
        url,
        data: {'refresh_token': ?refreshToken},
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// The profile plus the server-computed stats.
  Future<ApiResponse> me() async {
    const url = '/me';
    try {
      final resp = await http!.authService.get<dynamic>(url);
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// `{name?, city?, units?, reminder_time?, timezone?, consent_training?}`.
  Future<ApiResponse> updateMe(Map<String, Object?> changes) async {
    const url = '/me';
    try {
      final resp = await http!.authService.patch<dynamic>(url, data: changes);
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }

  /// Stores the push token. Nothing is sent yet (§7 of the API guide).
  Future<ApiResponse> registerDevice(String platform, String pushToken) async {
    const url = '/me/devices';
    try {
      final resp = await http!.authService.put<dynamic>(
        url,
        data: {'platform': platform, 'push_token': pushToken},
      );
      return ApiResponse.success(resp.data);
    } on DioException catch (e) {
      return ApiResponse.failure(http!.parseError(e));
    }
  }
}
