/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/core/stopwatch/time_source.dart';
import 'package:swatch/features/stopwatch/presentation/stopwatch_page.dart';
import 'package:swatch/features/landing/landing_page.dart';
import 'package:swatch/features/shopwatch/presentation/pages/shopwatch_page.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';

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
    final services = dependencies ?? ShopwatchDependencies(timeSource: timeSource);
    final Widget page = switch (settings.name) {
      AppRoutes.stopwatch => StopwatchPage(timeSource: timeSource),
      AppRoutes.shopwatch => ShopwatchPage(dependencies: services),
      _ => const LandingPage(),
    };

    return MaterialPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
