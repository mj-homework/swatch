/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shopping_buttons.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_keys.dart';

void main() {
  testWidgets('long-press runs only the secondary action', (tester) async {
    var primaryCalls = 0;
    var doubleCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingButtons(
            onStart: () => primaryCalls++,
            onLongStart: () => doubleCalls++,
          ),
        ),
      ),
    );

    await tester.longPress(find.byKey(ShopwatchKeys.start));
    await tester.pump();

    expect(primaryCalls, 0);
    expect(doubleCalls, 1);
  });

  testWidgets('tap runs only the primary action', (tester) async {
    var primaryCalls = 0;
    var doubleCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingButtons(
            onStart: () => primaryCalls++,
            onLongStart: () => doubleCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ShopwatchKeys.start));
    await tester.pump();

    expect(primaryCalls, 1);
    expect(doubleCalls, 0);
  });
}
