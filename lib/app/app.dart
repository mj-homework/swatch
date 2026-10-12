/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/core/stopwatch/time_source.dart';
import 'package:swatch/app/router.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';

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

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: brightness == Brightness.light ? _lightScheme : _darkScheme,
    );

    final sized = Typography.englishLike2021.merge(base.textTheme);

    return base.copyWith(
      textTheme: sized.apply(fontSizeFactor: 0.9),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = shopwatchDependencies ?? ShopwatchDependencies(timeSource: timeSource);
    return MaterialApp(
      title: 'Swatch',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: AppRoutes.shopwatch,
      onGenerateInitialRoutes: (name) => [
        AppRouter.onGenerateRoute(
          RouteSettings(name: name),
          timeSource: timeSource,
          dependencies: dependencies,
        ),
      ],
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, timeSource: timeSource, dependencies: dependencies),
    );
  }
}
