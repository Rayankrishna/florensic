import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../interceptors/api_interceptor.dart';
import '../../utils/app_log.dart';
import 'token_store.dart';

/// Base URL for the Florensic API.
///
/// Override per build with
/// `--dart-define=API_BASE_URL=https://api.florensic.example`. Phones and
/// emulators — Android or iOS — use the test server (plain HTTP until it has
/// a certificate; the debug manifest and Info.plist allow that): `localhost`
/// on a device is the device itself. Web and desktop run on the same machine
/// as the local stack, so they keep `localhost`.
String get serverUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return testServerUrl;
  }
  return 'http://localhost:8010';
}

/// The shared test server (hand-off of 2026-10-07). Replaces the ngrok
/// tunnel; images load from it without any tunnel.
const String testServerUrl = 'http://13.202.212.73:8012';

/// Every route sits under this prefix.
const String apiVersion = '/v1';

/// Process-wide client, as in the lead app. Providers reach Dio through
/// `http!.authService` and turn a failure into a message with
/// `http!.parseError(e)`.
HttpClient? http;

/// The Dio instance plus the two things every call needs: the bearer token
/// (attached by an interceptor, refreshed once when it has expired) and the
/// backend's error envelope mapped to an [ApiException].
///
/// In debug builds every request and response is logged with its timing, so
/// a failing call can be read straight off the console.
class HttpClient {
  HttpClient({required this.authService, required this._tokens});

  final Dio authService;
  final TokenStore _tokens;

  /// Called when the session is beyond saving, so the app can sign out.
  VoidCallback? onSessionExpired;

  Future<void>? _refreshing;

  /// `options.extra` flag that tells the auth interceptor not to attach a
  /// token — for sign-in, OTP and the public catalogue.
  static const String noAuthKey = 'noAuth';
  static const String _retriedKey = 'retriedAfterRefresh';

  /// Options for a call that must not carry a bearer token.
  static Options get unauthenticated =>
      Options(extra: const {noAuthKey: true});

