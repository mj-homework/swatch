import 'package:flutter/material.dart';

import '../core/stopwatch/time_source.dart';
import '../features/stopwatch/presentation/classic_stopwatch_page.dart';
import '../features/landing/landing_page.dart';
import '../features/shopwatch/presentation/shopwatch_page.dart';

abstract final class AppRoutes {
  static const landing = '/';
  static const classicStopwatch = '/classic-stopwatch';
  static const shopwatch = '/shopwatch';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    TimeSource? timeSource,
  }) {
    final Widget page = switch (settings.name) {
      AppRoutes.classicStopwatch =>
        ClassicStopwatchPage(timeSource: timeSource),
      AppRoutes.shopwatch => const ShopwatchPage(),
      _ => const LandingPage(),
    };

    return MaterialPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
