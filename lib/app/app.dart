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

  static const _seedColor = Color(0xFF00674C);

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: _seedColor,
    onPrimary: Colors.white,
    secondary: const Color(0xFF6EC72D),
    onSecondary: const Color(0xFF242724),
  );

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF6EC72D),
    onPrimary: const Color(0xFF0B2A1F),
    secondary: const Color(0xFF4FB38F),
    onSecondary: const Color(0xFF0B2A1F),
  );

  @override
  Widget build(BuildContext context) {
    final dependencies = shopwatchDependencies ?? ShopwatchDependencies(timeSource: timeSource);
    return MaterialApp(
      title: 'Swatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: _lightScheme, useMaterial3: true),
      darkTheme: ThemeData(colorScheme: _darkScheme, useMaterial3: true),
      initialRoute: AppRoutes.shopwatch,
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, timeSource: timeSource, dependencies: dependencies),
    );
  }
}
