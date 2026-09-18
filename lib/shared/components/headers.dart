import 'package:flutter/material.dart';

import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'app_button.dart';

/// `Needs attention` … `See all` — a section title with an optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: AppText.title28.copyWith(fontSize: 22.5))),
          if (trailing != null)
            onTrailingTap == null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(trailing!,
                        style: AppText.body15.copyWith(fontSize: 13)),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTrailingTap,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3, left: 8),
                      child: Text(
                        trailing!,
                        style: AppText.body15.copyWith(fontSize: 14),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}

/// A caption above a section — `ENVIRONMENTAL INSIGHT`, `TODAY`.
class CaptionLabel extends StatelessWidget {
  const CaptionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppText.caption12.copyWith(color: color ?? AppColors.inkMuted),
      );
}

/// The large display title at the top of a root screen.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.fontSize = 40,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppText.display40.copyWith(fontSize: fontSize)),
              if (subtitleWidget != null) ...[
                const SizedBox(height: AppSpacing.sm),
                subtitleWidget!,
              ] else if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle!, style: AppText.body15.copyWith(fontSize: 15)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.lg),
          trailing!,
        ],
      ],
    );
  }
}

/// A modal / detail header: a circular back button, a centred title and an
/// optional trailing action.
class NavHeader extends StatelessWidget {
  const NavHeader({
    super.key,
    this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.leadingIcon = PgIcons.chevronLeft,
    this.foreground = AppColors.ink,
    this.background = AppColors.surface,
    this.titleColor,
    this.progress,
  });

  final String? title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final PgIcons leadingIcon;
  final Color foreground;
  final Color background;
  final Color? titleColor;

  /// A three-segment step indicator under the title, for the update flow.
  final ({int step, int total})? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (title != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.heading17.copyWith(
                    fontSize: 16.5,
                    color: titleColor ?? foreground,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body13.copyWith(
                      fontStyle: FontStyle.italic,
                      color: (titleColor ?? foreground).withValues(alpha: 0.65),
                    ),
                  ),
                if (progress != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _StepBars(step: progress!.step, total: progress!.total),
                ],
              ],
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: onBack == null
                ? const SizedBox.shrink()
                : CircleIconButton(
                    icon: leadingIcon,
                    onPressed: onBack,
                    background: background,
                    foreground: foreground,
                    elevated: background != Colors.transparent &&
                        background.a > 0.9 &&
                        background == AppColors.surface,
                    semanticLabel: 'Back',
                  ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    );
  }
}

class _StepBars extends StatelessWidget {
  const _StepBars({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            width: 28,
            height: 4,
            decoration: BoxDecoration(
              color: i < step
                  ? AppColors.ink
                  : i == step
                      ? AppColors.leaf
                      : AppColors.track,
              borderRadius: AppRadius.pillR,
            ),
          ),
        ],
      ],
    );
  }
}
