import 'package:flutter/material.dart';
import '../../shopwatch_strings.dart';

class ShoppingControls extends StatelessWidget {
  const ShoppingControls(
      {super.key,
      this.start,
      this.pause,
      this.add,
      this.clear,
      this.pay,
      this.paused = false});

  final VoidCallback? start, pause, add, clear, pay;
  final bool paused;

  Widget _button(Key key, String title, String action, IconData icon,
          VoidCallback? callback) =>
      OutlinedButton.icon(
          key: key,
          onPressed: callback,
          icon: Icon(icon),
          label: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title),
            Text(action, style: const TextStyle(fontSize: 11))
          ]));

  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _button(ShopwatchKeys.start, ShopwatchStrings.shop, 'start',
                Icons.shopping_cart_outlined, start),
            _button(
                ShopwatchKeys.pause,
                paused ? ShopwatchStrings.resume : ShopwatchStrings.pause,
                paused ? 'resume' : 'pause',
                paused
                    ? Icons.shopping_cart_checkout
                    : Icons.storefront_outlined,
                pause),
            _button(ShopwatchKeys.add, ShopwatchStrings.add, 'lap',
                Icons.add_shopping_cart, add),
            _button(ShopwatchKeys.clear, ShopwatchStrings.clear, 'clear laps',
                Icons.remove_shopping_cart_outlined, clear),
            _button(ShopwatchKeys.pay, ShopwatchStrings.pay, 'reset',
                Icons.contactless, pay),
          ]);
}
