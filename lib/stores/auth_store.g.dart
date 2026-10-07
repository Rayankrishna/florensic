// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStore, Store {
  Computed<bool>? _$isLoadingComputed;

  @override
  bool get isLoading => (_$isLoadingComputed ??= Computed<bool>(
    () => super.isLoading,
    name: '_AuthStore.isLoading',
  )).value;
  Computed<bool>? _$isAuthenticatedComputed;

  @override
  bool get isAuthenticated => (_$isAuthenticatedComputed ??= Computed<bool>(
    () => super.isAuthenticated,
    name: '_AuthStore.isAuthenticated',
  )).value;
  Computed<bool>? _$isResettingPasswordComputed;

  @override
  bool get isResettingPassword =>
      (_$isResettingPasswordComputed ??= Computed<bool>(
        () => super.isResettingPassword,
        name: '_AuthStore.isResettingPassword',
      )).value;
  Computed<String>? _$codeValueComputed;

  @override
  String get codeValue => (_$codeValueComputed ??= Computed<String>(
    () => super.codeValue,
    name: '_AuthStore.codeValue',
  )).value;
  Computed<bool>? _$canVerifyComputed;

  @override
  bool get canVerify => (_$canVerifyComputed ??= Computed<bool>(
    () => super.canVerify,
    name: '_AuthStore.canVerify',
  )).value;
  Computed<bool>? _$canCreateAccountComputed;

  @override
  bool get canCreateAccount => (_$canCreateAccountComputed ??= Computed<bool>(
    () => super.canCreateAccount,
    name: '_AuthStore.canCreateAccount',
  )).value;
  Computed<String>? _$passwordStrengthLabelComputed;

  @override
  String get passwordStrengthLabel =>
      (_$passwordStrengthLabelComputed ??= Computed<String>(
        () => super.passwordStrengthLabel,
        name: '_AuthStore.passwordStrengthLabel',
      )).value;

  late final _$signInStateAtom = Atom(
    name: '_AuthStore.signInState',
    context: context,
  );

  @override
  LoadState get signInState {
    _$signInStateAtom.reportRead();
    return super.signInState;
  }

  @override
  set signInState(LoadState value) {
    _$signInStateAtom.reportWrite(value, super.signInState, () {
      super.signInState = value;
    });
  }

  late final _$signUpStateAtom = Atom(
    name: '_AuthStore.signUpState',
    context: context,
  );

  @override
  LoadState get signUpState {
    _$signUpStateAtom.reportRead();
    return super.signUpState;
  }

  @override
  set signUpState(LoadState value) {
    _$signUpStateAtom.reportWrite(value, super.signUpState, () {
      super.signUpState = value;
    });
  }

  late final _$otpRequestStateAtom = Atom(
    name: '_AuthStore.otpRequestState',
    context: context,
  );

  @override
  LoadState get otpRequestState {
    _$otpRequestStateAtom.reportRead();
    return super.otpRequestState;
  }

  @override
  set otpRequestState(LoadState value) {
    _$otpRequestStateAtom.reportWrite(value, super.otpRequestState, () {
      super.otpRequestState = value;
    });
  }

  late final _$verifyStateAtom = Atom(
    name: '_AuthStore.verifyState',
    context: context,
  );

  @override
  LoadState get verifyState {
    _$verifyStateAtom.reportRead();
    return super.verifyState;
  }

  @override
  set verifyState(LoadState value) {
    _$verifyStateAtom.reportWrite(value, super.verifyState, () {
      super.verifyState = value;
    });
  }

  late final _$resetStateAtom = Atom(
    name: '_AuthStore.resetState',
    context: context,
  );

  @override
  LoadState get resetState {
    _$resetStateAtom.reportRead();
    return super.resetState;
  }

  @override
  set resetState(LoadState value) {
    _$resetStateAtom.reportWrite(value, super.resetState, () {
      super.resetState = value;
    });
  }

  late final _$sessionStateAtom = Atom(
    name: '_AuthStore.sessionState',
    context: context,
  );

  @override
  LoadState get sessionState {
    _$sessionStateAtom.reportRead();
    return super.sessionState;
  }

  @override
  set sessionState(LoadState value) {
    _$sessionStateAtom.reportWrite(value, super.sessionState, () {
      super.sessionState = value;
    });
  }

  late final _$errorMessageAtom = Atom(
    name: '_AuthStore.errorMessage',
    context: context,
  );

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$profileAtom = Atom(name: '_AuthStore.profile', context: context);

  @override
  UserProfile? get profile {
    _$profileAtom.reportRead();
    return super.profile;
  }

  @override
  set profile(UserProfile? value) {
    _$profileAtom.reportWrite(value, super.profile, () {
      super.profile = value;
    });
  }

  late final _$obscurePasswordAtom = Atom(
    name: '_AuthStore.obscurePassword',
    context: context,
  );

  @override
  bool get obscurePassword {
    _$obscurePasswordAtom.reportRead();
    return super.obscurePassword;
  }

  @override
  set obscurePassword(bool value) {
    _$obscurePasswordAtom.reportWrite(value, super.obscurePassword, () {
      super.obscurePassword = value;
    });
  }

  late final _$codeAtom = Atom(name: '_AuthStore.code', context: context);

  @override
  ObservableList<String> get code {
    _$codeAtom.reportRead();
    return super.code;
  }

  @override
  set code(ObservableList<String> value) {
    _$codeAtom.reportWrite(value, super.code, () {
      super.code = value;
    });
  }

  late final _$resendSecondsAtom = Atom(
    name: '_AuthStore.resendSeconds',
    context: context,
  );

  @override
  int get resendSeconds {
    _$resendSecondsAtom.reportRead();
    return super.resendSeconds;
  }

  @override
  set resendSeconds(int value) {
    _$resendSecondsAtom.reportWrite(value, super.resendSeconds, () {
      super.resendSeconds = value;
    });
  }

  late final _$pendingEmailAtom = Atom(
    name: '_AuthStore.pendingEmail',
    context: context,
  );

  @override
  String get pendingEmail {
    _$pendingEmailAtom.reportRead();
    return super.pendingEmail;
  }

  @override
  set pendingEmail(String value) {
    _$pendingEmailAtom.reportWrite(value, super.pendingEmail, () {
      super.pendingEmail = value;
    });
  }

  late final _$otpPurposeAtom = Atom(
    name: '_AuthStore.otpPurpose',
    context: context,
  );

  @override
  String get otpPurpose {
    _$otpPurposeAtom.reportRead();
    return super.otpPurpose;
  }

  @override
  set otpPurpose(String value) {
    _$otpPurposeAtom.reportWrite(value, super.otpPurpose, () {
      super.otpPurpose = value;
    });
  }

  late final _$needsVerificationAtom = Atom(
    name: '_AuthStore.needsVerification',
    context: context,
  );

  @override
  bool get needsVerification {
    _$needsVerificationAtom.reportRead();
    return super.needsVerification;
  }

  @override
  set needsVerification(bool value) {
    _$needsVerificationAtom.reportWrite(value, super.needsVerification, () {
      super.needsVerification = value;
    });
  }

  late final _$acceptedTermsAtom = Atom(
    name: '_AuthStore.acceptedTerms',
    context: context,
  );

  @override
  bool get acceptedTerms {
    _$acceptedTermsAtom.reportRead();
    return super.acceptedTerms;
  }

  @override
  set acceptedTerms(bool value) {
    _$acceptedTermsAtom.reportWrite(value, super.acceptedTerms, () {
      super.acceptedTerms = value;
    });
  }

  late final _$passwordStrengthAtom = Atom(
    name: '_AuthStore.passwordStrength',
    context: context,
  );

  @override
  int get passwordStrength {
    _$passwordStrengthAtom.reportRead();
    return super.passwordStrength;
  }

  @override
  set passwordStrength(int value) {
    _$passwordStrengthAtom.reportWrite(value, super.passwordStrength, () {
      super.passwordStrength = value;
    });
  }

  late final _$signInAsyncAction = AsyncAction(
    '_AuthStore.signIn',
    context: context,
  );

  @override
  Future<bool> signIn(String email, String password) {
    return _$signInAsyncAction.run(() => super.signIn(email, password));
  }

  late final _$signUpAsyncAction = AsyncAction(
    '_AuthStore.signUp',
    context: context,
  );

  @override
  Future<bool> signUp(String name, String email, String password) {
    return _$signUpAsyncAction.run(() => super.signUp(name, email, password));
  }

  late final _$requestCodeAsyncAction = AsyncAction(
    '_AuthStore.requestCode',
    context: context,
  );

  @override
  Future<bool> requestCode(String email, {String purpose = 'signin'}) {
    return _$requestCodeAsyncAction.run(
      () => super.requestCode(email, purpose: purpose),
    );
  }

  late final _$verifyCodeAsyncAction = AsyncAction(
    '_AuthStore.verifyCode',
    context: context,
  );

  @override
  Future<bool> verifyCode() {
    return _$verifyCodeAsyncAction.run(() => super.verifyCode());
  }

  late final _$resetPasswordAsyncAction = AsyncAction(
    '_AuthStore.resetPassword',
    context: context,
  );

  @override
  Future<bool> resetPassword(String newPassword) {
    return _$resetPasswordAsyncAction.run(
      () => super.resetPassword(newPassword),
    );
  }

  late final _$signOutAsyncAction = AsyncAction(
    '_AuthStore.signOut',
    context: context,
  );

  @override
  Future<void> signOut() {
    return _$signOutAsyncAction.run(() => super.signOut());
  }

  late final _$restoreSessionAsyncAction = AsyncAction(
    '_AuthStore.restoreSession',
    context: context,
  );

  @override
  Future<void> restoreSession() {
    return _$restoreSessionAsyncAction.run(() => super.restoreSession());
  }

  late final _$syncTimezoneAsyncAction = AsyncAction(
    '_AuthStore.syncTimezone',
    context: context,
  );

  @override
  Future<void> syncTimezone() {
    return _$syncTimezoneAsyncAction.run(() => super.syncTimezone());
  }

  late final _$_AuthStoreActionController = ActionController(
    name: '_AuthStore',
    context: context,
  );

  @override
  void toggleObscurePassword() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.toggleObscurePassword',
    );
    try {
      return super.toggleObscurePassword();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAcceptedTerms(bool value) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.setAcceptedTerms',
    );
    try {
      return super.setAcceptedTerms(value);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void ratePassword(String value) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.ratePassword',
    );
    try {
      return super.ratePassword(value);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCodeDigit(int index, String digit) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.setCodeDigit',
    );
    try {
      return super.setCodeDigit(index, digit);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearError() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.clearError',
    );
    try {
      return super.clearError();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setError(String message) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.setError',
    );
    try {
      return super.setError(message);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void tickResend() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.tickResend',
    );
    try {
      return super.tickResend();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void handleSessionExpired() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.handleSessionExpired',
    );
    try {
      return super.handleSessionExpired();
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
signInState: ${signInState},
signUpState: ${signUpState},
otpRequestState: ${otpRequestState},
verifyState: ${verifyState},
resetState: ${resetState},
sessionState: ${sessionState},
errorMessage: ${errorMessage},
profile: ${profile},
obscurePassword: ${obscurePassword},
code: ${code},
resendSeconds: ${resendSeconds},
pendingEmail: ${pendingEmail},
otpPurpose: ${otpPurpose},
needsVerification: ${needsVerification},
acceptedTerms: ${acceptedTerms},
passwordStrength: ${passwordStrength},
isLoading: ${isLoading},
isAuthenticated: ${isAuthenticated},
isResettingPassword: ${isResettingPassword},
codeValue: ${codeValue},
canVerify: ${canVerify},
canCreateAccount: ${canCreateAccount},
passwordStrengthLabel: ${passwordStrengthLabel}
    ''';
  }
}
