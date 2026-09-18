import '../../../interceptors/api_interceptor.dart';

/// Runs mock repository calls through the interceptor chain.
///
/// Replacing this with a real HTTP client is a single-class change: the
/// repositories only ever call [send].
class MockApiClient {
  MockApiClient({List<ApiInterceptor>? interceptors})
      : _interceptors = interceptors ??
            const [LoggingInterceptor(), LatencyInterceptor()];

  final List<ApiInterceptor> _interceptors;

  /// Set from the UI to exercise the offline / failure states.
  bool offline = false;

  Future<T> send<T>(
    String path,
    T Function() body, {
    Map<String, Object?> params = const {},
    bool failsWhenOffline = true,
  }) async {
    final request = ApiRequest(path, params: params);
    for (final i in _interceptors) {
      await i.onRequest(request);
    }
    try {
      if (offline && failsWhenOffline) {
        throw const ApiException('No internet connection');
      }
      final result = body();
      for (final i in _interceptors) {
        await i.onResponse(request, result);
      }
      return result;
    } catch (error) {
      for (final i in _interceptors) {
        await i.onError(request, error);
      }
      rethrow;
    }
  }
}
