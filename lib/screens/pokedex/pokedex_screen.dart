import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/empty_state.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/components/plant_card.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/components/pressable.dart';
import '../../shared/widgets/plant_artwork.dart';
import '../../shared/widgets/skeleton.dart';
import '../../stores/pokedex_store.dart';
import '../../theme.dart';
import '../shell/app_shell.dart';

/// `Pokedex` — species discovery: search, trait filters, a weekly feature and
/// the catalogue grid.
class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key, this.embedded = false});

  /// True when hosted inside the shell rather than pushed as its own route.
  final bool embedded;

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokedexStore _store = locator<PokedexStore>();
  late final TextEditingController _search =
      TextEditingController(text: _store.searchQuery);

  @override
  void initState() {
    super.initState();
    _store.loadPokedex();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ScreenBackground(
      glow: false,
      child: SafeArea(
        bottom: false,
        child: Observer(
          builder: (context) {
            if (_store.isLoading && _store.species.isEmpty) {
              return ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl,
                    AppSpacing.gutter, navClearance(context)),
                children: const [
                  Skeleton(width: 200, height: 42),
                  SizedBox(height: AppSpacing.xl),
                  Skeleton(height: 62, radius: AppRadius.pill),
                  SizedBox(height: AppSpacing.xl),
                  Skeleton(height: 44, radius: AppRadius.pill),
                  SizedBox(height: AppSpacing.xl),
                  Skeleton(height: 230, radius: AppRadius.card),
                ],
              );
            }

            final results = _store.filteredSpecies;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(AppSpacing.gutter,
                      widget.embedded ? AppSpacing.lg : AppSpacing.xxl,
                      AppSpacing.gutter, 0),
                  sliver: SliverList.list(
                    children: [
                      if (widget.embedded) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CircleIconButton(
                            icon: PgIcons.chevronLeft,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text('Pokedex', style: AppText.display40),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl, vertical: 12),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.pillR,
                              boxShadow: AppShadows.raised,
                            ),
                            child: Text(
                              '${_formatCount(_store.catalogueSize)} species',
                              style: AppText.heading17.copyWith(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Discover your next plant',
                          style: AppText.body15.copyWith(fontSize: 16)),
                      const SizedBox(height: AppSpacing.xl),
                      AppSearchField(
                        hint: 'Search plants',
                        controller: _search,
                        onChanged: _store.setSearchQuery,
                      ),
                    ],
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
                      itemCount: PokedexFilter.values.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final filter = PokedexFilter.values[index];
                        return FilterChipPill(
                          label: filter.label,
                          selected: _store.selectedFilters.contains(filter),
                          onTap: () => _store.toggleFilter(filter),
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter),
                  sliver: SliverToBoxAdapter(
                    child: _PlantOfTheWeek(store: _store),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                      AppSpacing.section, AppSpacing.gutter, AppSpacing.lg),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Explore plants',
                      trailing: _store.resultsLabel,
                    ),
                  ),
                ),
                if (results.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.xl, AppSpacing.gutter, 0),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        compact: true,
                        title: 'Nothing here yet',
                        body: 'No species match that search. Try a different '
                            'name or clear the filters.',
                        primaryLabel: 'Clear filters',
                        onPrimary: () {
                          _search.clear();
                          _store.clearFilters();
                        },
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gutter),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.lg,
                        crossAxisSpacing: AppSpacing.lg,
                        childAspectRatio: 0.555,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) => Entrance(
                        index: index % 6,
                        child: SpeciesCard(
                          species: results[index],
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.speciesDetail,
                            arguments: results[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: navClearance(context)),
                ),
              ],
            );
          },
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: widget.embedded
          ? Scaffold(backgroundColor: AppColors.ground, body: body)
          : body,
    );
  }

  static String _formatCount(int value) {
    final s = value.toString();
    if (s.length <= 3) return s;
    final head = s.substring(0, s.length - 3);
    return '$head,${s.substring(s.length - 3)}';
  }
}

class _PlantOfTheWeek extends StatelessWidget {
  const _PlantOfTheWeek({required this.store});

  final PokedexStore store;

  @override
  Widget build(BuildContext context) {
    final species = store.plantOfTheWeek;
    return Pressable(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRoutes.speciesDetail, arguments: species),
      child: Container(
        height: 244,
        decoration: const BoxDecoration(
          color: AppColors.ink,
          borderRadius: AppRadius.cardR,
          boxShadow: AppShadows.raised,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -50,
              width: 250,
              height: 260,
              child: PlantArtwork(
                glyph: species.glyph,
                showGround: false,
                tint: const Color(0xFF060A05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CaptionLabel('Plant of the week',
                      color: AppColors.leaf),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: 210,
                    child: Text(
                      species.latinName,
                      style: AppText.title28
                          .copyWith(fontSize: 26, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: 218,
                    child: Text(
                      species.tagline ?? species.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body15.copyWith(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _DarkChip(label: species.difficulty),
                      const SizedBox(width: AppSpacing.sm),
                      _DarkChip(label: species.light),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: AppRadius.pillR,
      ),
      child: Text(label,
          style: AppText.label13.copyWith(fontSize: 13, color: Colors.white)),
    );
  }
}
