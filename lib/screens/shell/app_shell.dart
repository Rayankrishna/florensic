import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../locator.dart';
import '../../routes.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../stores/app_shell_store.dart';
import '../../stores/insights_store.dart';
import '../../stores/notifications_store.dart';
import '../../stores/plant_collection_store.dart';
import '../../stores/plantdex_store.dart';
import '../../theme.dart';
import '../home/home_screen.dart';
import '../insights/insights_screen.dart';
import '../plants/plants_screen.dart';
import '../profile/profile_screen.dart';

/// Hosts the four tabbed destinations under the floating navigation pill.
///
/// The pages are kept alive in an [IndexedStack] so scroll position and any
/// in-flight animation survive a tab switch.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppShellStore _shell = locator<AppShellStore>();

  /// The tab on screen, and which way the last switch went: +1 when the new
  /// tab sits to the right of the old one, -1 to the left. The incoming page
  /// slides in from that side and the outgoing one leaves the other way, so
  /// the motion matches the order of the pills in the nav bar.
  int _shownIndex = 0;
  int _direction = 1;

  /// How far a page travels, as a fraction of the width — enough to read as
  /// a direction, short enough to stay quick under the fade.
  static const double _travel = 0.3;

  @override
  void initState() {
    super.initState();
    _shell.restore();
    // Warm the stores the shell's tabs read from.
    locator<PlantCollectionStore>().loadPlants();
    locator<InsightsStore>().loadInsights();
    locator<NotificationsStore>().loadNotifications();
    locator<PlantdexStore>().loadPlantdex();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        extendBody: true,
        body: Observer(
          builder: (context) {
            final index = _shell.bodyIndex;
            if (index != _shownIndex) {
              _direction = index > _shownIndex ? 1 : -1;
              _shownIndex = index;
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                // One builder serves both pages: the one keyed to the
                // current tab is arriving, anything else is leaving. The
                // leaving page's animation runs backwards, so the same
                // tween carries it off the opposite side.
                final arriving = child.key == ValueKey<int>(index);
                final side = arriving ? _direction : -_direction;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_travel * side, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: KeyedSubtree(
                key: ValueKey<int>(index),
                child: _pageFor(index),
              ),
            );
          },
        ),
        bottomNavigationBar: Observer(
          builder: (context) => AppBottomNav(
            currentIndex: _shell.currentIndex,
            onSelect: _shell.select,
            onScan: () => Navigator.of(context).pushNamed(AppRoutes.scan),
          ),
        ),
      ),
    );
  }

  Widget _pageFor(int index) => switch (index) {
        0 => const HomeScreen(),
        1 => const PlantsScreen(),
        2 => const InsightsScreen(),
        _ => const ProfileScreen(),
      };
}

/// Space reserved at the foot of a scroll view so content clears the
/// floating navigation pill.
double navClearance(BuildContext context) =>
    AppBottomNav.height + AppBottomNav.bottomMargin(context) + AppSpacing.lg;
