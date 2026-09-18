import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import '../widgets/pg_icon.dart';
import 'pressable.dart';

/// A labelled input. Focus draws an ink hairline, as the specification shows.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.errorText,
    this.autofocus = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final int? maxLines;
  final int? minLines;
  final String? errorText;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocus);
  bool _focused = false;

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!,
              style: AppText.label13.copyWith(fontSize: 13, height: 1.2)),
          const SizedBox(height: AppSpacing.sm + 2),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: widget.maxLines != null && widget.maxLines! > 1 ? 16 : 0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
                widget.maxLines != null && widget.maxLines! > 1 ? 24 : 40),
            border: Border.all(
              color: hasError
                  ? AppColors.critical
                  : _focused
                      ? AppColors.ink
                      : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  obscuringCharacter: '●',
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  minLines: widget.minLines,
                  cursorWidth: 1.6,
                  cursorRadius: const Radius.circular(2),
                  style: AppText.body15Ink.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: AppText.body15.copyWith(
                      fontSize: 15,
                      color: AppColors.inkFaint,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: widget.maxLines != null && widget.maxLines! > 1
                          ? 0
                          : 20,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.sm, left: AppSpacing.xs),
                  child: Text(
                    widget.errorText!,
                    style: AppText.body13
                        .copyWith(color: AppColors.criticalDeep),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The rounded search field used on My Plants, the Pokedex and elsewhere.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.focusNode,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillR,
      ),
      child: Row(
        children: [
          const PgIcon(PgIcons.search, size: 22, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorWidth: 1.6,
              style: AppText.body15Ink.copyWith(fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    AppText.body15.copyWith(fontSize: 15, color: AppColors.inkMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single six-digit verification code box.
class CodeField extends StatelessWidget {
  const CodeField({
    super.key,
    required this.value,
    required this.focused,
    this.onTap,
  });

  final String value;
  final bool focused;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 66,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: focused ? AppColors.ink : Colors.transparent,
            width: 1.8,
          ),
        ),
        child: value.isEmpty
            ? (focused ? const _Caret() : const SizedBox.shrink())
            : Text(value, style: AppText.title28.copyWith(fontSize: 24)),
      ),
    );
  }
}

class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c.drive(Tween<double>(begin: 1, end: 0.1)),
      child: Container(width: 2, height: 30, color: AppColors.ink),
    );
  }
}

/// A checkbox drawn to the specification: a square with an ink border.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 26,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      scale: 0.9,
      child: SizedBox.square(
        dimension: AppSpacing.minTouchTarget,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: value ? AppColors.leaf : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value ? AppColors.leaf : AppColors.inkMuted,
                width: 1.6,
              ),
            ),
            child: value
                ? const PgIcon(PgIcons.check, size: 18, color: AppColors.ink)
                : null,
          ),
        ),
      ),
    );
  }
}

/// The lime/ink toggle from the permissions and reminders screens.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged!(!value);
            },
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 58,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.leaf : AppColors.track,
          borderRadius: AppRadius.pillR,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value ? AppColors.ink : AppColors.surface,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
