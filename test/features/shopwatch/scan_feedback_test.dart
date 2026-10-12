/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/presentation/pages/shopwatch_page.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

import '../../core/stopwatch/helpers/fake_time_source.dart';
import 'fakes.dart';

void main() {
  testWidgets('Add to cart plays a scan sound for each result accuracy', (tester) async {
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final time = FakeTimeSource();
    final sound = FakeSound();
    final dependencies = ShopwatchDependencies(
      config: GameConfig(
        minGoal: const Duration(seconds: 1),
        maxGoal: const Duration(seconds: 1),
        minGap: const Duration(seconds: 1),
        maxGap: const Duration(seconds: 1),
      ),
      random: Random(1),
      timeSource: time,
      soundFactory: () => sound,
    );

    await tester.pumpWidget(MaterialApp(
      home: ShopwatchPage(
        dependencies: dependencies,
      ),
    ));

    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.pump();
    time.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanAccuracies, [Accuracy.perfect]);

    time.advance(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanAccuracies, [Accuracy.perfect, Accuracy.close]);

    time.advance(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanAccuracies, [Accuracy.perfect, Accuracy.close, Accuracy.fair]);

    time.advance(const Duration(milliseconds: 1751));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanAccuracies, [Accuracy.perfect, Accuracy.close, Accuracy.fair, Accuracy.missed]);
  });
}
