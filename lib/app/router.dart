/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import '../core/stopwatch/time_source.dart';
import '../features/stopwatch/presentation/stopwatch_page.dart';
import '../features/landing/landing_page.dart';
import '../features/shopwatch/presentation/pages/shopwatch_page.dart';
import '../features/shopwatch/presentation/pages/game_arguments.dart';
import '../features/shopwatch/presentation/pages/game_page.dart';
import '../features/shopwatch/domain/shop_item.dart';
import '../features/shopwatch/shopwatch_dependencies.dart';

abstract final class AppRoutes {
  static const landing = '/';
  static const stopwatch = '/stopwatch';
  static const shopwatch = '/shopwatch';
  static const game = '/shopwatch/game';
  static const play = '/shopwatch/game/play';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    TimeSource? timeSource,
    ShopwatchDependencies? dependencies,
  }) {
    final services =
        dependencies ?? ShopwatchDependencies(timeSource: timeSource);
    final arguments = settings.arguments;
    final Widget page = switch (settings.name) {
      AppRoutes.stopwatch => StopwatchPage(timeSource: timeSource),
      AppRoutes.shopwatch => ShopwatchPage(dependencies: services),
      AppRoutes.game => ShopwatchPage(dependencies: services),
      AppRoutes.play => arguments is GameArguments &&
              arguments.count >= 1 &&
              arguments.count <= shopItemCombinationCount
          ? GamePage(dependencies: services, arguments: arguments)
          : ShopwatchPage(dependencies: services),
      _ => const LandingPage(),
    };

    return MaterialPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
