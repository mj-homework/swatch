import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/presentation/pages/game_arguments.dart';
import 'package:swatch/features/shopwatch/presentation/pages/game_page.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

import '../../core/stopwatch/helpers/fake_time_source.dart';
import 'fakes.dart';

void main() {
  testWidgets('Add to cart plays a scan sound for each result accuracy',
      (tester) async {
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
      home: GamePage(
        dependencies: dependencies,
        arguments: const GameArguments(
          nickname: 'Guest',
          count: 2,
          difficulty: Difficulty.easy,
          owned: false,
        ),
      ),
    ));

    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.pump();
    time.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanAccuracies, [Accuracy.perfect]);

    time.advance(const Duration(milliseconds: 1751));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanAccuracies, [Accuracy.perfect, Accuracy.missed]);
  });
}
