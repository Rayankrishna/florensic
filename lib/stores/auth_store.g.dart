// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on _AuthStore, Store {
  Computed<bool>? _$isAuthenticatedComputed;

  @override
  bool get isAuthenticated => (_$isAuthenticatedComputed ??= Computed<bool>(
    () => super.isAuthenticated,
    name: '_AuthStore.isAuthenticated',
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

  late final _$isLoadingAtom = Atom(
    name: '_AuthStore.isLoading',
    context: context,
  );

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
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

  late final _$keepSignedInAtom = Atom(
    name: '_AuthStore.keepSignedIn',
    context: context,
  );

  @override
  bool get keepSignedIn {
    _$keepSignedInAtom.reportRead();
    return super.keepSignedIn;
  }

  @override
  set keepSignedIn(bool value) {
    _$keepSignedInAtom.reportWrite(value, super.keepSignedIn, () {
      super.keepSignedIn = value;
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

  late final _$requestCodeAsyncAction = AsyncAction(
    '_AuthStore.requestCode',
    context: context,
  );

  @override
  Future<bool> requestCode(String email) {
    return _$requestCodeAsyncAction.run(() => super.requestCode(email));
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

  late final _$_AuthStoreActionController = ActionController(
    name: '_AuthStore',
    context: context,
  );

  @override
  void setKeepSignedIn(bool value) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.setKeepSignedIn',
    );
    try {
      return super.setKeepSignedIn(value);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

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
  Future<bool> signIn(String email, String password) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.signIn',
    );
    try {
      return super.signIn(email, password);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> signUp(String name, String email, String password) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.signUp',
    );
    try {
      return super.signUp(name, email, password);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> continueWithProvider(String provider) {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.continueWithProvider',
    );
    try {
      return super.continueWithProvider(provider);
    } finally {
      _$_AuthStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> verifyCode() {
    final _$actionInfo = _$_AuthStoreActionController.startAction(
      name: '_AuthStore.verifyCode',
    );
    try {
      return super.verifyCode();
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
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
profile: ${profile},
keepSignedIn: ${keepSignedIn},
obscurePassword: ${obscurePassword},
code: ${code},
resendSeconds: ${resendSeconds},
pendingEmail: ${pendingEmail},
acceptedTerms: ${acceptedTerms},
passwordStrength: ${passwordStrength},
isAuthenticated: ${isAuthenticated},
codeValue: ${codeValue},
canVerify: ${canVerify},
canCreateAccount: ${canCreateAccount},
passwordStrengthLabel: ${passwordStrengthLabel}
    ''';
  }
}
