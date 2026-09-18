import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/notifications_store.dart';
import '../../stores/profile_store.dart';
import '../../theme.dart';
import '../shell/app_shell.dart';

/// `Profile` — who is signed in, how the collection is doing, and the
/// preferences that shape the advice.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = locator<ProfileStore>();
    final notifications = locator<NotificationsStore>();

    return ScreenBackground(
      glow: false,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF9CCB6B), Color(0xFF7CB342)],
                      ),
                    ),
                    child: Text(store.initial,
                        style: AppText.display40.copyWith(fontSize: 35.5)),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name,
                            style: AppText.display40.copyWith(fontSize: 28)),
                        const SizedBox(height: 3),
                        Text(store.email,
                            style: AppText.body15.copyWith(fontSize: 15)),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Edit profile',
                          style: AppButtonStyle.link,
                          expand: false,
                          fontSize: 15,
                          onPressed: () => AppToast.show(context,
                              message: 'Profile editing',
                              detail: 'Not available in this build'),
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
                  _StatCard(
                    value: '${store.averageHealth}',
                    label: 'Avg. health',
                    dark: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SoftCard(
                color: AppColors.leafSoft,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                      child: const PgIcon(PgIcons.star,
                          size: 24, color: AppColors.ink),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${store.careStreakWeeks}-week care streak',
                              style: AppText.heading17.copyWith(fontSize: 16.5)),
                          const SizedBox(height: 2),
                          Text(
                            'Every scheduled check-in since '
                            '${store.streakSince}.',
                            style: AppText.body13.copyWith(
                                fontSize: 14, color: const Color(0xFF3F5015)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              const CaptionLabel('Care'),
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
                    icon: PgIcons.calendar,
                    label: 'Reminder preferences',
                    value: store.reminderTime,
                    onTap: () => AppToast.show(context,
                        message: 'Reminder preferences',
                        detail: 'Not available in this build'),
                  ),
                  SettingsRow(
                    icon: PgIcons.pin,
                    label: 'Location & weather',
                    value: store.city,
                    onTap: () => AppToast.show(context,
                        message: 'Location settings',
                        detail: 'Not available in this build'),
                  ),
                  SettingsRow(
                    icon: PgIcons.thermometer,
                    label: 'Units',
                    value: store.units,
                    onTap: () => AppToast.show(context,
                        message: 'Unit settings',
                        detail: 'Not available in this build'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              const CaptionLabel('Account'),
              const SizedBox(height: AppSpacing.md),
              SettingsGroup(
                rows: [
                  SettingsRow(
                    icon: PgIcons.person,
                    label: 'Account',
                    onTap: () => _confirmSignOut(context, store),
                  ),
                  SettingsRow(
                    icon: PgIcons.lock,
                    label: 'Privacy',
                    onTap: () => AppToast.show(context,
                        message: 'Privacy settings',
                        detail: 'Not available in this build'),
                  ),
                  SettingsRow(
                    icon: PgIcons.help,
                    label: 'Help & support',
                    onTap: () => AppToast.show(context,
                        message: 'Help & support',
                        detail: 'Not available in this build'),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C0B1A0F),
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.ground,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.track,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text('Sign out?', style: AppText.title28.copyWith(fontSize: 24)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your collection stays on this account. You can sign back in '
                  'at any time.',
                  style: AppText.body15.copyWith(fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
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
              ],
            ),
          ),
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
