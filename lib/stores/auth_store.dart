import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mobx/mobx.dart';

import '../domain/core/token_store.dart';
import '../domain/models/user_profile.dart';
import '../domain/provider/auth.provider.dart';
import '../enum.dart';
import '../key.dart';
import '../storage_manager.dart';
import '../utils/app_log.dart';

part 'auth_store.g.dart';

class AuthStore = _AuthStore with _$AuthStore;

/// Sign-in, sign-up, the OTP steps and the session.
///
/// Shaped like the lead app's store: each action sets its own state to
/// loading, makes one provider call, and branches on `resp.ok`. Nothing is
/// thrown across layers, so a failure is always a `resp` you can inspect,
/// and every call is logged by the client in debug builds.
abstract class _AuthStore with Store {
  _AuthStore(this._auth, this._tokens, this._storage);

  final AuthProvider _auth;
  final TokenStore _tokens;
  final StorageManager _storage;

  // ── Per-call state ───────────────────────────────────────────────────────
  //
  // One state per call, so it is always clear which request is in flight or
  // failed. Screens read the combined [isLoading] and [errorMessage].

  @observable
  LoadState signInState = LoadState.idle;

  @observable
  LoadState signUpState = LoadState.idle;

  @observable
  LoadState otpRequestState = LoadState.idle;

  @observable
  LoadState verifyState = LoadState.idle;

  @observable
  LoadState resetState = LoadState.idle;

  /// Restoring the saved session on launch.
  @observable
  LoadState sessionState = LoadState.idle;

  @observable
  String? errorMessage;

  @computed
  bool get isLoading =>
      signInState == LoadState.loading ||
      signUpState == LoadState.loading ||
      otpRequestState == LoadState.loading ||
      verifyState == LoadState.loading ||
      resetState == LoadState.loading;

  // ── Session ──────────────────────────────────────────────────────────────

  @observable
  UserProfile? profile;

  @computed
  bool get isAuthenticated => profile != null;

  // ── Form state ───────────────────────────────────────────────────────────

  @observable
  bool obscurePassword = true;

  /// Six-digit verification code, one entry per box.
  @observable
  ObservableList<String> code = ObservableList<String>.of(List.filled(6, ''));

  @observable
  int resendSeconds = 24;

  @observable
  String pendingEmail = '';

  /// Which code is in flight: `signup`, `signin` or `reset`. The backend
  /// issues a different code per purpose, so a resend must match.
  @observable
  String otpPurpose = 'signin';

  /// Set when sign-in is refused because the address was never verified, so
  /// the screen can route to the code step instead of showing a dead error.
  @observable
  bool needsVerification = false;

  @observable
  bool acceptedTerms = false;

  /// 0–4, drives the strength meter on sign-up.
  @observable
  int passwordStrength = 0;

  /// The code screen doubles as the reset flow's first step.
  @computed
  bool get isResettingPassword => otpPurpose == 'reset';

  @computed
  String get codeValue => code.join();

  @computed
  bool get canVerify => codeValue.length == 6 && !isLoading;

  @computed
  bool get canCreateAccount => acceptedTerms && !isLoading;

  @computed
  String get passwordStrengthLabel => switch (passwordStrength) {
        0 => '',
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Good',
        _ => 'Strong',
      };

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
  void setError(String message) => errorMessage = message;

  @action
  void tickResend() {
    if (resendSeconds > 0) resendSeconds--;
  }

  // ── Calls ────────────────────────────────────────────────────────────────

  @action
  Future<bool> signIn(String email, String password) async {
    signInState = LoadState.loading;
    errorMessage = null;
    needsVerification = false;

    final resp = await _auth.signIn(email, password);
    if (!resp.ok) {
      AppLog.w('sign-in failed: ${resp.code} — ${resp.message}', name: 'auth');
      // 403 email_unverified: the account exists but was never confirmed.
      // Send a fresh code and let the screen move on to the code step.
      if (resp.hasCode('email_unverified')) {
        final sent = await requestCode(email, purpose: 'signin');
        runInAction(() {
          needsVerification = sent;
          signInState = LoadState.error;
        });
        return false;
      }
      runInAction(() {
        signInState = LoadState.error;
        errorMessage = resp.message;
      });
      return false;
    }

    final ok = await _establishSession(resp.map);
    runInAction(() => signInState = ok ? LoadState.ready : LoadState.error);
    return ok;
  }

