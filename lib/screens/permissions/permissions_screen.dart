import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/permissions_store.dart';
import '../../theme.dart';

/// `Help us understand your plants' environment.`
///
/// Toggles here record the keeper's intent. Requesting the matching platform
/// permission happens when the feature is first used.
class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  static const Map<PermissionKind, (PgIcons, Color, Color)> _visuals = {
    PermissionKind.location: (
      PgIcons.pin,
      AppColors.waterTint,
      AppColors.waterDeep
    ),
    PermissionKind.reminders: (
      PgIcons.bell,
      AppColors.leafSoft,
      AppColors.healthyDeep
    ),
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
  };

  Future<void> _finish(BuildContext context) async {
    final store = locator<PermissionsStore>();
    await store.complete();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.shell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final store = locator<PermissionsStore>();
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
                      CircleIconButton(
                        icon: PgIcons.chevronLeft,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _finish(context),
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
                          'Four things make the advice specific to your home. '
                          "Turn on what you're comfortable with — you can change "
                          'any of it later.',
                          style: AppText.body15.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                        for (final kind in PermissionKind.values) ...[
                          _PermissionRow(
                            kind: kind,
                            value: store.granted[kind] ?? false,
                            onChanged: (_) => store.toggle(kind),
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
                  child: AppButton.primary(
                    label: 'Allow and continue',
                    onPressed: () => _finish(context),
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
    required this.value,
    required this.onChanged,
  });

  final PermissionKind kind;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, fg) = PermissionsScreen._visuals[kind]!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(kind.body, style: AppText.body13.copyWith(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: AppSwitch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
