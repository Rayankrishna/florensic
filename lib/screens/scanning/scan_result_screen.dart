import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/repositories/identification_repository.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/add_plant_sheet.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../stores/pokedex_store.dart';
import '../../stores/scanning_store.dart';
import '../../theme.dart';

/// `Match found` — the identification result, its confidence, and the way
/// back out if it is wrong.
class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = locator<ScanningStore>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: Observer(
          builder: (context) {
            final result = store.result;
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final species = result.species;
            return Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF1E3F26),
                                    Color(0xFF29552F)
                                  ],
                                ),
                              ),
                            ),
                            PlantArtwork(
                              glyph: species.glyph,
                              showGround: false,
                              tint: const Color(0xFF050D05),
                              inset: 0.04,
                            ),
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.gutter,
                                    AppSpacing.md,
                                    AppSpacing.gutter,
                                    0),
                                child: Row(
                                  children: [
                                    CircleIconButton(
                                      icon: PgIcons.chevronLeft,
                                      background: const Color(0x33FFFFFF),
                                      foreground: Colors.white,
                                      elevated: false,
                                      onPressed: () {
                                        store.resetScan();
                                        Navigator.of(context).maybePop();
                                      },
                                    ),
                                    const Spacer(),
                                    TweenAnimationBuilder<double>(
                                      tween:
                                          Tween<double>(begin: 0.85, end: 1),
                                      duration:
                                          const Duration(milliseconds: 420),
                                      curve: Curves.easeOutBack,
                                      builder: (context, t, child) =>
                                          Transform.scale(
                                              scale: t, child: child),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xl,
                                            vertical: 13),
                                        decoration: const BoxDecoration(
                                          color: AppColors.leaf,
                                          borderRadius: AppRadius.pillR,
                                        ),
                                        child: Text('Match found',
                                            style: AppText.heading17
                                                .copyWith(fontSize: 16)),
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
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: const Offset(0, -28),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.ground,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(AppRadius.card)),
                          ),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                              AppSpacing.xxl, AppSpacing.gutter, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(species.commonName,
                                  style: AppText.display40
                                      .copyWith(fontSize: 37)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                species.latinName,
                                style: AppText.body15.copyWith(
                                    fontSize: 16.5,
                                    fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _ConfidenceCard(result: result),
                              const SizedBox(height: AppSpacing.xl),
                              Text(species.summary,
                                  style:
                                      AppText.body15.copyWith(fontSize: 16)),
                              const SizedBox(height: AppSpacing.xl),
                              EqualHeightRow(
                                spacing: AppSpacing.md,
                                children: [
                                  _MiniFact(
                                      icon: PgIcons.leaf,
                                      iconColor: AppColors.healthyDeep,
                                      label: 'Difficulty',
                                      value: species.difficulty),
                                  _MiniFact(
                                      icon: PgIcons.sun,
                                      iconColor: AppColors.cautionDeep,
                                      label: 'Light',
                                      value: species.shortLight),
                                  _MiniFact(
                                      icon: PgIcons.droplet,
                                      iconColor: AppColors.waterDeep,
                                      label: 'Water',
                                      value: '${species.wateringIntervalDays}'
                                          '–${species.wateringIntervalDays + 3} days'),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.section),
                              const SectionHeader(
                                title: 'Not quite it?',
                                trailing: 'Other possible matches',
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _Alternatives(result: result),
                              SizedBox(
                                  height: 150 +
                                      MediaQuery.viewPaddingOf(context)
                                          .bottom),
                            ],
                          ),
                        ),
                      ),
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
                        stops: [0, 0.4, 1],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppButton.primary(
                          label: 'Add to My Plants',
                          loading: store.isAdding,
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final nickname =
                                await AddPlantSheet.show(context, species);
                            if (nickname == null || !context.mounted) return;
                            final plant =
                                await store.addToCollection(nickname: nickname);
                            if (plant == null || !context.mounted) return;
                            HapticFeedback.mediumImpact();
                            navigator.popUntil((route) => route.isFirst);
                            AppToast.show(
                              context,
                              message:
                                  '${plant.nickname} added to your collection',
                              detail: 'Care schedule starts tomorrow',
                              actionLabel: 'View',
                              onAction: () => navigator.pushNamed(
                                  AppRoutes.plantDetail,
                                  arguments: plant),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'View in Pokedex',
                          style: AppButtonStyle.link,
                          onPressed: () {
                            locator<PokedexStore>().clearFilters();
                            Navigator.of(context).pushReplacementNamed(
                              AppRoutes.speciesDetail,
                              arguments: species,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.result});

  final IdentificationResult result;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Identification confidence',
                    style: AppText.body15Ink.copyWith(fontSize: 16)),
              ),
              Text('${result.confidence}%',
                  style: AppText.title28.copyWith(fontSize: 24)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: AppRadius.pillR,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: result.confidence / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.track,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.leaf),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(result.rationale, style: AppText.body15.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

class _MiniFact extends StatelessWidget {
  const _MiniFact({
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PgIcon(icon, size: 20, color: iconColor),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: AppText.body13.copyWith(fontSize: 13)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.heading17.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _Alternatives extends StatelessWidget {
  const _Alternatives({required this.result});

  final IdentificationResult result;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final alt in result.alternatives) ...[
            Pressable(
              onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.speciesDetail,
                  arguments: alt.species),
              child: Container(
                width: 140,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardR,
                  boxShadow: AppShadows.raised,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 92,
                      child: PlantArtwork(
                        glyph: alt.species.glyph,
                        ground: alt.species.ground,
                        inset: 0.16,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alt.shortName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.heading17.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text('${alt.confidence}% match',
                              style: AppText.body13.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Pressable(
            onTap: () => Navigator.of(context)
                .pushReplacementNamed(AppRoutes.pokedex),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: AppRadius.cardR,
                border: Border.all(color: AppColors.line, width: 1.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PgIcon(PgIcons.search,
                      size: 26, color: AppColors.inkMuted),
                  const SizedBox(height: AppSpacing.md),
                  Text('Search\nmanually',
                      textAlign: TextAlign.center,
                      style: AppText.heading17.copyWith(fontSize: 15)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
