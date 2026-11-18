import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_bottom_sheet.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/notifications_store.dart';
import '../../stores/profile_store.dart';
import '../../theme.dart';
import '../shell/app_shell.dart';

/// `Profile` — who is signed in and how the collection is doing.
///
/// Only what works is on the page: the counts, the care streak once there
/// is one, notifications, and sign-out. Preferences the backend takes
/// (`PATCH /v1/me`) have no screen yet, so they are not listed either.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = locator<ProfileStore>();
    final notifications = locator<NotificationsStore>();

    return ScreenBackground(
      glow: false,
      bottomGlow: true,
      child: SafeArea(
        bottom: false,
        child: Observer(
          builder: (context) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xl,
                AppSpacing.gutter, navClearance(context)),
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        Text('Profile', style: AppText.title28.copyWith(fontSize: 24)),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleIconButton(
                        icon: PgIcons.bell,
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.notifications),
                        semanticLabel: 'Notifications',
                      ),
                      if (notifications.hasUnread)
                        Positioned(
                          top: 10,
                          right: 11,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: AppColors.leaf,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF9CCB6B), Color(0xFF7CB342)],
                      ),
                    ),
                    child: Text(store.initial,
                        style: AppText.display40.copyWith(fontSize: 30)),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display40.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          store.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body15.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              EqualHeightRow(
                spacing: AppSpacing.md,
                children: [
                  _StatCard(
                      value: '${store.plantsKept}', label: 'Plants kept'),
                  _StatCard(
                      value: '${store.underActiveCare}',
                      label: 'Under active care'),
                  // `null` means nothing under care has been scored yet,
                  // which is not the same as 0 % healthy.
                  _StatCard(
                    value: store.averageHealth?.toString() ?? '—',
                    label: store.averageHealth == null
                        ? 'Not scored yet'
                        : 'Avg. health',
                    dark: true,
                  ),
                ],
              ),
              // A streak is worth a card once there is one to show.
              if (store.careStreakWeeks > 0) ...[
                const SizedBox(height: AppSpacing.md),
                SoftCard(
                  color: AppColors.leafSoft,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(AppRadius.tile),
                        ),
                        child: const PgIcon(PgIcons.star,
                            size: 22, color: AppColors.ink),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${store.careStreakWeeks}-week care streak',
                              style:
                                  AppText.heading17.copyWith(fontSize: 16.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Every scheduled check-in done on time.',
                              style: AppText.body13.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF3F5015)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              const CaptionLabel('Account'),
              const SizedBox(height: AppSpacing.md),
              SettingsGroup(
                rows: [
                  SettingsRow(
                    icon: PgIcons.bell,
                    label: 'Notifications',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notifications),
                  ),
                  SettingsRow(
                    icon: PgIcons.arrowRight,
                    label: 'Sign out',
                    onTap: () => _confirmSignOut(context, store),
                  ),
                  const SettingsRow(
                    icon: PgIcons.leaf,
                    label: 'About Florensic',
                    value: 'v1.0',
                    showChevron: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, ProfileStore store) {
    AppBottomSheet.show<void>(
      context,
      builder: (sheetContext) => AppBottomSheet(
        actions: Row(
          children: [
            Expanded(
              child: AppButton.outline(
                label: 'Stay signed in',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Sign out',
                style: AppButtonStyle.danger,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  Navigator.of(sheetContext).pop();
                  await store.signOut();
                  navigator.pushNamedAndRemoveUntil(
                      AppRoutes.authLanding, (route) => false);
                },
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign out?', style: AppText.title28.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your collection stays on this account. You can sign back in '
              'at any time.',
              style: AppText.body15.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.dark = false,
  });

  final String value;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppText.metric.copyWith(
              fontSize: 30,
              color: dark ? AppColors.leaf : AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            maxLines: 2,
            style: AppText.body13.copyWith(
              fontSize: 13,
              color: dark ? const Color(0xFFB8C2BC) : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
