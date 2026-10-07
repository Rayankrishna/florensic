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
import '../../theme.dart';

/// `Start your collection.`
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
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
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Creates the account.
  ///
  /// `POST /v1/auth/sign-up` answers 202 and sends the OTP, so success lands
  /// on the code screen rather than a session.
  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (name.isEmpty) {
      _store.setError('Enter your name.');
      return;
    }
    if (!email.contains('@') || email.length < 5) {
      _store.setError('Enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      _store.setError('Use at least eight characters for your password.');
      return;
    }

    FocusScope.of(context).unfocus();
    final ok = await _store.signUp(name, email, password);
    if (ok && mounted) {
      Navigator.of(context).pushNamed(AppRoutes.verifyCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        body: ScreenBackground(
          glowAlignment: const Alignment(-0.45, -1),
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
                          'Start your\ncollection.',
                          style: AppText.display40.copyWith(fontSize: 37),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'One account keeps every plant, photo and care record '
                          'together.',
                          style: AppText.body15.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                        AppTextField(
                          label: 'Name',
                          hint: 'Your name',
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          onChanged: (_) => _store.clearError(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
                          hint: 'At least 8 characters',
                          controller: _password,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: _store.ratePassword,
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _StrengthMeter(
                          strength: _store.passwordStrength,
                          label: _store.passwordStrengthLabel,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppCheckbox(
                              value: _store.acceptedTerms,
                              onChanged: _store.setAcceptedTerms,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 11),
                                child: Text.rich(
                                  TextSpan(
                                    style: AppText.body15.copyWith(
                                      fontSize: 14,
                                    ),
                                    children: const [
                                      TextSpan(text: 'I agree to the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (_store.errorMessage != null) ...[
                          _FormError(message: _store.errorMessage!),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        AppButton.primary(
                          label: 'Create account',
                          loading: _store.isLoading,
                          onPressed: _store.canCreateAccount ? _submit : null,
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
                                'Already have an account?',
                                style: AppText.body15.copyWith(fontSize: 14),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              AppButton(
                                label: 'Sign in',
                                style: AppButtonStyle.link,
                                expand: false,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.signIn),
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

/// One place for anything that stopped the account being created — the field
/// checks and the backend's own message both land here.
class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.criticalTint,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PgIcon(
            PgIcons.alertCircle,
            size: 19,
            color: AppColors.criticalDeep,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.body13.copyWith(
                fontSize: 13,
                color: AppColors.criticalDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.label});

  final int strength;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              height: 5,
              decoration: BoxDecoration(
                color: i < strength ? AppColors.leaf : AppColors.track,
                borderRadius: AppRadius.pillR,
              ),
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.lg),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: AppText.heading17.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
