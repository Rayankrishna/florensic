import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// App logging.
///
/// Always import **this**, never `dart:developer` directly — an IDE
/// auto-import of `log` can land on `dart:nativewrappers/.../developer.dart`,
/// which is an internal VM library and silently does nothing.
///
/// Output goes to the Dart timeline (visible in DevTools and `flutter run`)
/// and is stripped from release builds.
class AppLog {
  const AppLog._();

  static const String _default = 'florensic';

  static void d(Object? message, {String name = _default}) =>
      _emit(message, name: name, level: 500);

  static void i(Object? message, {String name = _default}) =>
      _emit(message, name: name, level: 800);

  static void w(Object? message, {String name = _default}) =>
      _emit(message, name: name, level: 900);

  static void e(
    Object? message, {
    String name = _default,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    developer.log(
      '$message',
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    // `flutter run` shows debugPrint reliably; developer.log can be swallowed
    // by some launch configurations.
    debugPrint('[$name] $message${error == null ? '' : ' — $error'}');
  }

  static void _emit(Object? message, {required String name, required int level}) {
    if (!kDebugMode) return;
    developer.log('$message', name: name, level: level);
    debugPrint('[$name] $message');
  }
}
