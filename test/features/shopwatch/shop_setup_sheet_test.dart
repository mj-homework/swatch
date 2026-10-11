import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/presentation/widgets/shop_setup_sheet.dart';
import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

Future<void> open(WidgetTester tester, void Function(ShopChoice?) onResult) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async =>
            onResult(await showShopSetup(context, maxItems: 5)),
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('autostarts after 3 s with unlimited items', (tester) async {
    ShopChoice? result;
    var done = false;
    await open(tester, (r) { result = r; done = true; });
    expect(find.text('Shop! (3)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Shop! (2)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(result, isNotNull);
    expect(result!.count, isNull);
  });

  testWidgets('tapping the dropdown cancels the countdown', (tester) async {
    ShopChoice? result;
    await open(tester, (r) => result = r);
    await tester.tap(find.byKey(ShopwatchKeys.itemsDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(ShopwatchKeys.shopConfirm), findsOneWidget);
    expect(find.text('Shop!'), findsOneWidget);
    await tester.tap(find.byKey(ShopwatchKeys.shopConfirm));
    await tester.pumpAndSettle();
    expect(result!.count, 2);
  });

  testWidgets('cancel returns null', (tester) async {
    ShopChoice? result = const ShopChoice(1);
    await open(tester, (r) => result = r);
    await tester.tap(find.byKey(ShopwatchKeys.shopCancel));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
