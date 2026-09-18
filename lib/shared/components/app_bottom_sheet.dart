import 'package:flutter/material.dart';

import '../../theme.dart';

/// 28px top radius, 20px padding, grab handle, one primary action pinned to
/// the base.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(
        AppSpacing.gutter, AppSpacing.lg, AppSpacing.gutter, AppSpacing.gutter),
    this.background = AppColors.ground,
  });

  final Widget child;
  final Widget? actions;
  final EdgeInsetsGeometry padding;
  final Color background;

  /// Presents [builder] with the app's sheet chrome and motion.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C0B1A0F),
      transitionAnimationController: null,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Flexible(child: SingleChildScrollView(child: child)),
              if (actions != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
