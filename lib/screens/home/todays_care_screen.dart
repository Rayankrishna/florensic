import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../enum.dart';
import '../../locator.dart';
import '../../shared/components/app_chip.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/metric_card.dart';
import '../../stores/plant_collection_store.dart';
import '../../theme.dart';
import 'home_care_card.dart';
import 'home_care_rows.dart';

/// `Today's care` in full. Home shows the day folded by kind and sends the
/// keeper here — straight to one kind when they tapped its row — where
/// every task and folded treatment plan is listed and ticked off.
class TodaysCareScreen extends StatefulWidget {
  const TodaysCareScreen({super.key, this.initialKind});

  /// The kind to start filtered on; null shows everything.
  final CareTaskKind? initialKind;

  @override
  State<TodaysCareScreen> createState() => _TodaysCareScreenState();
}

class _TodaysCareScreenState extends State<TodaysCareScreen> {
  late CareTaskKind? _kind = widget.initialKind;

  @override
  Widget build(BuildContext context) {
    final collection = locator<PlantCollectionStore>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: SafeArea(
          child: Observer(
            builder: (context) {
              final tasks = collection.tasks;
              final kinds = summariseToday(
                tasks,
                (id) => collection.plantById(id)?.nickname,
              );
              // A kind that has left the list (refreshed away) falls back
              // to everything rather than an empty page.
              final kind = kinds.any((k) => k.kind == _kind) ? _kind : null;
              final items = todayItems(
                kind == null
                    ? tasks
                    : tasks.where((t) => t.kind == kind).toList(),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      0,
                    ),
                    child: NavHeader(
                      title: "Today's care",
                      subtitle:
                          '${collection.doneTaskCount} of ${tasks.length} done',
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  if (kinds.length > 1)
                    SizedBox(
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.lg,
                          AppSpacing.gutter,
                          0,
                        ),
                        children: [
                          FilterChipPill(
                            label: 'All',
                            selected: kind == null,
                            onTap: () => setState(() => _kind = null),
                          ),
                          for (final k in kinds) ...[
                            const SizedBox(width: AppSpacing.sm),
                            FilterChipPill(
                              label: '${careKindLabel(k.kind)} · ${k.left}',
                              selected: kind == k.kind,
                              onTap: () => setState(() => _kind = k.kind),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.ink,
                      backgroundColor: AppColors.surface,
                      onRefresh: collection.refreshTodaysCare,
                      child: items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xxxl,
                                AppSpacing.xxxl,
                                AppSpacing.xxxl,
                                0,
                              ),
                              children: [
                                Text(
                                  'Nothing due today.',
                                  textAlign: TextAlign.center,
                                  style: AppText.body15.copyWith(fontSize: 15),
                                ),
                              ],
                            )
                          : ListView.separated(
                              key: ValueKey(kind),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.gutter,
                                AppSpacing.lg,
                                AppSpacing.gutter,
                                AppSpacing.xxxl,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, index) => Entrance(
                                index: index,
                                child: TodayCareRow(item: items[index]),
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
    );
  }
}
