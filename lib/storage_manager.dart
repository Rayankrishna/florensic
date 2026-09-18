import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper over [SharedPreferences].
///
/// Every persisted value in the app goes through here so the storage backend
/// can be swapped without touching stores or widgets.
class StorageManager {
  StorageManager._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageManager> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageManager._(prefs);
  }

  bool getBool(String key, {bool fallback = false}) =>
      _prefs.getBool(key) ?? fallback;

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  int getInt(String key, {int fallback = 0}) => _prefs.getInt(key) ?? fallback;

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  List<String> getStringList(String key) => _prefs.getStringList(key) ?? const [];

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
