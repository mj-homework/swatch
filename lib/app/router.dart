/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/features/stopwatch/presentation/stopwatch_page.dart';
import 'package:swatch/features/landing/presentation/pages/landing_page.dart';
import 'package:swatch/features/shopwatch/presentation/pages/shopwatch_page.dart';
import 'package:swatch/app/app_dependencies.dart';

abstract final class AppRoutes {
  static const landing = '/';
  static const stopwatch = '/swatch';
  static const shopwatch = '/shopwatch';
}

class AppRouter {
  const AppRouter._();

  /// Every page gets the same app-scoped [dependencies], so all of them share
  /// one time source and one sound player.
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required AppDependencies dependencies,
  }) {
    final Widget page = switch (settings.name) {
      AppRoutes.stopwatch => StopwatchPage(
          timeSource: dependencies.timeSource,
          soundPlayer: dependencies.sound,
        ),
      AppRoutes.shopwatch => ShopwatchPage(dependencies: dependencies),
      _ => const LandingPage(),
    };

    return MaterialPageRoute<void>(
      builder: (_) => page,
      settings: settings,
    );
  }
}
