/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/core/widgets/analog_clock.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/presentation/pages/shopwatch_page.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/pos_terminal_sheet.dart';
import 'package:swatch/features/shopwatch/shopwatch_dependencies.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

import '../../core/stopwatch/helpers/fake_time_source.dart';
import 'fakes.dart';

void main() {
  late FakeTimeSource time;
  late FakeSound sound;
  late ShopwatchDependencies dependencies;

  setUp(() {
    time = FakeTimeSource();
    sound = FakeSound();
    dependencies = ShopwatchDependencies(
      config: GameConfig(
        minGoal: const Duration(seconds: 1),
        maxGoal: const Duration(seconds: 1),
        minGap: const Duration(seconds: 1),
        maxGap: const Duration(seconds: 1),
      ),
      random: Random(1),
      timeSource: time,
      soundFactory: () => sound,
      hintsStore: FakeHintsSeenStore(),
    );
  });

  Future<void> pumpShopwatch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: ShopwatchPage(dependencies: dependencies),
    ));
    await tester.pump();
  }

  /// Advances the fake clock and pumps a frame so the ticker updates the clock display.
  Future<void> elapse(WidgetTester tester, Duration duration) async {
    time.advance(duration);
    await tester.pump(const Duration(milliseconds: 16));
  }

  String displayedTime(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(ShopwatchKeys.time)).data!;

  group('Shopwatch: Widget interactions', () {
    testWidgets('tapping pause freezes the clock and tapping resume unfreezes it', (tester) async {
      await pumpShopwatch(tester);

      expect(displayedTime(tester), '00:00.000');
      expect(find.byType(AnalogClock), findsOneWidget);

      // Start the shopping game
      await tester.longPress(find.byKey(ShopwatchKeys.start));
      await tester.pump();

      expect(find.text(ShopwatchStrings.pause), findsOneWidget);

      // Elapsed time increases with the clock
      await elapse(tester, const Duration(seconds: 1));
      expect(displayedTime(tester), '00:01.000');

      await elapse(tester, const Duration(milliseconds: 250));
      expect(displayedTime(tester), '00:01.250');

      // Tap pause ("Coffee break")
      await tester.tap(find.byKey(ShopwatchKeys.pause));
      await tester.pump();

      expect(find.text(ShopwatchStrings.resume), findsOneWidget);

      // Clock freezes while paused
      await elapse(tester, const Duration(seconds: 3));
      expect(displayedTime(tester), '00:01.250');

      // Tap resume ("Back to it")
      await tester.tap(find.byKey(ShopwatchKeys.pause));
      await tester.pump();

      expect(find.text(ShopwatchStrings.pause), findsOneWidget);

      // Clock unfreezes and resumes advancing
      await elapse(tester, const Duration(milliseconds: 500));
      expect(displayedTime(tester), '00:01.750');
    });

    testWidgets('tapping checkout with items in cart pauses the clock, continuing resumes, and paying resets clock to zero', (tester) async {
      await pumpShopwatch(tester);

      // Start the shopping game
      await tester.longPress(find.byKey(ShopwatchKeys.start));
      await tester.pump(const Duration(milliseconds: 555)); // quick-start lockout

      // Advance clock and add an item to the cart
      await elapse(tester, const Duration(seconds: 1));
      await tester.tap(find.byKey(ShopwatchKeys.add));
      await tester.pump();

      await elapse(tester, const Duration(seconds: 1));
      expect(displayedTime(tester), '00:02.000');

      // Tap Pay to initiate checkout (pauses the running game)
      await tester.tap(find.byKey(ShopwatchKeys.pay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PosTerminalSheet), findsOneWidget);

      // Clock is paused while in checkout
      time.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 16));
      expect(displayedTime(tester), '00:02.000');

      // Cancel checkout and continue shopping
      await tester.tap(find.byKey(ShopwatchKeys.skip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PosTerminalSheet), findsNothing);
      expect(displayedTime(tester), '00:02.000');

      // Clock continues running after returning to shopping
      await elapse(tester, const Duration(seconds: 1));
      expect(displayedTime(tester), '00:03.000');

      // Tap Pay again
      await tester.tap(find.byKey(ShopwatchKeys.pay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Approve payment via contactless tap in the checkout sheet
      final contactless = find.descendant(
        of: find.byType(PosTerminalSheet),
        matching: find.byIcon(Icons.contactless),
      );
      await tester.tap(contactless);
      await tester.pump();

      // Dismiss receipt with "Bag it & go"
      await tester.tap(find.byKey(ShopwatchKeys.dismiss));
      await tester.pumpAndSettle();
      await tester.idle();
      await tester.pump();

      expect(find.byType(PosTerminalSheet), findsNothing);

      // Verifying the clock: paying resets the clock to zero
      expect(displayedTime(tester), '00:00.000');

      // Clock stays stopped after round ends
      await elapse(tester, const Duration(seconds: 3));
      expect(displayedTime(tester), '00:00.000');
    });

    testWidgets('tapping checkout with empty cart pauses the clock, continuing resumes, and checking out anyway resets clock to zero', (tester) async {
      await pumpShopwatch(tester);

      // Start the shopping game
      await tester.longPress(find.byKey(ShopwatchKeys.start));
      await tester.pump();

      await elapse(tester, const Duration(seconds: 1));
      expect(displayedTime(tester), '00:01.000');

      // Tap Pay with empty cart
      await tester.tap(find.byKey(ShopwatchKeys.pay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nothing to pay.'), findsOneWidget);

      // Clock is paused while dialog is showing
      time.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 16));
      expect(displayedTime(tester), '00:01.000');

      // Continue shopping (resumes ticker, so avoid pumpAndSettle)
      await tester.tap(find.byKey(ShopwatchKeys.continueShopping));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(displayedTime(tester), '00:01.000');

      // Clock continues running
      await elapse(tester, const Duration(seconds: 1));
      expect(displayedTime(tester), '00:02.000');

      // Tap Pay again with empty cart
      await tester.tap(find.byKey(ShopwatchKeys.pay));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Choose "Checkout anyway" (ends round and stops ticker)
      await tester.tap(find.byKey(ShopwatchKeys.cancelShopping));
      await tester.pumpAndSettle();

      // Verifying the clock: ending round resets the clock to zero
      expect(displayedTime(tester), '00:00.000');

      // Clock remains stopped at zero
      await elapse(tester, const Duration(seconds: 3));
      expect(displayedTime(tester), '00:00.000');
    });

    testWidgets('long-pressing Shop! locks Add to cart for 555 ms', (tester) async {
      await pumpShopwatch(tester);

      await tester.longPress(find.byKey(ShopwatchKeys.start));
      await tester.pump();

      // A quick follow-up tap lands on the locked Add to cart button
      await elapse(tester, const Duration(seconds: 1));
      await tester.tap(find.byKey(ShopwatchKeys.add), warnIfMissed: false);
      await tester.pump();
      expect(sound.scanAccuracies, isEmpty);

      await tester.pump(const Duration(milliseconds: 555));
      await tester.tap(find.byKey(ShopwatchKeys.add));
      await tester.pump();
      expect(sound.scanAccuracies, hasLength(1));
    });

    testWidgets('long-pressing pay immediately ends round and resets clock to zero', (tester) async {
      await pumpShopwatch(tester);

      // Start the shopping game
      await tester.longPress(find.byKey(ShopwatchKeys.start));
      await tester.pump();

      await elapse(tester, const Duration(seconds: 2));
      expect(displayedTime(tester), '00:02.000');

      // Long-press Pay to reset at once
      await tester.longPress(find.byKey(ShopwatchKeys.pay));
      await tester.pumpAndSettle();

      // Verifying the clock: resets to zero
      expect(displayedTime(tester), '00:00.000');

      // Clock remains stopped
      await elapse(tester, const Duration(seconds: 2));
      expect(displayedTime(tester), '00:00.000');
    });
  });
}
