import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/plant_species.dart';
import '../../enum.dart';
import '../../key.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/add_plant_sheet.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';

/// A Pokedex entry: the reference record for one species.
class SpeciesDetailScreen extends StatefulWidget {
  const SpeciesDetailScreen({super.key, required this.species});

  final PlantSpecies species;

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  bool _adding = false;

  Future<void> _add() async {
    final nickname = await AddPlantSheet.show(context, widget.species);
    if (nickname == null || !mounted) return;

    setState(() => _adding = true);
    final plant = await locator<PlantCollectionStore>()
        .addPlant(widget.species, nickname: nickname);
    if (!mounted) return;
    setState(() => _adding = false);
    if (plant == null) return;
    HapticFeedback.mediumImpact();
    AppToast.show(
      context,
      message: '${plant.nickname} added to your collection',
      detail: 'Care schedule starts tomorrow',
      actionLabel: 'View',
      onAction: () => Navigator.of(context)
          .pushNamed(AppRoutes.plantDetail, arguments: plant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.species;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: AppKeys.speciesHero(s.id),
                          child: PlantArtwork(
                            glyph: s.glyph,
                            ground: s.ground,
                            inset: 0.05,
                          ),
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 90,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x00F1F7F6), AppColors.ground],
                              ),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.gutter),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    CircleIconButton(
                                      icon: PgIcons.chevronLeft,
                                      onPressed: () =>
                                          Navigator.of(context).maybePop(),
                                    ),
                                    const Spacer(),
                                    CircleIconButton(
                                      icon: PgIcons.bookmark,
                                      onPressed: () => AppToast.show(context,
                                          message: 'Saved to your shortlist'),
                                      semanticLabel: 'Save species',
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    CircleIconButton(
                                      icon: PgIcons.share,
                                      onPressed: () => AppToast.show(context,
                                          message: 'Sharing is not wired up '
                                              'in this build'),
                                      semanticLabel: 'Share species',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '№ ${s.number.toString().padLeft(3, '0')}',
                                  style: AppText.label13.copyWith(
                                    fontSize: 13,
                                    color: AppColors.healthyDeep,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter, 0, AppSpacing.gutter, 0),
                  sliver: SliverList.list(
                    children: [
                      Text(s.commonName,
                          style: AppText.display40.copyWith(fontSize: 37)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        s.latinName,
                        style: AppText.body15.copyWith(
                            fontSize: 16.5, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final tag in s.tags)
                            TagPill(
                              label: tag.label,
                              tone: switch (tag.tone) {
                                SpeciesTagTone.positive => MetricStatus.good,
                                SpeciesTagTone.warning => MetricStatus.bad,
                                SpeciesTagTone.neutral => MetricStatus.neutral,
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(s.summary,
                          style: AppText.body15.copyWith(fontSize: 16)),
                      const SizedBox(height: AppSpacing.xl),
                      EqualHeightRow(
                        children: [
                          _CareFact(
                              icon: PgIcons.sun,
                              iconColor: AppColors.cautionDeep,
                              label: 'Light',
                              value: s.light),
                          _CareFact(
                              icon: PgIcons.droplet,
                              iconColor: AppColors.waterDeep,
                              label: 'Water',
                              value: s.water),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      EqualHeightRow(
                        children: [
                          _CareFact(
                              icon: PgIcons.thermometer,
                              iconColor: AppColors.ink,
                              label: 'Temperature',
                              value: s.temperature),
                          _CareFact(
                              icon: PgIcons.dropletDouble,
                              iconColor: AppColors.waterDeep,
                              label: 'Humidity',
                              value: s.humidity),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        padding:
                            const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Origin & growth',
                                style:
                                    AppText.heading20.copyWith(fontSize: 20.5)),
                            const SizedBox(height: AppSpacing.lg),
                            _FactLine(
                                label: 'Native range', value: s.nativeRange),
                            const Divider(
                                height: AppSpacing.xxl, color: AppColors.line),
                            _FactLine(
                                label: 'Mature height', value: s.matureHeight),
                            const Divider(
                                height: AppSpacing.xxl, color: AppColors.line),
                            _FactLine(
                                label: 'Growth habit', value: s.growthHabit),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const SectionHeader(title: 'Common issues'),
                      const SizedBox(height: AppSpacing.lg),
                      for (final issue in s.commonIssues) ...[
                        TileRow(
                          icon: issue.tone == MetricStatus.watch
                              ? PgIcons.alertTriangle
                              : PgIcons.leaf,
                          title: issue.title,
                          detail: issue.body,
                          tone: issue.tone,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      SoftCard(
                        color: AppColors.leafSoft,
                        padding:
                            const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Care tips',
                                style:
                                    AppText.heading20.copyWith(fontSize: 20.5)),
                            const SizedBox(height: AppSpacing.lg),
                            for (final tip in s.careTips) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 9),
                                    child: SizedBox(
                                      width: 6,
                                      height: 6,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.ink,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(tip,
                                        style: AppText.body15Ink
                                            .copyWith(fontSize: 15)),
                                  ),
                                ],
                              ),
                              if (tip != s.careTips.last)
                                const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: 110 + MediaQuery.viewPaddingOf(context).bottom),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.xxxl,
                  AppSpacing.gutter,
                  MediaQuery.viewPaddingOf(context).bottom + AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00F1F7F6),
                      AppColors.ground,
                      AppColors.ground
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.primary(
                        label: 'Add to My Plants',
                        loading: _adding,
                        onPressed: _add,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    CircleIconButton(
                      icon: PgIcons.scan,
                      size: 58,
                      background: AppColors.ink,
                      foreground: AppColors.leaf,
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.scan),
                      semanticLabel: 'Identify a plant',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareFact extends StatelessWidget {
  const _CareFact({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final PgIcons icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PgIcon(icon, size: 22, color: iconColor),
          const SizedBox(height: AppSpacing.lg),
          Text(label, style: AppText.body15.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppText.heading20.copyWith(fontSize: 17.5)),
        ],
      ),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body15.copyWith(fontSize: 15)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppText.heading17.copyWith(fontSize: 15.5),
          ),
        ),
      ],
    );
  }
}
