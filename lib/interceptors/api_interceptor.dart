/// Raised for any failed call.
///
/// [code] is the backend's stable error code from the `{"error": {...}}`
/// envelope, so stores can branch on it without matching prose. The typed
/// providers throw it; the auth provider wraps it in an `ApiResponse`.
class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get isOffline => code == 'offline';

  bool get isRateLimited => code == 'rate_limited' || statusCode == 429;

  /// `notes` or `water/skip` on a paused plant.
  bool get isPlantNotActive => code == 'plant_not_active';

  /// `resume` on a plant that is active or stale. On a stale plant it means
  /// "check in instead".
  bool get isPlantNotPaused => code == 'plant_not_paused';

  /// The treatment or plan was already closed, or is not ours any more.
  bool get isTreatmentGone =>
      code == 'treatment_not_open' ||
      code == 'treatment_not_found' ||
      code == 'course_not_open' ||
      code == 'course_not_found';

  bool get isTaskNotSkippable => code == 'task_not_skippable';

  bool get isInvalidTimezone => code == 'invalid_timezone';

  @override
  String toString() => message;
}
