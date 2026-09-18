import 'package:flutter/material.dart';

import '../../enum.dart';
import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'app_chip.dart';
import 'pressable.dart';

/// A white row with a tinted icon tile, a title, a detail line and an
/// optional trailing widget. Used across care lists, next actions, insights
/// and notifications.
class TileRow extends StatelessWidget {
  const TileRow({
    super.key,
    required this.icon,
    required this.title,
    this.detail,
    this.tone = MetricStatus.neutral,
    this.iconBackground,
    this.iconForeground,
    this.trailing,
    this.onTap,
    this.background = AppColors.surface,
    this.detailColor,
    this.strikeThrough = false,
    this.titleMaxLines = 3,
    this.elevated = true,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.leading,
  });

  final PgIcons icon;
  final String title;
  final String? detail;
  final MetricStatus tone;
  final Color? iconBackground;
  final Color? iconForeground;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color background;
  final Color? detailColor;
  final bool strikeThrough;
  final int titleMaxLines;
  final bool elevated;
  final EdgeInsetsGeometry padding;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.cardR,
          boxShadow: elevated && background == AppColors.surface
              ? AppShadows.raised
              : null,
        ),
        child: Row(
          children: [
            leading ??
                IconTile(
                  icon: icon,
                  tone: tone,
                  background: iconBackground,
                  foreground: iconForeground,
                ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading17.copyWith(
                      fontSize: 16,
                      color: strikeThrough ? AppColors.inkMuted : AppColors.ink,
                      decoration:
                          strikeThrough ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.inkMuted,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      detail!,
                      style: AppText.body13.copyWith(
                        fontSize: 14,
                        color: detailColor ?? AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A settings row: an outline icon, a label, an optional value and a chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.showChevron = true,
  });

  final PgIcons icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 68,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            PgIcon(icon, size: 23, color: AppColors.ink),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(label,
                  style: AppText.heading17.copyWith(fontSize: 16.5)),
            ),
            if (value != null)
              Text(value!, style: AppText.body15.copyWith(fontSize: 14)),
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.md),
              const PgIcon(PgIcons.chevronRight,
                  size: 20, color: AppColors.inkMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// A group of [SettingsRow]s under a caption, hairline-separated.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.cardR,
        boxShadow: AppShadows.raised,
      ),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: AppColors.surface,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.line,
                  indent: AppSpacing.xl,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A timeline entry in `Care history` — a coloured node on a vertical rail.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.title,
    required this.detail,
    required this.type,
    this.isLast = false,
  });

  final String title;
  final String detail;
  final CareEventType type;
  final bool isLast;

  Color get _nodeColor => switch (type) {
        CareEventType.watered => AppColors.water,
        CareEventType.conditionUpdate => AppColors.leaf,
        CareEventType.repotted => AppColors.caution,
        CareEventType.moved => AppColors.inkFaint,
      };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration:
                      BoxDecoration(color: _nodeColor, shape: BoxShape.circle),
                ),
                if (!isLast)
                  const Expanded(
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1.4,
                      color: AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.heading17.copyWith(fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(detail, style: AppText.body13.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of small statistics separated by generous space — `7-day change`,
/// `Streak`, `Updates`.
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.stats});

  final List<({String label, String value, Color? valueColor})> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++)
          Expanded(
            child: Column(
              crossAxisAlignment: i == stats.length - 1
                  ? CrossAxisAlignment.end
                  : i == 0
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
              children: [
                Text(stats[i].label,
                    style: AppText.body13.copyWith(fontSize: 13)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  stats[i].value,
                  style: AppText.heading20.copyWith(
                    fontSize: 18.5,
                    color: stats[i].valueColor ?? AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
