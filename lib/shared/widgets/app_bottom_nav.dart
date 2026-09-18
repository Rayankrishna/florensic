import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import 'pg_icon.dart';

/// The floating navigation pill, rendered as liquid glass: the page scrolls
/// underneath and shows through a heavy blur, with a hairline highlight
/// giving the surface its edge.
///
/// Five destinations; the third is the scan action and opens a full-screen
/// route rather than a tab, so it is drawn as a filled ink disc.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onScan,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  static const int scanIndex = 2;
  static const double height = 66;

  /// Clear space between the pill and the bottom edge of the screen.
  static double bottomMargin(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    return inset > 0 ? inset + AppSpacing.sm + 2 : AppSpacing.xl;
  }

  static const List<PgIcons> _icons = [
    PgIcons.home,
    PgIcons.grid,
    PgIcons.scan,
    PgIcons.chart,
    PgIcons.person,
  ];

  static const List<String> _labels = [
    'Home',
    'My Plants',
    'Identify a plant',
    'Insights',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        bottomMargin(context),
      ),
      child: DecoratedBox(
        // Glass carries both a hairline and a soft shadow — the one deliberate
        // exception to the "border or shadow, never both" rule, since the
        // shadow is what separates the translucent surface from the page.
        decoration: const BoxDecoration(
          borderRadius: AppRadius.pillR,
          boxShadow: AppShadows.navBar,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillR,
          // A wider blur with less tint: the page reads clearly through the
          // surface, and the refraction alone gives it its edge.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: AppRadius.pillR,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.34),
                    Colors.white.withValues(alpha: 0.14),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.42),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _icons.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _icons[i],
                        label: _labels[i],
                        selected: i == currentIndex,
                        isScan: i == scanIndex,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (i == scanIndex) {
                            onScan();
                          } else {
                            onSelect(i);
                          }
                        },
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isScan,
    required this.onTap,
  });

  final PgIcons icon;
  final String label;
  final bool selected;
  final bool isScan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double diameter = isScan ? 58 : 46;
    final Color background = isScan
        ? AppColors.ink
        : (selected ? AppColors.leaf : Colors.transparent);
    final Color foreground = isScan
        ? Colors.white
        : (selected ? AppColors.ink : AppColors.inkMuted);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: AppBottomNav.height,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.04 : 1,
                  child: PgIcon(
                    icon,
                    size: isScan ? 26 : 24,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
