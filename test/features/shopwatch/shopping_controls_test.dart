/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shopping_controls.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

void main() {
  testWidgets('double-tap runs only the secondary action', (tester) async {
    var primaryCalls = 0;
    var doubleCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingControls(
            start: () => primaryCalls++,
            onDoubleStart: () => doubleCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.pump();

    expect(primaryCalls, 0);
    expect(doubleCalls, 1);
  });

  testWidgets('single-tap runs the primary action after the double-tap window',
      (tester) async {
    var primaryCalls = 0;
    var doubleCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingControls(
            start: () => primaryCalls++,
            onDoubleStart: () => doubleCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));

    expect(primaryCalls, 1);
    expect(doubleCalls, 0);
  });
}
