import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/app/app.dart';

void main() {
  testWidgets('app launches to the Shopwatch screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SwatchApp());

    expect(find.text('Shopwatch'), findsOneWidget);
  });
}
