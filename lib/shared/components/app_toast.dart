import 'package:flutter/material.dart';

import '../../theme.dart';
import '../widgets/pg_icon.dart';

/// The ink feedback toast: a lime check, a message, and an optional action.
///
/// It enters from the top, holds, then leaves — the design uses it for
/// `Condition updated` and `Peace Lily added to your collection`.
class AppToast {
  const AppToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    String? detail,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    dismiss();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastHost(
        message: message,
        detail: detail,
        actionLabel: actionLabel,
        onAction: () {
          dismiss();
          onAction?.call();
        },
        duration: duration,
        onFinished: () {
          if (_current == entry) dismiss();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _current?.remove();
    _current = null;
  }
}

class _ToastHost extends StatefulWidget {
  const _ToastHost({
    required this.message,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onFinished,
  });

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback onAction;
  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future<void>.delayed(widget.duration, () async {
      if (!mounted) return;
      await _c.reverse();
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Positioned(
      top: MediaQuery.viewPaddingOf(context).top + AppSpacing.sm,
      left: AppSpacing.gutter,
      right: AppSpacing.gutter,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
            .animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.ink,
                borderRadius: AppRadius.cardR,
                boxShadow: AppShadows.floating,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.leaf,
                      shape: BoxShape.circle,
                    ),
                    child: const PgIcon(PgIcons.check,
                        size: 22, color: AppColors.ink),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message,
                          style: AppText.heading17
                              .copyWith(fontSize: 16, color: Colors.white),
                        ),
                        if (widget.detail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.detail!,
                            style: AppText.body13.copyWith(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.actionLabel != null)
                    GestureDetector(
                      onTap: widget.onAction,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                        child: Text(
                          widget.actionLabel!,
                          style: AppText.button
                              .copyWith(fontSize: 15, color: AppColors.leaf),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
