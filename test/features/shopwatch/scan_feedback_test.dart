/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/core/services/sound_player.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/presentation/pages/shopwatch_page.dart';
import 'package:swatch/app/app_dependencies.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

import '../../core/stopwatch/helpers/fake_time_source.dart';
import 'fakes.dart';

void main() {
  testWidgets('mute stops Shopwatch ticking and unmute resumes it', (tester) async {
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sound = FakeSound();
    final dependencies = AppDependencies(
      random: Random(1),
      timeSource: FakeTimeSource(),
      sound: sound,
      hintsStore: FakeHintsSeenStore(),
    );
    await tester.pumpWidget(MaterialApp(home: ShopwatchPage(dependencies: dependencies)));

    await tester.longPress(find.byKey(ShopwatchKeys.start));
    await tester.pump();
    expect(sound.ticking, isTrue);

    await tester.tap(find.byKey(ShopwatchKeys.mute));
    await tester.pump();
    expect(sound.ticking, isFalse);

    await tester.tap(find.byKey(ShopwatchKeys.mute));
    await tester.pump();
    expect(sound.ticking, isTrue);
  });

  testWidgets('Add to cart plays a scan sound for each result accuracy', (tester) async {
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final time = FakeTimeSource();
    final sound = FakeSound();
    final dependencies = AppDependencies(
      config: GameConfig(
        minGoal: const Duration(seconds: 1),
        maxGoal: const Duration(seconds: 1),
        minGap: const Duration(seconds: 1),
        maxGap: const Duration(seconds: 1),
      ),
      random: Random(1),
      timeSource: time,
      sound: sound,
      hintsStore: FakeHintsSeenStore(),
    );

    await tester.pumpWidget(MaterialApp(
      home: ShopwatchPage(
        dependencies: dependencies,
      ),
    ));

    await tester.longPress(find.byKey(ShopwatchKeys.start));
    await tester.pump(const Duration(milliseconds: 555)); // quick-start lockout
    time.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanCues, [SoundCue.scanPerfect]);

    time.advance(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanCues, [SoundCue.scanPerfect, SoundCue.scanClose]);

    time.advance(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanCues, [SoundCue.scanPerfect, SoundCue.scanClose, SoundCue.scanFair]);

    time.advance(const Duration(milliseconds: 1751));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.byKey(ShopwatchKeys.add));
    await tester.pump();
    expect(sound.scanCues, [SoundCue.scanPerfect, SoundCue.scanClose, SoundCue.scanFair, SoundCue.scanError]);
  });
}
