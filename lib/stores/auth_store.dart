import 'package:mobx/mobx.dart';

import '../domain/models/user_profile.dart';
import '../domain/repositories/auth_repository.dart';
import '../key.dart';
import '../storage_manager.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

abstract class _AuthStore with Store {
  _AuthStore(this._repository, this._storage);

  final AuthRepository _repository;
  final StorageManager _storage;

  @observable
  bool isLoading = false;

  @observable
  String? errorMessage;

  @observable
  UserProfile? profile;

  @observable
  bool keepSignedIn = false;

  @observable
  bool obscurePassword = true;

  /// Six-digit verification code, one entry per box.
  @observable
  ObservableList<String> code = ObservableList<String>.of(List.filled(6, ''));

  @observable
  int resendSeconds = 24;

  @observable
  String pendingEmail = '';

  @observable
  bool acceptedTerms = false;

  @computed
  bool get isAuthenticated => profile != null;

  @computed
  String get codeValue => code.join();

  @computed
  bool get canVerify => codeValue.length == 6 && !isLoading;

  @computed
  bool get canCreateAccount => acceptedTerms && !isLoading;

  /// 0–4, drives the strength meter on sign-up.
  @observable
  int passwordStrength = 0;

  @computed
  String get passwordStrengthLabel => switch (passwordStrength) {
        0 => '',
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Good',
        _ => 'Strong',
      };

  @action
  void setKeepSignedIn(bool value) => keepSignedIn = value;

  @action
  void toggleObscurePassword() => obscurePassword = !obscurePassword;

  @action
  void setAcceptedTerms(bool value) => acceptedTerms = value;

  @action
  void ratePassword(String value) {
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    passwordStrength = score;
  }

  @action
  void setCodeDigit(int index, String digit) {
    if (index < 0 || index >= code.length) return;
    code[index] = digit;
    errorMessage = null;
  }

  @action
  void clearError() => errorMessage = null;

  @action
  Future<bool> signIn(String email, String password) =>
      _run(() => _repository.signIn(email: email, password: password));

  @action
  Future<bool> signUp(String name, String email, String password) =>
      _run(() => _repository.signUp(name: name, email: email, password: password));

  @action
  Future<bool> continueWithProvider(String provider) =>
      _run(() => _repository.continueWithProvider(provider));

  @action
  Future<bool> requestCode(String email) async {
    pendingEmail = email;
    isLoading = true;
    errorMessage = null;
    try {
      await _repository.requestCode(email);
      resendSeconds = 24;
      code = ObservableList<String>.of(List.filled(6, ''));
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> verifyCode() =>
      _run(() => _repository.verifyCode(pendingEmail, codeValue));

  @action
  void tickResend() {
    if (resendSeconds > 0) resendSeconds--;
  }

  @action
  Future<void> signOut() async {
    await _repository.signOut();
    profile = null;
    await _storage.remove(StorageKeys.authToken);
    await _storage.remove(StorageKeys.userEmail);
    await _storage.remove(StorageKeys.userName);
  }

  @action
  Future<void> restoreSession() async {
    final token = _storage.getString(StorageKeys.authToken);
    if (token == null) return;
    profile = UserProfile(
      name: _storage.getString(StorageKeys.userName) ?? 'Alex Moreau',
      email: _storage.getString(StorageKeys.userEmail) ?? 'alex.moreau@studio.co',
      city: 'Mumbai',
      plantsKept: 12,
      underActiveCare: 9,
      averageHealth: 84,
      careStreakWeeks: 32,
      streakSince: 'February',
      reminderTime: '08:00',
      units: '°C · ml',
    );
  }

  Future<bool> _run(Future<UserProfile> Function() call) async {
    isLoading = true;
    errorMessage = null;
    try {
      final result = await call();
      profile = result;
      await _persist(result);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> _persist(UserProfile user) async {
    await _storage.setString(StorageKeys.authToken, 'mock-session');
    await _storage.setString(StorageKeys.userEmail, user.email);
    await _storage.setString(StorageKeys.userName, user.name);
    await _storage.setBool(StorageKeys.keepSignedIn, keepSignedIn);
  }
}
