import 'package:flutter/material.dart';

import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'pressable.dart';

enum AppButtonStyle {
  /// Leaf-green fill, ink label — the primary action.
  primary,

  /// Ink fill, white label.
  dark,

  /// White fill with a hairline — secondary.
  outline,

  /// Soft green fill — a completed or passive action.
  soft,

  /// Coral fill — destructive.
  danger,

  /// No fill, ink label with a lime underline.
  link,
}

/// The pill button from the Components page. Touch targets never below 44.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.trailingIcon,
    this.height = 58,
    this.expand = true,
    this.loading = false,
    this.fontSize = 16,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.height = 58,
    this.expand = true,
    this.loading = false,
    this.fontSize = 16,
  }) : style = AppButtonStyle.primary;

  const AppButton.dark({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.height = 58,
    this.expand = true,
    this.loading = false,
    this.fontSize = 16,
  }) : style = AppButtonStyle.dark;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.height = 58,
    this.expand = true,
    this.loading = false,
    this.fontSize = 16,
  }) : style = AppButtonStyle.outline;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final PgIcons? icon;
  final PgIcons? trailingIcon;
  final double height;
  final bool expand;
  final bool loading;
  final double fontSize;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = _palette();
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: fontSize + 4,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  PgIcon(icon!, size: fontSize + 5, color: fg),
                  const SizedBox(width: AppSpacing.sm + 2),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppText.button.copyWith(color: fg, fontSize: fontSize),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  PgIcon(trailingIcon!, size: fontSize + 5, color: fg),
                ],
              ],
            ),
    );

    if (style == AppButtonStyle.link) {
      return Pressable(
        onTap: onPressed,
        semanticLabel: label,
        child: Container(
          height: AppSpacing.minTouchTarget,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.leaf, width: 2),
              ),
            ),
            child: Text(
              label,
              style: AppText.button.copyWith(fontSize: fontSize, color: fg),
            ),
          ),
        ),
      );
    }

    return Pressable(
      onTap: _enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: height,
        width: expand ? double.infinity : null,
        padding: expand
            ? null
            : const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillR,
          border: border,
          boxShadow:
              _enabled && style == AppButtonStyle.primary ? AppShadows.raised : null,
        ),
        child: content,
      ),
    );
  }

  (Color, Color, Border?) _palette() {
    if (!_enabled && !loading) {
      return (AppColors.neutralTint, AppColors.inkFaint, null);
    }
    return switch (style) {
      AppButtonStyle.primary => (AppColors.leaf, AppColors.ink, null),
      AppButtonStyle.dark => (AppColors.ink, Colors.white, null),
      AppButtonStyle.outline => (
          AppColors.surface,
          AppColors.ink,
          Border.all(color: AppColors.line, width: 1.2),
        ),
      AppButtonStyle.soft => (AppColors.softGreen, AppColors.healthyDeep, null),
      AppButtonStyle.danger => (AppColors.critical, AppColors.ink, null),
      AppButtonStyle.link => (Colors.transparent, AppColors.ink, null),
    };
  }
}

/// A circular icon button — back chevrons, overflow menus, the onboarding
/// forward arrow.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 52,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.iconSize,
    this.elevated = true,
    this.semanticLabel,
  });

  final PgIcons icon;
  final VoidCallback? onPressed;
  final double size;
  final Color background;
  final Color foreground;
  final double? iconSize;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: elevated ? AppShadows.raised : null,
        ),
        child: PgIcon(icon, size: iconSize ?? size * 0.44, color: foreground),
      ),
    );
  }
}
