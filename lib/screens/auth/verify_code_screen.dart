import 'dart:async';

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_store.pendingEmail.isEmpty) {
      _store.pendingEmail = 'alex.moreau@studio.co';
    }
    // Seed the first digits so the screen reads as the design shows it.
    for (var i = 0; i < 3; i++) {
      _store.setCodeDigit(i, ['4', '1', '9'][i]);
    }
    _hidden.text = _store.codeValue;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _store.tickResend();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.dispose();
    _hidden.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < 6; i++) {
      _store.setCodeDigit(i, i < digits.length ? digits[i] : '');
    }
  }

  Future<void> _verify() async {
    final ok = await _store.verifyCode();
    if (ok && mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.onboarding, (route) => false);
    }
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
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.lg, AppSpacing.gutter, AppSpacing.gutter),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleIconButton(
                          icon: PgIcons.chevronLeft,
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const PgIcon(PgIcons.mail,
                            size: 32, color: AppColors.leaf),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text('Check your inbox.',
                          style: AppText.display40.copyWith(fontSize: 35.5)),
                      const SizedBox(height: AppSpacing.md),
                      Text.rich(
                        TextSpan(
                          style: AppText.body15.copyWith(fontSize: 16),
                          children: [
                            const TextSpan(text: 'We sent a six-digit code to '),
                            TextSpan(
                              text: _store.pendingEmail,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var i = 0; i < 6; i++)
                            CodeField(
                              value: _store.code[i],
                              focused: i == _store.codeValue.length,
                              onTap: () => _focus.requestFocus(),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Didn't get it?",
                              style: AppText.body15.copyWith(fontSize: 15)),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: _store.resendSeconds > 0
                                ? 'Resend in 0:${_store.resendSeconds.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: AppButtonStyle.link,
                            expand: false,
                            onPressed: _store.resendSeconds > 0
                                ? null
                                : () => _store.requestCode(_store.pendingEmail),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton.primary(
                        label: 'Verify and continue',
                        loading: _store.isLoading,
                        onPressed: _store.canVerify ? _verify : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.softGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const PgIcon(PgIcons.check,
                                  size: 24, color: AppColors.healthyDeep),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Password reset complete',
                                      style: AppText.heading17
                                          .copyWith(fontSize: 16)),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Shown here as the same confirmation '
                                    'pattern used after a reset link is '
                                    'followed.',
                                    style:
                                        AppText.body13.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Wrong address?',
                              style: AppText.body15.copyWith(fontSize: 14)),
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
