/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/core/widgets/analog_clock.dart';

void main() {
  testWidgets('digital display updates over the analog clock face',
      (tester) async {
    final elapsed = ValueNotifier(Duration.zero);
    addTearDown(elapsed.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 240,
              child: AnalogClock(
                elapsed: elapsed,
                digitalDisplay: ValueListenableBuilder<Duration>(
                  valueListenable: elapsed,
                  builder: (_, value, __) => Text('${value.inMilliseconds}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final clockStack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(AnalogClock),
        matching: find.byType(Stack),
      ),
    );
    final handsOverlay = clockStack.children.last as CustomPaint;
    expect((handsOverlay.painter as AnalogClockPainter).handsOnly, isTrue);

    elapsed.value = const Duration(milliseconds: 1234);
    await tester.pump();

    expect(find.text('1234'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
