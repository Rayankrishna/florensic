import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in session's token pair.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Sign-in, OTP verify and refresh all answer with this shape.
  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw FormatException(
        'token pair is missing access_token or refresh_token',
        json.keys.toList(),
      );
    }
    final seconds = (json['expires_in'] as num?)?.toInt() ?? 900;
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now().toUtc().add(Duration(seconds: seconds)),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Treated as expired a little early so a request in flight does not race
  /// the server's own clock.
  bool get isExpired =>
      DateTime.now().toUtc().isAfter(expiresAt.subtract(const Duration(seconds: 30)));
}

/// Tokens live in the platform keychain / keystore, never in
/// SharedPreferences — they are credentials, not preferences.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const String _access = 'florensic.access_token';
  static const String _refresh = 'florensic.refresh_token';
  static const String _expiry = 'florensic.token_expires_at';

  final FlutterSecureStorage _storage;

  TokenPair? _cached;

  TokenPair? get current => _cached;

  bool get hasSession => _cached != null;

  Future<TokenPair?> restore() async {
    final access = await _storage.read(key: _access);
    final refresh = await _storage.read(key: _refresh);
    final expiry = await _storage.read(key: _expiry);
    if (access == null || refresh == null) return null;
    _cached = TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.tryParse(expiry ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
    );
    return _cached;
  }

  /// Refresh tokens rotate on every use, so this always replaces the pair.
  Future<void> save(TokenPair pair) async {
    _cached = pair;
    await _storage.write(key: _access, value: pair.accessToken);
    await _storage.write(key: _refresh, value: pair.refreshToken);
    await _storage.write(
        key: _expiry, value: pair.expiresAt.toIso8601String());
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _expiry);
  }
}
