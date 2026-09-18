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

/// `Welcome back.`
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController(text: 'alex.moreau@studio.co');
  final _password = TextEditingController(text: 'plantgram');
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ok = await _store.signIn(_email.text.trim(), _password.text);
    if (ok && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.onboarding, (route) => false);
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
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.lg, AppSpacing.gutter, AppSpacing.gutter),
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
                        Text('Welcome back.',
                            style: AppText.display40.copyWith(fontSize: 37)),
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
                        Row(
                          children: [
                            AppCheckbox(
                              value: _store.keepSignedIn,
                              onChanged: _store.setKeepSignedIn,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Keep me signed in',
                                style: AppText.body15.copyWith(fontSize: 15)),
                            const Spacer(),
                            AppButton(
                              label: 'Forgot password?',
                              style: AppButtonStyle.link,
                              expand: false,
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(AppRoutes.verifyCode),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        AppButton.primary(
                          label: 'Sign in',
                          loading: _store.isLoading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: AppColors.line)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg),
                              child: Text('or',
                                  style: AppText.body15.copyWith(fontSize: 14)),
                            ),
                            const Expanded(
                                child: Divider(color: AppColors.line)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton.outline(
                                label: 'Apple',
                                icon: PgIcons.apple,
                                onPressed: () => _provider('apple'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppButton.outline(
                                label: 'Google',
                                icon: PgIcons.google,
                                onPressed: () => _provider('google'),
                              ),
                            ),
                          ],
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
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No account yet?',
                                  style:
                                      AppText.body15.copyWith(fontSize: 14)),
                              const SizedBox(width: AppSpacing.sm),
                              AppButton(
                                label: 'Sign up',
                                style: AppButtonStyle.link,
                                expand: false,
                                onPressed: () => Navigator.of(context)
                                    .pushReplacementNamed(AppRoutes.signUp),
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

  Future<void> _provider(String name) async {
    final ok = await _store.continueWithProvider(name);
    if (ok && mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.onboarding, (route) => false);
    }
  }
}
