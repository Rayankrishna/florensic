import '../models/user_profile.dart';
import 'mock/mock_api_client.dart';
import '../../interceptors/api_interceptor.dart';

abstract class AuthRepository {
  Future<UserProfile> signIn({required String email, required String password});

  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<UserProfile> continueWithProvider(String provider);

  Future<void> requestCode(String email);

  Future<UserProfile> verifyCode(String email, String code);

  Future<void> signOut();
}

/// Mock auth. No credentials are checked against a real service; any
/// well-formed email and a six-digit code are accepted.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._client);

  final MockApiClient _client;

  static const UserProfile _seed = UserProfile(
    name: 'Alex Moreau',
    email: 'alex.moreau@studio.co',
    city: 'Mumbai',
    plantsKept: 12,
    underActiveCare: 9,
    averageHealth: 84,
    careStreakWeeks: 32,
    streakSince: 'February',
    reminderTime: '08:00',
    units: '°C · ml',
  );

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) =>
      _client.send('/auth/sign-in', () {
        if (password.length < 6) {
          throw const ApiException('That password is too short.');
        }
        return _seed.copyWith(email: email);
      }, params: {'email': email});

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
  }) =>
      _client.send('/auth/sign-up', () {
        if (password.length < 8) {
          throw const ApiException('Use at least eight characters.');
        }
        return _seed.copyWith(name: name, email: email);
      }, params: {'email': email});

  @override
  Future<UserProfile> continueWithProvider(String provider) =>
      _client.send('/auth/$provider', () => _seed);

  @override
  Future<void> requestCode(String email) =>
      _client.send('/auth/code', () {}, params: {'email': email});

  @override
  Future<UserProfile> verifyCode(String email, String code) =>
      _client.send('/auth/verify', () {
        if (code.length < 6) {
          throw const ApiException('Enter all six digits.');
        }
        return _seed.copyWith(email: email);
      });

  @override
  Future<void> signOut() => _client.send('/auth/sign-out', () {});
}
