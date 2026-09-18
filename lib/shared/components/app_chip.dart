import 'package:flutter/material.dart';

import '../../enum.dart';
import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'pressable.dart';

/// A selectable filter chip. Leaf green when selected, white when not.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.selectedColor = AppColors.leaf,
    this.unselectedColor = AppColors.surface,
    this.selectedLabelColor = AppColors.ink,
    this.unselectedLabelColor = AppColors.ink,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedLabelColor;
  final Color unselectedLabelColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: AppSpacing.minTouchTarget,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedColor : unselectedColor,
          borderRadius: AppRadius.pillR,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: AppText.body15Ink.copyWith(
            fontFamily: AppText.display,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? selectedLabelColor : unselectedLabelColor,
            fontSize: 14,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// A static descriptive tag — `Easy care`, `Tropical`, `Toxic to pets`.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.label,
    this.tone = MetricStatus.neutral,
    this.dense = false,
  });

  final String label;
  final MetricStatus tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      MetricStatus.good => (AppColors.softGreen, AppColors.healthyDeep),
      MetricStatus.watch => (AppColors.cautionTint, AppColors.cautionDeep),
      MetricStatus.bad => (AppColors.criticalTint, AppColors.criticalDeep),
      MetricStatus.neutral => (AppColors.surface, AppColors.ink),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm + 2 : AppSpacing.lg,
        vertical: dense ? 5 : 10,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillR),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (dense ? AppText.label13 : AppText.body15Ink).copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 12.5 : 15,
        ),
      ),
    );
  }
}

/// The dot-plus-label status line under a plant's name.
class StatusLine extends StatelessWidget {
  const StatusLine({
    super.key,
    required this.label,
    required this.tone,
    this.isWater = false,
    this.fontSize = 14,
  });

  final String label;
  final MetricStatus tone;
  final bool isWater;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = isWater
        ? AppColors.waterDeep
        : switch (tone) {
            MetricStatus.good => AppColors.healthyDeep,
            MetricStatus.watch => AppColors.cautionDeep,
            MetricStatus.bad => AppColors.criticalDeep,
            MetricStatus.neutral => AppColors.inkMuted,
          };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isWater)
          PgIcon(PgIcons.droplet, size: fontSize + 2, color: color)
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: switch (tone) {
                MetricStatus.good => const Color(0xFF3E9B49),
                MetricStatus.watch => AppColors.caution,
                MetricStatus.bad => AppColors.critical,
                MetricStatus.neutral => AppColors.inkFaint,
              },
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.label13.copyWith(color: color, fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

/// A rounded square tinted tile carrying an icon — used in every list row.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 52,
    this.radius = AppRadius.tile,
    this.background,
    this.foreground,
  });

  final PgIcons icon;
  final MetricStatus tone;
  final double size;
  final double radius;
  final Color? background;
  final Color? foreground;

  /// Water-blue tile, which the signal enum has no slot for.
  const IconTile.water({
    super.key,
    required this.icon,
    this.size = 52,
    this.radius = AppRadius.tile,
  })  : tone = MetricStatus.neutral,
        background = AppColors.waterTint,
        foreground = AppColors.waterDeep;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      MetricStatus.good => (AppColors.softGreen, AppColors.healthyDeep),
      MetricStatus.watch => (AppColors.cautionTint, AppColors.cautionDeep),
      MetricStatus.bad => (AppColors.criticalTint, AppColors.criticalDeep),
      MetricStatus.neutral => (AppColors.neutralTint, AppColors.inkMuted),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: PgIcon(icon, size: size * 0.46, color: foreground ?? fg),
    );
  }
}
