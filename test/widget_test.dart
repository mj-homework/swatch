/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/app/app.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';

import 'features/shopwatch/fakes.dart';

void main() {
  testWidgets('app launches to the Shopwatch screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SwatchApp(
      shopwatchDependencies: ShopwatchDependencies(
        hintsStore: FakeHintsSeenStore(),
        soundFactory: FakeSound.new,
      ),
    ));

    expect(find.text('Shopwatch'), findsOneWidget);
  });

  testWidgets('app bar About action shows the copyright notice', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SwatchApp(
      shopwatchDependencies: ShopwatchDependencies(
        hintsStore: FakeHintsSeenStore(),
        soundFactory: FakeSound.new,
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