  /// Creates the account and sends the OTP. There is no session until the
  /// code is verified, so success routes to the code screen.
  @action
  Future<bool> signUp(String name, String email, String password) async {
    signUpState = LoadState.loading;
    errorMessage = null;
    pendingEmail = email;
    otpPurpose = 'signup';

    final resp = await _auth.signUp(name, email, password);
    if (!resp.ok) {
      AppLog.w('sign-up failed: ${resp.code} — ${resp.message}', name: 'auth');
      runInAction(() {
        signUpState = LoadState.error;
        errorMessage = resp.message;
      });
      return false;
    }

    // 202: the account exists and a code is on its way.
    AppLog.i('sign-up accepted, awaiting OTP for $email', name: 'auth');
    runInAction(() {
      signUpState = LoadState.ready;
      _resetCode();
    });
    return true;
  }

  @action
  Future<bool> requestCode(String email, {String purpose = 'signin'}) async {
    pendingEmail = email;
    otpPurpose = purpose;
    otpRequestState = LoadState.loading;
    errorMessage = null;

    final resp = await _auth.requestOtp(email, purpose: purpose);
    if (!resp.ok) {
      AppLog.w('OTP request failed: ${resp.code} — ${resp.message}',
          name: 'auth');
      runInAction(() {
        otpRequestState = LoadState.error;
        errorMessage = resp.message;
      });
      return false;
    }

    AppLog.i('OTP ($purpose) sent to $email', name: 'auth');
    runInAction(() {
      otpRequestState = LoadState.ready;
      _resetCode();
    });
    return true;
  }

  @action
  Future<bool> verifyCode() async {
    verifyState = LoadState.loading;
    errorMessage = null;

    final resp = await _auth.verifyOtp(pendingEmail, codeValue);
    if (!resp.ok) {
      AppLog.w('OTP verify failed: ${resp.code} — ${resp.message}',
          name: 'auth');
      runInAction(() {
        verifyState = LoadState.error;
        errorMessage = resp.message;
        // Five wrong tries lock the code; the only way on is a new one.
        if (resp.hasCode('otp_locked')) resendSeconds = 0;
      });
      return false;
    }

    final ok = await _establishSession(resp.map);
    runInAction(() => verifyState = ok ? LoadState.ready : LoadState.error);
    return ok;
  }

  /// Consumes a `reset` code and sets the new password. There is no session
  /// afterwards — the keeper signs in with it.
  @action
  Future<bool> resetPassword(String newPassword) async {
    if (newPassword.length < 8) {
      setError('Use at least eight characters for your password.');
      return false;
    }
    resetState = LoadState.loading;
    errorMessage = null;

    final resp = await _auth.resetPassword(pendingEmail, codeValue, newPassword);
    if (!resp.ok) {
      AppLog.w('password reset failed: ${resp.code} — ${resp.message}',
          name: 'auth');
      runInAction(() {
        resetState = LoadState.error;
        errorMessage = resp.message;
        if (resp.hasCode('otp_locked')) resendSeconds = 0;
      });
      return false;
    }

    AppLog.i('password reset for $pendingEmail', name: 'auth');
    runInAction(() {
      resetState = LoadState.ready;
      _resetCode();
      otpPurpose = 'signin';
    });
    return true;
  }

  @action
  Future<void> signOut() async {
    final resp = await _auth.signOut(_tokens.current?.refreshToken);
    if (!resp.ok) {
      // Signing out locally must succeed even if the call does not.
      AppLog.w('sign-out call failed (${resp.code}); clearing locally',
          name: 'auth');
    }
    await _tokens.clear();
    await _clearSession();
    AppLog.i('signed out', name: 'auth');
    runInAction(() {
      profile = null;
      signInState = LoadState.idle;
      verifyState = LoadState.idle;
    });
  }

