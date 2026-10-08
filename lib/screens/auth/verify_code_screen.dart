import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/auth_store.dart';
import '../../stores/onboarding_store.dart';
import '../../theme.dart';

/// `Check your inbox.` — six-digit verification, with the reset confirmation
/// pattern shown beneath it.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final AuthStore _store = locator<AuthStore>();
  final FocusNode _focus = FocusNode();
  final TextEditingController _hidden = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _hidden.text = _store.codeValue;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _store.tickResend();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _openKeyboard());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
    _hidden.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  /// Brings the keyboard back.
  ///
  /// The boxes are presentation only; the real input is an off-screen field.
  /// Once the keyboard is dismissed that field usually still holds focus, and
  /// `requestFocus()` on a node that already has it is a no-op — so the
  /// keyboard would never return. Dropping focus first makes the next request
  /// a real one.
  void _openKeyboard() {
    if (!mounted) return;
    if (_focus.hasFocus) {
      _focus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focus.requestFocus();
        _caretToEnd();
      });
      return;
    }
    _focus.requestFocus();
    _caretToEnd();
  }

  /// Regaining focus can leave the caret at the start, which would insert the
  /// next digit in front of the ones already entered.
  void _caretToEnd() {
    _hidden.selection = TextSelection.collapsed(offset: _hidden.text.length);
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < 6; i++) {
      _store.setCodeDigit(i, i < digits.length ? digits[i] : '');
    }
  }

  Future<void> _verify() async {
    // A `reset` code sets a new password; every other purpose opens a
    // session (§2).
    if (_store.isResettingPassword) {
      final done = await _store.resetPassword(_newPassword.text);
      if (done && mounted) {
        Navigator.of(context).pop();
        AppToast.show(
          context,
          message: 'Password updated',
          detail: 'Sign in with your new password.',
        );
      }
      return;
    }

    final ok = await _store.verifyCode();
    if (!ok || !mounted) return;

    // Only a brand-new account gets the introduction. A sign-in that needed
    // a code (an address never verified) is still an existing account.
    if (_store.otpPurpose == 'signup') {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.onboarding, (route) => false);
      return;
    }
    await locator<OnboardingStore>().completeOnboarding();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.afterSignIn, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        body: ScreenBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // An off-screen field carries the real keyboard input; the
                // boxes are presentation only.
                Positioned(
                  left: -400,
                  child: SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _hidden,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      onChanged: _onChanged,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ),
                Observer(
                  builder: (context) => ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      AppSpacing.gutter,
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleIconButton(
                          icon: PgIcons.chevronLeft,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Check your inbox.',
                        style: AppText.display40.copyWith(fontSize: 35.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text.rich(
                        TextSpan(
                          style: AppText.body15.copyWith(fontSize: 16),
                          children: [
                            const TextSpan(
                              text: 'We sent a six-digit code to ',
                            ),
                            TextSpan(
                              text: _store.pendingEmail.isEmpty
                                  ? 'your inbox'
                                  : _store.pendingEmail,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '. It expires in 10 minutes.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openKeyboard,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < 6; i++)
                              CodeField(
                                value: _store.code[i],
                                focused: i == _store.codeValue.length,
                                onTap: _openKeyboard,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't get it?",
                            style: AppText.body15.copyWith(fontSize: 15),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: _store.resendSeconds > 0
                                ? 'Resend in 0:${_store.resendSeconds.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: AppButtonStyle.link,
                            expand: false,
                            onPressed: _store.resendSeconds > 0
                                ? null
                                : () => _store.requestCode(
                                    _store.pendingEmail,
                                    purpose: _store.otpPurpose,
                                  ),
                          ),
                        ],
                      ),
                      if (_store.isResettingPassword) ...[
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          label: 'New password',
                          hint: 'At least 8 characters',
                          controller: _newPassword,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => _store.clearError(),
                          onSubmitted: (_) => _verify(),
                        ),
                      ],
                      if (_store.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _store.errorMessage!,
                          style: AppText.body13.copyWith(
                            fontSize: 13,
                            color: AppColors.criticalDeep,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      AppButton.primary(
                        label: _store.isResettingPassword
                            ? 'Set new password'
                            : 'Verify and continue',
                        loading: _store.isLoading,
                        onPressed: _store.canVerify ? _verify : null,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Wrong address?',
                            style: AppText.body15.copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: 'Change email',
                            style: AppButtonStyle.link,
                            expand: false,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
