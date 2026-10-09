import 'package:flutter/material.dart';

import '../core/stopwatch/time_source.dart';
import 'router.dart';

/// Root widget of the application.
///
/// [timeSource] can be injected so the whole app can be driven by a fake
/// clock in widget tests.
class ShopwatchApp extends StatelessWidget {
  const ShopwatchApp({super.key, this.timeSource});

  final TimeSource? timeSource;

  static const _seedColor = Color(0xFF52AE30);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopwatch',
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
      initialRoute: AppRoutes.landing,
      onGenerateRoute: (settings) =>
          AppRouter.onGenerateRoute(settings, timeSource: timeSource),
    );
  }
}
