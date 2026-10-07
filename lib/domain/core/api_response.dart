import '../../interceptors/api_interceptor.dart';
import 'json.dart';

/// What a provider call hands back — never a thrown exception.
///
/// Mirrors the lead app's `{'status': ..., 'message': ...}` result, typed:
/// the store reads `resp.ok`, then either `resp.map` or `resp.message`.
/// A breakpoint on the `return` in any provider method shows exactly what
/// the server sent.
class ApiResponse {
  const ApiResponse.success(this.data)
      : ok = true,
        error = null;

  const ApiResponse.failure(this.error)
      : ok = false,
        data = null;

  final bool ok;

  /// The decoded body on success; `null` on failure.
  final dynamic data;

  /// The mapped failure, with the backend's stable `code`.
  final ApiException? error;

  /// The body as a map (empty when it was not one).
  Map<String, dynamic> get map => Json.map(data);

  String get message => error?.message ?? '';

  String? get code => error?.code;

  int? get statusCode => error?.statusCode;

  bool hasCode(String code) => error?.code == code;

  @override
  String toString() => ok
      ? 'ApiResponse.success($data)'
      : 'ApiResponse.failure(${error?.code} — ${error?.message})';
}
