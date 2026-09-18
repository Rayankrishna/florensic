import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/notification_item.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/empty_state.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../shared/widgets/skeleton.dart';
import '../../stores/notifications_store.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';

/// `Notifications` — grouped by day, filterable by kind.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsStore _store = locator<NotificationsStore>();

  @override
  void initState() {
    super.initState();
    _store.loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: ScreenBackground(
          glow: false,
          child: SafeArea(
            child: Observer(
              builder: (context) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.lg, AppSpacing.gutter, 0),
                      sliver: SliverToBoxAdapter(
                        child: NavHeader(
                          title: 'Notifications',
                          onBack: () => Navigator.of(context).maybePop(),
                          trailing: _MarkReadButton(
                            enabled: _store.hasUnread,
                            onTap: _store.markAllRead,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 44 + AppSpacing.xl * 2,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                              AppSpacing.xl, AppSpacing.gutter, AppSpacing.xl),
                          itemCount: NotificationFilter.values.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final filter = NotificationFilter.values[index];
                            return FilterChipPill(
                              label: filter.label,
                              selected: _store.filter == filter,
                              selectedColor: AppColors.ink,
                              selectedLabelColor: Colors.white,
                              onTap: () => _store.setFilter(filter),
                            );
                          },
                        ),
                      ),
                    ),
                    if (_store.isLoading && _store.items.isEmpty)
                      const SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Skeleton(height: 96, radius: AppRadius.card),
                              SizedBox(height: AppSpacing.md),
                              Skeleton(height: 96, radius: AppRadius.card),
                              SizedBox(height: AppSpacing.md),
                              Skeleton(height: 96, radius: AppRadius.card),
                            ],
                          ),
                        ),
                      )
                    else if (_store.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.xxxl, AppSpacing.gutter, 0),
                        sliver: SliverToBoxAdapter(
                          child: EmptyState(
                            compact: true,
                            icon: PgIcons.bell,
                            title: 'Nothing here yet',
                            body: 'Nothing in this category. Reminders arrive '
                                'before trouble does.',
                            primaryLabel: 'Show all',
                            onPrimary: () =>
                                _store.setFilter(NotificationFilter.all),
                          ),
                        ),
                      )
                    else
                      for (final group in _store.grouped) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                              AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
                          sliver: SliverToBoxAdapter(
                            child: CaptionLabel(group.key),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.gutter),
                          sliver: SliverList.separated(
                            itemCount: group.value.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) => Entrance(
                              index: index,
                              child: _NotificationRow(
                                item: group.value[index],
                                onTap: () => _open(group.value[index]),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                            child: SizedBox(height: AppSpacing.xl)),
                      ],
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.xxl, AppSpacing.gutter, AppSpacing.xxxl),
                        child: Center(
                          child: AppButton(
                            label: 'Reminder settings',
                            style: AppButtonStyle.link,
                            expand: false,
                            onPressed: () =>
                                Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _open(AppNotification item) {
    final id = item.plantId;
    if (id == null) return;
    final plant = locator<PlantCollectionStore>().plantById(id);
    if (plant == null) return;
    Navigator.of(context)
        .pushNamed(AppRoutes.plantDetail, arguments: plant);
  }
}

class _MarkReadButton extends StatelessWidget {
  const _MarkReadButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.pillR,
            boxShadow: AppShadows.raised,
          ),
          child: Text('Mark read',
              style: AppText.heading17.copyWith(fontSize: 15)),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plant = item.plantId == null
        ? null
        : locator<PlantCollectionStore>().plantById(item.plantId!);

    final (icon, tone) = switch (item.kind) {
      NotificationKind.conditionUpdate => (PgIcons.camera, MetricStatus.watch),
      NotificationKind.watering => (PgIcons.droplet, MetricStatus.neutral),
      NotificationKind.environment =>
        (PgIcons.thermometer, MetricStatus.watch),
      NotificationKind.healthChange => (PgIcons.chart, MetricStatus.good),
      NotificationKind.checkInMissed => (PgIcons.alertCircle, MetricStatus.bad),
      NotificationKind.appUpdate => (PgIcons.leaf, MetricStatus.neutral),
    };

    return TileRow(
      icon: icon,
      tone: tone,
      title: item.title,
      detail: item.detail,
      detailColor: item.kind == NotificationKind.conditionUpdate
          ? AppColors.cautionDeep
          : null,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      leading: plant == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.tile),
              child: SizedBox(
                width: 56,
                height: 56,
                child: PlantArtwork(
                  glyph: plant.species.glyph,
                  ground: plant.species.ground,
                  inset: 0.2,
                ),
              ),
            ),
      trailing: item.unread
          ? Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: AppColors.leaf,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
