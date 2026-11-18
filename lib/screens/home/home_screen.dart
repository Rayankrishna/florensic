import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/empty_state.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/health_ring.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../shared/widgets/skeleton.dart';
import '../../stores/app_shell_store.dart';
import '../../stores/insights_store.dart';
import '../../stores/notifications_store.dart';
import '../../stores/plant_collection_store.dart';
import '../../stores/profile_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';
import '../shell/app_shell.dart';
import 'home_attention_card.dart';
import 'home_care_card.dart';
import 'home_environment_card.dart';

/// The home dashboard: who is looking, what needs attention, today's care and
/// the ambient reading.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Needs attention shows the most urgent few; "See all" has the rest.
  static const int _attentionFold = 3;

  @override
  Widget build(BuildContext context) {
    final collection = locator<PlantCollectionStore>();
    final insights = locator<InsightsStore>();
    final notifications = locator<NotificationsStore>();
    final profile = locator<ProfileStore>();

    return ScreenBackground(
      glowAlignment: const Alignment(0, -1.0),
      glowRadius: 0.8,
      glowOpacity: 0.85,
      bottomGlow: true,
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
              // The day folded by kind — four rows at most, however many
              // plants want something. The full list is a tap away.
              final care = summariseToday(
                collection.tasks,
                (id) => collection.plantById(id)?.nickname,
              );
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.md,
                      AppSpacing.gutter,
                      0,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _GreetingRow(
                          initial: profile.initial,
                          name: profile.name.split(' ').first,
                          temperature: insights.weather?.temperatureC,
                          unread: notifications.unreadCount,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _CollectionHeader(
                          attentionCount: collection.attentionCount,
                          // Null when there is no reading, rather than the
                          // store's '—' placeholder.
                          city: insights.weather?.city,
                          averageHealth: collection.averageHealth,
                          // First load only: a refresh keeps what is shown.
                          loading: collection.isLoading &&
                              collection.plants.isEmpty,
                          // An empty collection has its own empty state.
                          showRing: collection.plants.isNotEmpty ||
                              collection.isLoading,
                          onOpenHealth: () {
                            collection.setFilter(PlantFilter.all);
                            locator<AppShellStore>().select(1);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (collection.isLoading && collection.plants.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.xxl,
                        AppSpacing.gutter,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(child: _HomeSkeleton()),
                    )
                  else if (collection.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.xxxl,
                        AppSpacing.gutter,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: EmptyState(
                          title: 'Your collection is waiting to grow.',
                          body:
                              'Scan a plant nearby and it arrives with a '
                              'profile, a care schedule and its own health '
                              'record.',
                          primaryLabel: 'Add your first plant',
                          primaryIcon: PgIcons.scan,
                          onPrimary: () =>
                              Navigator.of(context).pushNamed(AppRoutes.scan),
                          secondaryLabel: 'Browse the Plantdex',
                          onSecondary: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.plantdex),
                        ),
                      ),
                    )
                  else ...[
                    if (collection.needsAttention.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.xxl,
                          AppSpacing.gutter,
                          AppSpacing.md,
                        ),
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
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        sliver: SliverList.separated(
                          itemCount: math.min(
                            collection.needsAttention.length,
                            _attentionFold,
                          ),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) => Entrance(
                            index: index,
                            child: HomeAttentionCard(
                              plant: collection.needsAttention[index],
                              highlighted: index == 0,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.xxl,
                          AppSpacing.gutter,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(child: _AllCaughtUpCard()),
                      ),
                    // With nothing scheduled there is no day to fold.
                    if (care.isNotEmpty) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.xxl,
                          AppSpacing.gutter,
                          AppSpacing.md,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: SectionHeader(
                            title: "Today's care",
                            trailing: 'View all',
                            onTrailingTap: () => Navigator.of(context)
                                .pushNamed(AppRoutes.todaysCare),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.gutter,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: TodayCareCard(
                            summaries: care,
                            onOpenKind: (kind) => Navigator.of(context)
                                .pushNamed(AppRoutes.todaysCare,
                                    arguments: kind),
                          ),
                        ),
                      ),
                    ],
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.xxl,
                        AppSpacing.gutter,
                        0,
                      ),
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
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9CCB6B), Color(0xFF7CB342)],
            ),
          ),
          child: Text(
            initial,
            style: AppText.heading20.copyWith(fontSize: 16),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppDate.greeting(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body15.copyWith(fontSize: 13.5),
              ),
              // One line, so a long name cannot make the header taller.
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.heading20.copyWith(fontSize: 17),
              ),
            ],
          ),
        ),
        if (temperature != null)
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.pillR,
              boxShadow: AppShadows.raised,
            ),
            child: Row(
              children: [
                const PgIcon(
                  PgIcons.sun,
                  size: 18,
                  color: AppColors.cautionDeep,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$temperature°',
                  style: AppText.heading17.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: PgIcons.bell,
              size: 42,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.notifications),
              semanticLabel:
                  unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
            ),
            if (unread > 0)
              Positioned(
                top: 7,
                right: 8,
                child: IgnorePointer(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.leaf,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "My Plants" and what wants attention on the left; the collection's
/// average health on the right, so the block under the greeting carries
/// weight on both sides — the ring sits under the bell, on the same edge.
/// It is no taller than the two lines beside it, so the header keeps its
/// height.
class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({
    required this.attentionCount,
    required this.city,
    required this.averageHealth,
    required this.loading,
    required this.showRing,
    required this.onOpenHealth,
  });

  final int attentionCount;
  final String? city;
  final int? averageHealth;
  final bool loading;
  final bool showRing;
  final VoidCallback onOpenHealth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Plants',
                  style: AppText.display40.copyWith(fontSize: 32)),
              const SizedBox(height: AppSpacing.xs),
              _AttentionSummary(
                count: attentionCount,
                city: city,
                loading: loading,
              ),
            ],
          ),
        ),
        if (showRing) ...[
          const SizedBox(width: AppSpacing.lg),
          _CollectionHealthRing(
            score: averageHealth,
            loading: loading,
            onTap: onOpenHealth,
          ),
        ],
      ],
    );
  }
}

