import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'locator.dart';
import 'routes.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.lightOverlay);
  await setupLocator();
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
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        // Cap text scaling so cards keep their designed proportions while
        // still honouring the reader's preference.
        final scaler = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );
        return SafeArea(
          bottom: true,
          top: false,
          
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