  /// Brings back a signed-in session on launch: tokens from the keychain,
  /// profile from `GET /v1/me`.
  @action
  Future<void> restoreSession() async {
    sessionState = LoadState.loading;

    final pair = await _tokens.restore();
    if (pair == null) {
      AppLog.i('no stored session', name: 'auth');
      await _clearSession();
      runInAction(() => sessionState = LoadState.ready);
      return;
    }
    AppLog.i(
      'stored session found; access token '
      '${pair.isExpired ? 'expired' : 'valid until ${pair.expiresAt.toLocal()}'}',
      name: 'auth',
    );

    // A 15-minute access token has almost always expired by the next launch.
    // Rotate the pair and save it first, instead of letting `/me` trip over
    // a 401 and relying on the retry.
    if (pair.isExpired) {
      final refreshed = await _auth.refreshSession();
      if (!refreshed) {
        if (_tokens.current == null) {
          // The server refused the refresh token; it has already been
          // cleared. Sign in again.
          AppLog.w('stored session refused; sign-in needed', name: 'auth');
          await _clearSession();
        } else {
          // Offline or a server error: the pair stays for the next launch.
          AppLog.w('could not refresh the session; keeping the saved tokens',
              name: 'auth');
        }
        runInAction(() {
          profile = null;
          sessionState = LoadState.error;
        });
        return;
      }
    }

    final resp = await _auth.me();
    if (!resp.ok) {
      AppLog.w('session restore failed: ${resp.code} — ${resp.message}',
          name: 'auth');
      // Only an auth refusal means the tokens are bad. Offline, they are
      // kept so the next launch can try again.
      if (resp.statusCode == 401 || resp.statusCode == 403) {
        await _tokens.clear();
        await _clearSession();
      }
      runInAction(() {
        profile = null;
        sessionState = LoadState.error;
      });
      return;
    }

    final user = UserProfile.fromJson(resp.map);
    AppLog.i('session restored for ${user.email}', name: 'auth');
    runInAction(() {
      profile = user;
      sessionState = LoadState.ready;
    });
    await syncTimezone();
  }

  /// The client calls this when a refresh could not rescue the session.
  @action
  void handleSessionExpired() {
    AppLog.w('session expired, signing out', name: 'auth');
    profile = null;
    errorMessage = 'Your session has ended. Please sign in again.';
    _clearSession();
  }

  /// Sends the device's IANA zone when it differs from the one on the
  /// profile. Best effort: a failure leaves the owner on their last zone.
  @action
  Future<void> syncTimezone() async {
    final current = profile;
    if (current == null) return;

    String zone;
    try {
      zone = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (e) {
      // No plugin on this build yet, or the platform refused.
      AppLog.w('device time zone unavailable: $e', name: 'auth');
      return;
    }
    if (zone.isEmpty || zone == current.timezone) return;

    final resp = await _auth.updateMe({'timezone': zone});
    if (!resp.ok) {
      // `invalid_timezone`: the server's tz database has no such name.
      AppLog.w('time zone refused: ${resp.code} — ${resp.message}',
          name: 'auth');
      return;
    }
    final updated = UserProfile.fromJson(resp.map);
    AppLog.i('time zone set to ${updated.timezone}', name: 'auth');
    runInAction(() => profile = updated);
  }

  // ── Internals ────────────────────────────────────────────────────────────

  /// Saves the token pair, then reads the profile. Both must succeed for the
  /// keeper to count as signed in; [errorMessage] says which one did not.
  Future<bool> _establishSession(Map<String, dynamic> tokenJson) async {
    final TokenPair pair;
    try {
      pair = TokenPair.fromJson(tokenJson);
    } catch (e) {
      AppLog.e('token response unreadable: $tokenJson',
          name: 'auth', error: e);
      runInAction(() => errorMessage =
          'The server sent an unexpected reply. Please try again.');
      return false;
    }
    await _tokens.save(pair);
    AppLog.i(
      'token pair saved to the keychain; access token expires '
      '${pair.expiresAt.toLocal()}, refresh token rotates on use',
      name: 'auth',
    );

    final resp = await _auth.me();
    if (!resp.ok) {
      AppLog.w('GET /me failed after sign-in: ${resp.code} — ${resp.message}',
          name: 'auth');
      await _tokens.clear();
      runInAction(() => errorMessage = resp.message);
      return false;
    }

    final user = UserProfile.fromJson(resp.map);
    await _persist(user);
    AppLog.i('signed in as ${user.email}', name: 'auth');
    runInAction(() => profile = user);
    // Every date the API answers with is on the owner's calendar, so the
    // device zone goes up as soon as there is a token.
    await syncTimezone();
    return true;
  }

  void _resetCode() {
    resendSeconds = 24;
    code = ObservableList<String>.of(List.filled(6, ''));
  }

  Future<void> _persist(UserProfile user) async {
    // A 'signed in' marker only — the real credentials live in the
    // keychain via TokenStore, never here.
    await _storage.setString(StorageKeys.authToken, 'signed-in');
    await _storage.setString(StorageKeys.userEmail, user.email);
    await _storage.setString(StorageKeys.userName, user.name);
  }

  Future<void> _clearSession() async {
    await _storage.remove(StorageKeys.authToken);
    await _storage.remove(StorageKeys.userEmail);
    await _storage.remove(StorageKeys.userName);
  }
}
