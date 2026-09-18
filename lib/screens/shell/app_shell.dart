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
import '../../stores/pokedex_store.dart';
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

  @override
  void initState() {
    super.initState();
    _shell.restore();
    // Warm the stores the shell's tabs read from.
    locator<PlantCollectionStore>().loadPlants();
    locator<InsightsStore>().loadInsights();
    locator<NotificationsStore>().loadNotifications();
    locator<PokedexStore>().loadPokedex();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightOverlay,
      child: Scaffold(
        backgroundColor: AppColors.ground,
        extendBody: true,
        body: Observer(
          builder: (context) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_shell.bodyIndex),
              child: _pageFor(_shell.bodyIndex),
            ),
          ),
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
