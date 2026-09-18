import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../routes.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/empty_state.dart';
import '../../shared/components/metric_card.dart';
import '../../shared/components/plant_card.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../shared/widgets/skeleton.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';
import '../shell/app_shell.dart';

/// `My Plants` — the collection grid, with search and filter chips.
class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final PlantCollectionStore _store = locator<PlantCollectionStore>();
  late final TextEditingController _search =
      TextEditingController(text: _store.searchQuery);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBackground(
      glow: false,
      child: SafeArea(
        bottom: false,
        child: Observer(
          builder: (context) {
            if (_store.isLoading && _store.plants.isEmpty) {
              return ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl,
                    AppSpacing.gutter, navClearance(context)),
                children: [
                  const Text('My Plants', style: AppText.display40),
                  const SizedBox(height: AppSpacing.md),
                  const PlantsSkeleton(),
                ],
              );
            }

            if (_store.isEmpty) {
              return _EmptyCollection(
                onScan: () => Navigator.of(context).pushNamed(AppRoutes.scan),
                onBrowse: () =>
                    Navigator.of(context).pushNamed(AppRoutes.pokedex),
              );
            }

            final plants = _store.filteredPlants;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                      AppSpacing.xxl, AppSpacing.gutter, 0),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Plants', style: AppText.display40),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${_store.plants.length} plants · '
                                  '${_store.attentionCount} need attention',
                                  style: AppText.body15.copyWith(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          CircleIconButton(
                            icon: PgIcons.plus,
                            size: 56,
                            background: AppColors.ink,
                            foreground: AppColors.leaf,
                            onPressed: () =>
                                Navigator.of(context).pushNamed(AppRoutes.scan),
                            semanticLabel: 'Add a plant',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchField(
                              hint: 'Search your plants',
                              controller: _search,
                              onChanged: _store.setSearchQuery,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          CircleIconButton(
                            icon: PgIcons.sliders,
                            size: 62,
                            onPressed: () => _showFilters(context),
                            semanticLabel: 'Filters',
                          ),
                        ],
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
                      itemCount: PlantFilter.values.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final filter = PlantFilter.values[index];
                        return FilterChipPill(
                          label: filter.label,
                          selected: _store.selectedFilter == filter,
                          onTap: () => _store.setFilter(filter),
                        );
                      },
                    ),
                  ),
                ),
                if (plants.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                        AppSpacing.xxxl, AppSpacing.gutter, 0),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        compact: true,
                        title: 'Nothing here yet',
                        body: 'No plants match that search or filter.',
                        primaryLabel: 'Clear filters',
                        onPrimary: () {
                          _search.clear();
                          _store
                            ..setSearchQuery('')
                            ..setFilter(PlantFilter.all);
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
                        childAspectRatio: 0.66,
                      ),
                      itemCount: plants.length,
                      itemBuilder: (context, index) => Entrance(
                        index: index % 6,
                        child: PlantCard(
                          plant: plants[index],
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.plantDetail,
                            arguments: plants[index],
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
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C0B1A0F),
      builder: (context) => _FilterSheet(store: _store),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.store});

  final PlantCollectionStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('Filter your collection',
                  style: AppText.title28.copyWith(fontSize: 22.5)),
              const SizedBox(height: AppSpacing.xl),
              Observer(
                builder: (context) => Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final filter in PlantFilter.values)
                      FilterChipPill(
                        label: filter.label,
                        selected: store.selectedFilter == filter,
                        onTap: () {
                          store.setFilter(filter);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.onScan, required this.onBrowse});

  final VoidCallback onScan;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.xxl,
          AppSpacing.gutter, navClearance(context)),
      children: [
        const Text('My Plants', style: AppText.display40),
        const SizedBox(height: AppSpacing.sm),
        Text('No plants yet', style: AppText.body15.copyWith(fontSize: 16)),
        const SizedBox(height: AppSpacing.xxxl + AppSpacing.lg),
        EmptyState(
          title: 'Your collection is\nwaiting to grow.',
          body: 'Scan a plant nearby and it arrives with a profile, a care '
              'schedule and its own health record.',
          artwork: SizedBox(
            height: 230,
            child: Image.asset('assets/images/tree_pine.png',
                fit: BoxFit.contain),
          ),
          primaryLabel: 'Add your first plant',
          primaryIcon: PgIcons.scan,
          onPrimary: onScan,
          secondaryLabel: 'Browse the Pokedex',
          onSecondary: onBrowse,
        ),
      ],
    );
  }
}
