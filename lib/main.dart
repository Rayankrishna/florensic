import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'locator.dart';
import 'routes.dart';
import 'shared/components/app_toast.dart';
import 'stores/auth_store.dart';
import 'theme.dart';
import 'utils/ui_scale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightOverlay);
  await setupLocator();
  // A refresh token that has expired or been revoked ends the session from
  // inside a call: clear every screen, land on sign-in, and say why.
  locator<AuthStore>().onSignedOut = (message) {
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.authLanding, (_) => false);
    final overlay = navigator.overlay;
    if (overlay != null) AppToast.showIn(overlay, message: message);
  };
  runApp(const PlantGramApp());
}

class PlantGramApp extends StatelessWidget {
  const PlantGramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Florensic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      navigatorKey: AppRoutes.navigatorKey,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        // Cap text scaling so cards keep their designed proportions while
        // still honouring the reader's preference.
        final scaler = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
        return UiScale(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: SafeArea(
              top: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
