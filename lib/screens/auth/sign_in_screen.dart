import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/auth_store.dart';
import '../../stores/onboarding_store.dart';
import '../../theme.dart';

/// `Welcome back.`
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthStore _store = locator<AuthStore>();

  @override
  void initState() {
    super.initState();
    _store.clearError();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// A reset needs a code, so ask for one before showing the code screen —
  /// otherwise the keeper lands on six empty boxes with nothing on the way.
  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      _store.setError('Enter your email address first.');
      return;
    }
    FocusScope.of(context).unfocus();
    final sent = await _store.requestCode(email, purpose: 'reset');
    if (sent && mounted) {
      Navigator.of(context).pushNamed(AppRoutes.verifyCode);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ok = await _store.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;

    if (ok) {
      // An existing account has no introduction to sit through. Mark it
      // seen so the next launch does not show it either, then land on the
      // permissions step if this device still needs it, else home.
      await locator<OnboardingStore>().completeOnboarding();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.afterSignIn, (route) => false);
      return;
    }
    // 403 email_unverified: the store has already sent a fresh code, so carry
    // on to the code screen rather than leaving an error on a dead end.
    if (_store.needsVerification) {
      Navigator.of(context).pushNamed(AppRoutes.verifyCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: ScreenBackground(
          child: SafeArea(
            child: Observer(
              builder: (context) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      AppSpacing.gutter,
                    ),
                    sliver: SliverList.list(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CircleIconButton(
                            icon: PgIcons.chevronLeft,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Text(
                          'Welcome back.',
                          style: AppText.display40.copyWith(fontSize: 37),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Sign in to pick up where your collection left off.',
                          style: AppText.body15.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        AppTextField(
                          label: 'Email address',
                          hint: 'you@example.com',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => _store.clearError(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _password,
                          obscureText: _store.obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          errorText: _store.errorMessage,
                          onChanged: (_) => _store.clearError(),
                          onSubmitted: (_) => _submit(),
                          suffix: GestureDetector(
                            onTap: _store.toggleObscurePassword,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.neutralTint,
                                shape: BoxShape.circle,
                              ),
                              child: PgIcon(
                                _store.obscurePassword
                                    ? PgIcons.eye
                                    : PgIcons.eyeOff,
                                size: 20,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            label: 'Forgot password?',
                            style: AppButtonStyle.link,
                            expand: false,
                            onPressed: _resetPassword,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton.primary(
                          label: 'Sign in',
                          loading: _store.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No account yet?',
                                style: AppText.body15.copyWith(fontSize: 14),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AppButton(
                                label: 'Sign up',
                                style: AppButtonStyle.link,
                                expand: false,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.signUp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
