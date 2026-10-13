/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/app/app.dart';
import 'package:swatch/app/router.dart';
import 'package:swatch/core/widgets/swatch_keys.dart';
import 'package:swatch/app/app_dependencies.dart';

import 'core/stopwatch/helpers/fake_time_source.dart';
import 'features/shopwatch/fakes.dart';

void main() {
  testWidgets('app launches to the Shopwatch screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SwatchApp(
      dependencies: AppDependencies(
        hintsStore: FakeHintsSeenStore(),
        sound: FakeSound(),
      ),
    ));

    expect(find.text('Shopwatch'), findsOneWidget);
  });

  testWidgets('Classic stopwatch uses the time source from dependencies', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final time = FakeTimeSource();
    await tester.pumpWidget(SwatchApp(
      dependencies: AppDependencies(
        timeSource: time,
        hintsStore: FakeHintsSeenStore(),
        sound: FakeSound(),
      ),
    ));

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(AppRoutes.stopwatch);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(SwatchKeys.startButton));
    await tester.pump();

    time.advance(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.widget<Text>(find.byKey(SwatchKeys.elapsedText)).data, '00:00.200');
  });

  testWidgets('app bar About action shows the copyright notice', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SwatchApp(
      dependencies: AppDependencies(
        hintsStore: FakeHintsSeenStore(),
        sound: FakeSound(),
      ),
    ));
    await tester.tap(find.byTooltip('About Shopwatch'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Copyright 2026 Juhász Mátyás (gatsby82)\n'
        'Licensed under the MIT License.',
      ),
      findsOneWidget,
    );
  });
}