/// The collection's average health on a white disc, drawn with the plant
/// page's own ring. The number takes its band's deep colour, as the score
/// badge on the plant cards does.
///
/// `null` means no plant under care has been scored yet: the ring is the
/// beaded "not scored" one with a camera, as on an unscored plant's page —
/// never a 0. Tapping opens My Plants; a long press says what the number is.
class _CollectionHealthRing extends StatelessWidget {
  const _CollectionHealthRing({
    required this.score,
    required this.loading,
    required this.onTap,
  });

  /// The height of the title and attention lines beside it.
  static const double _size = 60;
  static const double _inset = 4;
  static const double _stroke = 5;

  final int? score;
  final bool loading;
  final VoidCallback onTap;

  static Color _numberColor(int score) =>
      switch (HealthBandX.fromScore(score)) {
        HealthBand.thriving => AppColors.healthyDeep,
        HealthBand.watch => AppColors.cautionDeep,
        HealthBand.critical => AppColors.criticalDeep,
        null => AppColors.inkMuted,
      };

  @override
  Widget build(BuildContext context) {
    // One pixel down puts the ring's centre on the two lines' ink centre.
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: loading ? const Skeleton.circle(size: _size) : _ring(),
    );
  }

  Widget _ring() {
    final s = score;
    return Tooltip(
      message: s == null
          ? 'Not scored yet — a check-in photo scores a plant'
          : 'Average plant health',
      excludeFromSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.94,
        semanticLabel: s == null
            ? 'Average plant health, not scored yet'
            : 'Average plant health $s',
        child: ExcludeSemantics(
          child: Container(
            width: _size,
            height: _size,
            padding: const EdgeInsets.all(_inset),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.raised,
            ),
            child: HealthRing(
              score: s,
              size: _size - _inset * 2,
              strokeWidth: _stroke,
              // Kept inside the stroke, and scaled down rather than clipped
              // when large text or a 100 would reach the arc.
              child: Padding(
                padding: const EdgeInsets.all(_stroke + 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: s == null
                      ? const PgIcon(
                          PgIcons.camera,
                          size: 18,
                          color: AppColors.inkMuted,
                        )
                      : AnimatedScore(
                          value: s,
                          style: AppText.metric.copyWith(
                            fontSize: s >= 100 ? 17 : 19,
                            letterSpacing: -0.6,
                            color: _numberColor(s),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
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

  /// Null or blank when no place is known; the line then ends at the count
  /// instead of reading "· —".
  final String? city;
  final bool loading;

  static String? _knownPlace(String? city) {
    final c = city?.trim();
    if (c == null || c.isEmpty || c == '—') return null;
    return c;
  }

  TextSpan _line(String? place) => TextSpan(
        // Even leading centres the status dot on the text.
        style: AppText.body15.copyWith(
          fontSize: 16,
          leadingDistribution: TextLeadingDistribution.even,
        ),
        children: [
          if (count == 0)
            const TextSpan(
              text: 'Nothing needs attention',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            )
          else ...[
            TextSpan(
              text: '$count plant${count == 1 ? '' : 's'}',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: ' need${count == 1 ? 's' : ''} attention'),
          ],
          if (place != null) TextSpan(text: ' · $place'),
        ],
      );

  static bool _fits(BuildContext context, TextSpan line, double width) {
    final painter = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [line],
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Skeleton(width: 220, height: 16);
    final place = _knownPlace(city);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: count == 0 ? AppColors.leaf : AppColors.caution,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The ring takes the right edge, so the line has less room.
              // The place goes first rather than being cut mid-word; the
              // count always stays.
              var line = _line(place);
              if (place != null &&
                  !_fits(context, line, constraints.maxWidth)) {
                line = _line(null);
              }
              return Text.rich(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AllCaughtUpCard extends StatelessWidget {
  const _AllCaughtUpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: const Color(0xFFA9D183),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.raised,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            right: -26,
            bottom: -34,
            width: 140,
            height: 140,
            child: PlantArtwork(
              glyph: PlantGlyph.pothos,
              showGround: false,
              tint: Color(0xFF243218),
              opacity: 0.55,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const PgIcon(
                    PgIcons.check,
                    size: 22,
                    color: AppColors.healthyDeep,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All caught up',
                        style: AppText.title28.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Every plant is watered and checked in.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body15.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF243517),
                        ),
                      ),
                    ],
                  ),
                ),
                // Room for the artwork peeking in from the corner.
                const SizedBox(width: 56),
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
        SizedBox(height: AppSpacing.xxl),
        Skeleton(width: 150, height: 22),
        SizedBox(height: AppSpacing.lg),
        Skeleton(height: 84, radius: AppRadius.card),
        SizedBox(height: AppSpacing.md),
        Skeleton(height: 84, radius: AppRadius.card),
      ],
    );
  }
}
