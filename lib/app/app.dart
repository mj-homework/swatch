import 'package:flutter/material.dart';

import '../core/stopwatch/time_source.dart';
import 'router.dart';
import '../features/shopwatch/shopwatch_dependencies.dart';

/// Root widget of the application.
///
/// [timeSource] can be injected so the whole app can be driven by a fake
/// clock in widget tests.
class SwatchApp extends StatelessWidget {
  const SwatchApp({super.key, this.timeSource, this.shopwatchDependencies});

  final TimeSource? timeSource;
  final ShopwatchDependencies? shopwatchDependencies;

  static const _seedColor = Color(0xFF52AE30);

  @override
  Widget build(BuildContext context) {
    final dependencies = shopwatchDependencies ?? ShopwatchDependencies(timeSource: timeSource);
    return MaterialApp(
      title: 'Swatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.shopwatch,
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, timeSource: timeSource, dependencies: dependencies),
    );
  }
}
