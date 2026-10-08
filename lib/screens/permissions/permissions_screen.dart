import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/permissions_store.dart';
import '../../theme.dart';

/// `Help us understand your plants' environment.`
///
/// Each row shows what the OS actually allows and asks for it on the spot;
/// "Allow and continue" walks through every prompt still worth showing.
/// A permission cannot be switched off from inside the app, so a refused one
/// leads to Settings rather than pretending to toggle.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final PermissionsStore _store = locator<PermissionsStore>();
  bool _finishing = false;

  static const Map<PermissionKind, (PgIcons, Color, Color)> _visuals = {
    PermissionKind.camera: (
      PgIcons.camera,
      AppColors.softGreen,
      AppColors.healthyDeep
    ),
    PermissionKind.photoLibrary: (
      PgIcons.image,
      AppColors.neutralTint,
      AppColors.inkMuted
    ),
    PermissionKind.location: (
      PgIcons.pin,
      AppColors.waterTint,
      AppColors.waterDeep
    ),
  };

  @override
  void initState() {
    super.initState();
    _store.refresh();
  }

  Future<void> _allowAll() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await _store.requestAll();
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
    await _finish();
  }

  Future<void> _finish() async {
    await _store.complete();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.shell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        body: ScreenBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _finish,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text('Not now',
                              style: AppText.heading17.copyWith(
                                  fontSize: 16.5, color: AppColors.inkMuted)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Observer(
                    builder: (context) => ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.xl, AppSpacing.gutter, AppSpacing.lg),
                      children: [
                        Text(
                            "Help us understand\nyour plants'\nenvironment.",
                            style: AppText.display40.copyWith(fontSize: 33.5)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Three things make the advice specific to your '
                          "home. Allow what you're comfortable with — you can "
                          'change any of it later in Settings.',
                          style: AppText.body15.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                        for (final kind in PermissionKind.values) ...[
                          _PermissionRow(
                            kind: kind,
                            visuals: _visuals[kind]!,
                            state: _store.states[kind] ??
                                PermissionState.unknown,
                            busy: _store.requesting == kind,
                            onTap: _store.requesting == null
                                ? () => _store.request(kind)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        SoftCard(
                          color: const Color(0xFFE6EEEC),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          radius: AppRadius.tile,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: PgIcon(PgIcons.lock,
                                    size: 20, color: AppColors.inkMuted),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Location is only ever used to read the '
                                  'weather for your area. Photos stay in your '
                                  'collection unless you choose to share them.',
                                  style: AppText.body13.copyWith(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                      AppSpacing.sm, AppSpacing.gutter, AppSpacing.lg),
                  child: Observer(
                    builder: (context) => AppButton.primary(
                      // Once nothing is left to ask, the button just moves on.
                      label: _store.anyAskable
                          ? 'Allow and continue'
                          : 'Continue',
                      loading: _finishing,
                      onPressed: _store.anyAskable ? _allowAll : _finish,
                    ),
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

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.kind,
    required this.visuals,
    required this.state,
    required this.busy,
    required this.onTap,
  });

  final PermissionKind kind;
  final (PgIcons, Color, Color) visuals;
  final PermissionState state;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, fg) = visuals;
    final granted = state == PermissionState.granted;
    return Pressable(
      onTap: granted ? null : onTap,
      semanticLabel: kind.title,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: PgIcon(icon, size: 24, color: fg),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kind.title,
                      style: AppText.heading17.copyWith(fontSize: 16.5)),
                  const SizedBox(height: 3),
                  Text(
                    state == PermissionState.blocked
                        ? 'Turned off in Settings.'
                        : kind.body,
                    style: AppText.body13.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            switch (state) {
              PermissionState.granted => const TagPill(
                  label: 'Allowed',
                  tone: MetricStatus.good,
                  dense: true,
                ),
              PermissionState.blocked => AppButton.dark(
                  label: 'Settings',
                  expand: false,
                  height: 38,
                  fontSize: 13.5,
                  onPressed: onTap,
                ),
              PermissionState.denied ||
              PermissionState.unknown =>
                AppButton.primary(
                  label: 'Allow',
                  expand: false,
                  height: 38,
                  fontSize: 13.5,
                  loading: busy,
                  onPressed: onTap,
                ),
            },
          ],
        ),
      ),
    );
  }
}
