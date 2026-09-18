import 'dart:developer' as developer;

/// A single call passing through the client.
class ApiRequest {
  const ApiRequest(this.path, {this.params = const {}});

  final String path;
  final Map<String, Object?> params;

  @override
  String toString() =>
      params.isEmpty ? path : '$path?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
}

/// Hook points around a call.
///
/// The app currently talks to a mock backend, but every repository goes through
/// this chain so swapping in a real HTTP client changes one class, not many.
abstract class ApiInterceptor {
  const ApiInterceptor();

  Future<void> onRequest(ApiRequest request) async {}

  Future<void> onResponse(ApiRequest request, Object? response) async {}

  Future<void> onError(ApiRequest request, Object error) async {}
}

/// Writes calls to the Dart timeline / console in debug builds.
class LoggingInterceptor extends ApiInterceptor {
  const LoggingInterceptor();

  @override
  Future<void> onRequest(ApiRequest request) async {
    developer.log('→ $request', name: 'api');
  }

  @override
  Future<void> onError(ApiRequest request, Object error) async {
    developer.log('✗ $request — $error', name: 'api', error: error);
  }
}

/// Gives mock responses a believable delay so loading states are real.
class LatencyInterceptor extends ApiInterceptor {
  const LatencyInterceptor({this.duration = const Duration(milliseconds: 620)});

  final Duration duration;

  @override
  Future<void> onRequest(ApiRequest request) => Future<void>.delayed(duration);
}

/// Thrown by repositories when a mock call is configured to fail.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