  factory HttpClient.init({required TokenStore tokens}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: '$serverUrl$apiVersion',
        connectTimeout: const Duration(seconds: 100),
        receiveTimeout: const Duration(seconds: 200),
        receiveDataWhenStatusError: true,
        headers: const {'Accept': 'application/json'},
      ),
    );
    final client = HttpClient(authService: dio, tokens: tokens);
    dio.interceptors
      ..add(client._authInterceptor())
      ..add(_DebugLogInterceptor());
    http = client;
    return client;
  }

  // ── Interceptors ─────────────────────────────────────────────────────────

  /// Bearer token on every call that wants one; one silent refresh when the
  /// server says `token_expired`, then the call is retried; the end of the
  /// session on any other 401 outside `/auth/*`.
  Interceptor _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokens.current?.accessToken;
          if (options.extra[noAuthKey] != true && token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final options = e.requestOptions;
          final status = e.response?.statusCode;
          if (status != 401 ||
              options.path.startsWith('/auth/') ||
              options.extra[noAuthKey] == true) {
            return handler.next(e);
          }

          if (_codeOf(e) == 'token_expired' &&
              options.extra[_retriedKey] != true) {
            try {
              await _refreshTokens();
            } catch (_) {
              // Refused or unreachable; the call fails with its own 401.
              return handler.next(e);
            }
            options.extra[_retriedKey] = true;
            try {
              return handler.resolve(await authService.fetch<dynamic>(options));
            } on DioException catch (retry) {
              return handler.next(retry);
            }
          }

          // A 401 a refresh cannot rescue: the session is over.
          _endSession();
          handler.next(e);
        },
      );

  /// Rotates the token pair now and saves it to the keychain.
  ///
  /// For the launch path: a 15-minute access token has almost always expired
  /// by the next launch, so the store refreshes up front rather than letting
  /// the first call trip over a 401. Returns true when a new pair is saved.
  /// On false, the session has been ended only if the server refused the
  /// refresh token; a network failure leaves the saved pair alone.
  Future<bool> refreshSession() async {
    try {
      await _refreshTokens();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Coalesces concurrent callers onto one refresh so a screen firing several
  /// calls does not rotate the token several times.
  Future<void> _refreshTokens() {
    return _refreshing ??=
        _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _doRefresh() async {
    final refresh = _tokens.current?.refreshToken;
    if (refresh == null) {
      _endSession();
      throw StateError('no refresh token');
    }

    final Response<dynamic> response;
    try {
      response = await authService.post<dynamic>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: unauthenticated,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // The server refused the token (rotated already, revoked, malformed):
      // the session is over. Anything else — offline, a timeout, a 5xx —
      // keeps the saved pair so the next launch can try again.
      final refused = status != null && status >= 400 && status < 500 &&
          status != 429;
      if (refused) {
        AppLog.w('refresh token refused (${_codeOf(e) ?? status}); signing out',
            name: 'api');
        _endSession();
      } else {
        AppLog.w(
          'token refresh failed (${_codeOf(e) ?? e.type.name}); keeping the '
          'saved pair',
          name: 'api',
        );
      }
      rethrow;
    }

    final TokenPair pair;
    try {
      pair = TokenPair.fromJson(Map<String, dynamic>.from(response.data as Map));
    } catch (e) {
      // A 200 we cannot read is a client bug, not a dead session.
      AppLog.e('refresh response unreadable: ${response.data}',
          name: 'api', error: e);
      rethrow;
    }
    await _tokens.save(pair);
    AppLog.i(
      'access token refreshed and saved; expires ${pair.expiresAt.toLocal()}',
      name: 'api',
    );
  }

  void _endSession() {
    unawaited(_tokens.clear());
    onSessionExpired?.call();
  }

  // ── Helpers for the typed providers ──────────────────────────────────────
  //
  // Plants, species, insights and photos go through these: one Dio call,
  // `parse` on the body, `parseError` thrown on failure. [auth] false skips
  // the bearer token.

  Future<T> get<T>(
    String path,
    T Function(dynamic json) parse, {
    Map<String, Object?> query = const {},
    bool auth = true,
  }) =>
      request(path, parse, method: 'GET', query: query, auth: auth);

  Future<T> post<T>(
    String path,
    T Function(dynamic json) parse, {
    Object? body,
    Map<String, Object?> query = const {},
    bool auth = true,
  }) =>
      request(path, parse, method: 'POST', body: body, query: query, auth: auth);

  Future<T> put<T>(String path, T Function(dynamic json) parse,
          {Object? body, bool auth = true}) =>
      request(path, parse, method: 'PUT', body: body, auth: auth);

  Future<T> patch<T>(String path, T Function(dynamic json) parse,
          {Object? body, bool auth = true}) =>
      request(path, parse, method: 'PATCH', body: body, auth: auth);

  Future<T> delete<T>(
    String path,
    T Function(dynamic json) parse, {
    Map<String, Object?> query = const {},
    bool auth = true,
  }) =>
      request(path, parse, method: 'DELETE', query: query, auth: auth);

  Future<T> request<T>(
    String path,
    T Function(dynamic json) parse, {
    String method = 'GET',
    Object? body,
    Map<String, Object?> query = const {},
    bool auth = true,
  }) async {
    try {
      final response = await authService.request<dynamic>(
        path,
        data: body,
        queryParameters: {
          for (final entry in query.entries)
            if (entry.value != null) entry.key: entry.value,
        },
        options: Options(
          method: method,
          contentType: body is FormData ? null : Headers.jsonContentType,
          extra: {noAuthKey: !auth},
        ),
      );
      return parse(response.data);
    } on DioException catch (e) {
      throw parseError(e);
    }
  }

  // ── Errors ───────────────────────────────────────────────────────────────

  static String? _codeOf(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return (data['error'] as Map)['code'] as String?;
    }
    return null;
  }

  /// Turns a transport or envelope failure into a message the UI already
  /// knows how to show, keeping the backend's stable `code` for the stores.
  ApiException parseError(DioException error) {
    if (error.response == null) {
      final message = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'The server is taking too long to respond. Please try again.',
        DioExceptionType.connectionError =>
          "Can't reach the server. Check your internet connection.",
        _ => 'Something went wrong. Check your internet connection.',
      };
      final code = error.type == DioExceptionType.connectionError
          ? 'offline'
          : 'network';
      return ApiException(message, code: code);
    }

    final status = error.response!.statusCode;
    final data = error.response!.data;
    String? message;
    String? code;
    if (data is Map && data['error'] is Map) {
      final envelope = data['error'] as Map;
      final m = envelope['message'];
      final c = envelope['code'];
      if (m is String && m.isNotEmpty) message = m;
      if (c is String && c.isNotEmpty) code = c;
    }

    if (status == 401 && code != 'token_expired') {
      return ApiException(
        _messageFor(code) ??
            message ??
            'Your session has ended. Please sign in again.',
        code: code ?? 'invalid_token',
        statusCode: status,
      );
    }

    return ApiException(
      _messageFor(code) ?? message ?? _fallbackFor(status),
      code: code,
      statusCode: status,
    );
  }

  /// App wording for codes whose server message is written for a developer.
  static String? _messageFor(String? code) => switch (code) {
        'plant_not_active' => 'This plant is paused. Resume care first.',
        'plant_not_paused' =>
          'This plant is not paused. Add a check-in to bring it up to date.',
        'treatment_not_open' => 'That treatment has already been closed.',
        'treatment_not_found' => 'We could not find that treatment.',
        'course_not_open' => 'Every problem on that plan has already finished.',
        'course_not_found' => 'We could not find that treatment plan.',
        'task_not_skippable' => 'Only a treatment step can be skipped.',
        'invalid_timezone' => 'That time zone is not recognised.',
        _ => null,
      };

  static String _fallbackFor(int? status) {
    if (status != null && status >= 500) {
      return 'The server had a problem. Please try again.';
    }
    return switch (status) {
      400 || 422 => "That didn't look right. Please check and try again.",
      403 => 'You do not have access to that.',
      404 => 'We could not find that.',
      413 => 'That photo is too large. Try a smaller one.',
      429 => 'Too many requests just now. Please wait a moment.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

/// Debug-only request log: method, path, masked body, status and timing.
///
/// Secrets never reach the console: passwords, tokens and OTP codes are
/// shown as `***`, and the Authorization header is not printed at all.
class _DebugLogInterceptor extends Interceptor {
  static const String _startedKey = 'logStartedAt';
  static const Set<String> _secrets = {
    'password',
    'new_password',
    'access_token',
    'refresh_token',
    'push_token',
    'code',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      options.extra[_startedKey] = DateTime.now();
      final query = options.queryParameters.isEmpty
          ? ''
          : ' ?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      final body = options.data == null ? '' : ' ${_describe(options.data)}';
      AppLog.d('→ ${options.method} ${options.path}$query$body', name: 'api');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final o = response.requestOptions;
      AppLog.d(
        '← ${response.statusCode} ${o.method} ${o.path}${_elapsed(o)}',
        name: 'api',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final o = err.requestOptions;
      final status = err.response?.statusCode?.toString() ?? err.type.name;
      final code = HttpClient._codeOf(err);
      final body = err.response?.data;
      final message = body is Map && body['error'] is Map
          ? (body['error'] as Map)['message']
          : err.message;
      AppLog.e(
        '✗ $status ${o.method} ${o.path}${_elapsed(o)}'
        '${code == null ? '' : ' ($code)'}'
        '${message == null ? '' : ' — $message'}',
        name: 'api',
      );
    }
    handler.next(err);
  }

  static String _elapsed(RequestOptions o) {
    final started = o.extra[_startedKey];
    if (started is! DateTime) return '';
    return ' (${DateTime.now().difference(started).inMilliseconds}ms)';
  }

  static String _describe(Object? body) {
    if (body is FormData) {
      return '<multipart: ${body.fields.map((f) => f.key).join(', ')}'
          '${body.files.isEmpty ? '' : ' + ${body.files.length} file(s)'}>';
    }
    if (body is Map) {
      final masked = {
        for (final e in body.entries)
          e.key: _secrets.contains(e.key) ? '***' : e.value,
      };
      return masked.toString();
    }
    final text = body.toString();
    return text.length > 300 ? '${text.substring(0, 300)}…' : text;
  }
}
