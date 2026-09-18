import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../domain/models/plant.dart';
import '../../locator.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_surfaces.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/app_toast.dart';
import '../../shared/components/headers.dart';
import '../../shared/components/list_rows.dart';
import '../../shared/widgets/pg_icon.dart';
import '../../stores/plant_detail_store.dart';
import '../../theme.dart';
import '../../utils/date_format.dart';
import '../../utils/app_clock.dart';

/// `Care schedule` — when the next watering lands, why, and what the keeper
/// has asked to be reminded about.
class CareScheduleScreen extends StatefulWidget {
  const CareScheduleScreen({super.key, required this.plant});

  final Plant plant;

  @override
  State<CareScheduleScreen> createState() => _CareScheduleScreenState();
}

class _CareScheduleScreenState extends State<CareScheduleScreen> {
  late final PlantDetailStore _store = locator<PlantDetailStore>()
    ..attach(widget.plant);

  Future<void> _water() async {
    await _store.markAsWatered();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    AppToast.show(context, message: 'Watering logged');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        body: Observer(
          builder: (context) {
            final plant = _store.plant!;
            final schedule = plant.schedule;
            final due = plant.daysUntilWatering;
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      AppSpacing.lg,
                      AppSpacing.gutter,
                      110 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    children: [
                      NavHeader(
                        title: 'Care schedule',
                        onBack: () => Navigator.of(context).maybePop(),
                        trailing: CircleIconButton(
                          icon: PgIcons.pencil,
                          onPressed: () => AppToast.show(context,
                              message: 'Editing the schedule',
                              detail: 'Not available in this build'),
                          semanticLabel: 'Edit schedule',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      DarkCard(
                        glow: const Color(0xFF7FB7E8),
                        glowAlignment: const Alignment(0.75, -0.55),
                        glowOpacity: 0.26,
                        padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CaptionLabel('Next watering',
                                color: Color(0xFF9AA69C)),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              AppDate.relativeDue(due),
                              style: AppText.display40
                                  .copyWith(fontSize: 41, color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              "Based on your plant's care schedule and current "
                              'conditions.',
                              style: AppText.body15.copyWith(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              children: [
                                _DarkPill(
                                    label: AppDate.weekdayDayMonth(
                                        schedule.nextWatering)),
                                const SizedBox(width: AppSpacing.md),
                                _DarkPill(
                                    label:
                                        '~${schedule.nextWaterAmountMl} ml'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _CalendarCard(plant: plant),
                      const SizedBox(height: AppSpacing.lg),
                      EqualHeightRow(
                        children: [
                          _FactCard(
                            label: 'Last watered',
                            value: AppDate.relativeDays(plant.daysSinceWatered)
                                .replaceFirst('t', 'T'),
                            detail:
                                '${AppDate.weekdayDayMonth(schedule.lastWatered)}'
                                ' · ${schedule.lastAmountMl} ml',
                          ),
                          _FactCard(
                            label: 'Frequency',
                            value: 'Every ${schedule.frequencyDays} days',
                            detail: 'Adjusts with weather',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        padding:
                            const EdgeInsets.all(AppSpacing.cardPaddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reminders',
                                style:
                                    AppText.heading20.copyWith(fontSize: 20.5)),
                            const SizedBox(height: AppSpacing.xl),
                            _ReminderRow(
                              title: 'Watering reminder',
                              detail: 'Morning of, at ${schedule.reminderTime}',
                              value: schedule.wateringReminder,
                              onChanged: (v) => _store.setReminder(watering: v),
                            ),
                            const Divider(
                                height: AppSpacing.xxxl, color: AppColors.line),
                            _ReminderRow(
                              title: 'Condition check-in',
                              detail:
                                  'Every ${schedule.checkInIntervalDays} days · '
                                  '${schedule.checkInWindowDays}-day window',
                              value: schedule.checkInReminder,
                              onChanged: (v) => _store.setReminder(checkIn: v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SoftCard(
                        color: AppColors.cautionTint,
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6DFB6),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.tile),
                              ),
                              child: const PgIcon(PgIcons.clock,
                                  size: 24, color: AppColors.cautionDeep),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in window opens '
                                    '${AppDate.weekdayShort(schedule.checkInWindowOpens)}',
                                    style: AppText.heading17
                                        .copyWith(fontSize: 16.5),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Add a photo between '
                                    '${AppDate.dayMonth(schedule.checkInWindowOpens)}–'
                                    '${AppDate.dayMonth(schedule.checkInWindowOpens.add(Duration(days: schedule.checkInWindowDays)))}'
                                    ' to keep care status active. Miss it and '
                                    'the status simply pauses — nothing is lost.',
                                    style: AppText.body13.copyWith(
                                        fontSize: 14,
                                        color: AppColors.cautionDeep),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const SectionHeader(title: 'Care history'),
                      const SizedBox(height: AppSpacing.xl),
                      for (var i = 0; i < plant.careHistory.length; i++)
                        TimelineRow(
                          title: plant.careHistory[i].title,
                          detail: '${AppDate.eventStamp(plant.careHistory[i].at)}'
                              '${plant.careHistory[i].detail.isEmpty ? '' : ' · ${plant.careHistory[i].detail}'}',
                          type: plant.careHistory[i].type,
                          isLast: i == plant.careHistory.length - 1,
                        ),
                    ],
                  ),
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
                            label: _store.justWatered
                                ? 'Watered'
                                : 'Mark as watered',
                            loading: _store.isBusy,
                            onPressed: _water,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        CircleIconButton(
                          icon: PgIcons.pencil,
                          size: 58,
                          elevated: false,
                          background: AppColors.ground,
                          onPressed: () => AppToast.show(context,
                              message: 'Editing the schedule',
                              detail: 'Not available in this build'),
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

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillR,
      ),
      child: Text(label,
          style: AppText.heading17.copyWith(fontSize: 15, color: Colors.white)),
    );
  }
}

/// A week strip with the states the legend names.
class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.plant});

  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final today = AppClock.now();
    final week = AppDate.weekOf(today);
    final schedule = plant.schedule;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppDate.monthFull(today),
                    style: AppText.heading20.copyWith(fontSize: 20.5)),
              ),
              Text('Watering · Check-in',
                  style: AppText.body15.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: Text(
                    AppDate.weekdayInitial(day),
                    textAlign: TextAlign.center,
                    style: AppText.label13.copyWith(
                      fontSize: 13,
                      color: AppDate.sameDay(day, today)
                          ? AppColors.ink
                          : AppColors.inkMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DayTile(
                      day: day,
                      isToday: AppDate.sameDay(day, today),
                      isWatering: AppDate.sameDay(day, schedule.nextWatering),
                      isWatered: AppDate.sameDay(day, schedule.lastWatered),
                      isCheckIn: !day.isBefore(_strip(schedule.checkInWindowOpens)) &&
                          !day.isAfter(_strip(schedule.checkInWindowOpens)
                              .add(Duration(days: schedule.checkInWindowDays))),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _Legend(color: AppColors.leaf, label: 'Watering'),
              _Legend(color: AppColors.caution, label: 'Check-in window'),
              _Legend(color: AppColors.water, label: 'Watered'),
            ],
          ),
        ],
      ),
    );
  }

  static DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.isToday,
    required this.isWatering,
    required this.isWatered,
    required this.isCheckIn,
  });

  final DateTime day;
  final bool isToday;
  final bool isWatering;
  final bool isWatered;
  final bool isCheckIn;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (isToday) {
      background = AppColors.ink;
      foreground = Colors.white;
    } else if (isWatering) {
      background = AppColors.leaf;
      foreground = AppColors.ink;
    } else if (isWatered) {
      background = AppColors.waterTint;
      foreground = AppColors.waterDeep;
    } else if (isCheckIn) {
      background = AppColors.cautionTint;
      foreground = AppColors.cautionDeep;
    } else {
      background = const Color(0xFFEFF4F2);
      foreground = AppColors.ink;
    }
    return AspectRatio(
      aspectRatio: 0.82,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.chip + 4),
        ),
        child: Text(
          '${day.day}',
          style: AppText.heading17.copyWith(fontSize: 16, color: foreground),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.body13.copyWith(fontSize: 11.5)),
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.body15.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppText.heading20.copyWith(fontSize: 19.5)),
          const SizedBox(height: AppSpacing.sm),
          Text(detail, style: AppText.body13.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.heading17.copyWith(fontSize: 16.5)),
              const SizedBox(height: 3),
              Text(detail, style: AppText.body13.copyWith(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
