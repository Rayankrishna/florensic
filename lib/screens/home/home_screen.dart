import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/plant.dart';
import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/empty_state.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../shared/widgets/skeleton.dart';
import '../../stores/app_shell_store.dart';
import '../../domain/models/care_task.dart';
import '../../stores/insights_store.dart';
import '../../stores/notifications_store.dart';
import '../../stores/plant_collection_store.dart';
import '../../stores/profile_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';
import '../shell/app_shell.dart';
import 'home_attention_card.dart';
import 'home_environment_card.dart';

/// The home dashboard: who is looking, what needs attention, today's care and
/// the ambient reading.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = locator<PlantCollectionStore>();
    final insights = locator<InsightsStore>();
    final notifications = locator<NotificationsStore>();
    final profile = locator<ProfileStore>();

    return ScreenBackground(
      glowAlignment: const Alignment(0.35, -0.98),
      glowRadius: 0.75,
      glowOpacity: 0.85,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.ink,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await Future.wait([
              collection.loadPlants(force: true),
              insights.loadInsights(force: true),
            ]);
          },
          child: Observer(
            builder: (context) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, 0),
                    sliver: SliverList.list(
                      children: [
                        _GreetingRow(
                          initial: profile.initial,
                          name: profile.name.split(' ').first,
                          temperature: insights.weather?.temperatureC,
                          unread: notifications.unreadCount,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        const Text('My Plants', style: AppText.display40),
                        const SizedBox(height: AppSpacing.sm),
                        _AttentionSummary(
                          count: collection.attentionCount,
                          city: insights.city,
                          loading: collection.isLoading,
                        ),
                      ],
                    ),
                  ),
                  if (collection.isLoading && collection.plants.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.section, AppSpacing.gutter, 0),
                      sliver: SliverToBoxAdapter(child: _HomeSkeleton()),
                    )
                  else if (collection.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.xxxl, AppSpacing.gutter, 0),
                      sliver: SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'Your collection is waiting to grow.',
                          body: 'Scan a plant nearby and it arrives with a '
                              'profile, a care schedule and its own health '
                              'record.',
                          primaryLabel: 'Add your first plant',
                          primaryIcon: PgIcons.scan,
                          onPrimary: () =>
                              Navigator.of(context).pushNamed(AppRoutes.scan),
                          secondaryLabel: 'Browse the Pokedex',
                          onSecondary: () =>
                              Navigator.of(context).pushNamed(AppRoutes.pokedex),
                        ),
                      ),
                    )
                  else ...[
                    if (collection.needsAttention.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.section, AppSpacing.gutter, AppSpacing.lg),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'Needs attention',
                            trailing: 'See all',
                            onTrailingTap: () {
                              collection.setFilter(PlantFilter.needsAttention);
                              locator<AppShellStore>().select(1);
                            },
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _AttentionCarousel(
                          plants: collection.needsAttention,
                        ),
                      ),
                    ] else
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.gutter,
                            AppSpacing.section, AppSpacing.gutter, 0),
                        sliver: SliverToBoxAdapter(child: _AllCaughtUpCard()),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.section, AppSpacing.gutter, AppSpacing.lg),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                          title: "Today's care",
                          trailing:
                              '${collection.doneTaskCount} of ${collection.tasks.length} done',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter),
                      sliver: SliverList.separated(
                        itemCount: collection.tasks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final task = collection.tasks[index];
                          return Entrance(
                            index: index,
                            child: _CareTaskRow(
                              task: task,
                              onToggle: () => collection.completeTask(task.id),
                              onOpen: () {
                                final plant =
                                    collection.plantById(task.plantId);
                                if (plant == null) return;
                                if (task.kind == MetricKind.condition) {
                                  Navigator.of(context).pushNamed(
                                      AppRoutes.conditionUpdate,
                                      arguments: plant);
                                } else {
                                  Navigator.of(context).pushNamed(
                                      AppRoutes.plantDetail,
                                      arguments: plant);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                          AppSpacing.section, AppSpacing.gutter, 0),
                      sliver: SliverToBoxAdapter(
                        child: HomeEnvironmentCard(
                          insight: insights.homeInsight,
                          weather: insights.weather,
                          loading: insights.isLoading,
                          onOpen: () => locator<AppShellStore>().select(3),
                        ),
                      ),
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: SizedBox(height: navClearance(context)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.initial,
    required this.name,
    required this.temperature,
    required this.unread,
  });

  final String initial;
  final String name;
  final int? temperature;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9CCB6B), Color(0xFF7CB342)],
            ),
          ),
          child: Text(initial, style: AppText.heading20.copyWith(fontSize: 18.5)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppDate.greeting(),
                  style: AppText.body15.copyWith(fontSize: 15)),
              Text(name, style: AppText.heading20.copyWith(fontSize: 18.5)),
            ],
          ),
        ),
        if (temperature != null)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.pillR,
              boxShadow: AppShadows.raised,
            ),
            child: Row(
              children: [
                const PgIcon(PgIcons.sun, size: 21, color: AppColors.cautionDeep),
                const SizedBox(width: AppSpacing.sm),
                Text('$temperature°',
                    style: AppText.heading17.copyWith(fontSize: 16.5)),
              ],
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: PgIcons.bell,
              size: 48,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.notifications),
              semanticLabel: 'Notifications',
            ),
            if (unread > 0)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.leaf,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AttentionSummary extends StatelessWidget {
  const _AttentionSummary({
    required this.count,
    required this.city,
    required this.loading,
  });

  final int count;
  final String city;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Skeleton(width: 220, height: 16);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: count == 0 ? const Color(0xFF3E9B49) : AppColors.caution,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppText.body15.copyWith(fontSize: 16),
              children: [
                if (count == 0)
                  const TextSpan(
                    text: 'Nothing needs attention',
                    style: TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700),
                  )
                else ...[
                  TextSpan(
                    text: '$count plant${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' need attention'),
                ],
                TextSpan(text: ' · $city'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AttentionCarousel extends StatelessWidget {
  const _AttentionCarousel({required this.plants});

  final List<Plant> plants;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 268.0;
    return SizedBox(
      height: 242,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: plants.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) => Entrance(
          index: index,
          child: SizedBox(
            width: cardWidth,
            child: HomeAttentionCard(
              plant: plants[index],
              highlighted: index == 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _CareTaskRow extends StatelessWidget {
  const _CareTaskRow({
    required this.task,
    required this.onToggle,
    required this.onOpen,
  });

  final CareTask task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    final kind = task.kind;
    final overdue = task.overdue;

    return TileRow(
      icon: kind == MetricKind.watering ? PgIcons.droplet : PgIcons.camera,
      title: task.title,
      detail: task.detail,
      strikeThrough: done,
      background: done ? const Color(0xFFF7FAF9) : AppColors.surface,
      elevated: !done,
      detailColor: overdue ? AppColors.cautionDeep : null,
      iconBackground: done
          ? AppColors.softGreen
          : kind == MetricKind.watering
              ? AppColors.waterTint
              : AppColors.cautionTint,
      iconForeground: done
          ? AppColors.healthyDeep
          : kind == MetricKind.watering
              ? AppColors.waterDeep
              : AppColors.cautionDeep,
      leading: done
          ? Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(AppRadius.tile),
              ),
              child: const PgIcon(PgIcons.check,
                  size: 24, color: AppColors.healthyDeep),
            )
          : null,
      onTap: done ? null : onOpen,
      trailing: done
          ? null
          : kind == MetricKind.condition
              ? CircleIconButton(
                  icon: PgIcons.chevronRight,
                  size: 46,
                  background: AppColors.ink,
                  foreground: AppColors.leaf,
                  elevated: false,
                  onPressed: onOpen,
                )
              : Pressable(
                  onTap: onToggle,
                  scale: 0.9,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line, width: 1.6),
                    ),
                    child: const PgIcon(PgIcons.check,
                        size: 22, color: AppColors.inkMuted),
                  ),
                ),
    );
  }
}

class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      decoration: BoxDecoration(
        color: const Color(0xFFA9D183),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.raised,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -30,
            bottom: -40,
            width: 200,
            height: 200,
            child: PlantArtwork(
              glyph: PlantGlyph.pothos,
              showGround: false,
              tint: Color(0xFF243218),
              opacity: 0.55,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const PgIcon(PgIcons.check,
                      size: 24, color: AppColors.leaf),
                ),
                const Spacer(),
                Text('All caught up',
                    style: AppText.title28.copyWith(fontSize: 24)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Every plant is watered and checked in.',
                  style: AppText.body15
                      .copyWith(fontSize: 15, color: const Color(0xFF243517)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: 180, height: 22),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 242, radius: AppRadius.card),
        SizedBox(height: AppSpacing.section),
        Skeleton(width: 150, height: 22),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 84, radius: AppRadius.card),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 84, radius: AppRadius.card),
      ],
    );
  }
}
