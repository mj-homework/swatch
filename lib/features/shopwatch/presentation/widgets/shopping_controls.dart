import 'package:flutter/material.dart';
import '../../shopwatch_strings.dart';

class ShoppingControls extends StatelessWidget {
  const ShoppingControls({super.key, this.start, this.pause, this.add, this.pay, this.paused = false});

  final VoidCallback? start, pause, add, pay;
  final bool paused;

  Widget _button({
    required Key key,
    required String title,
    required IconData icon,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    final icon0 = Icon(icon);
    final label = Text(title);
    return primary
        ? FilledButton.icon(key: key, onPressed: onPressed, icon: icon0, label: label)
        : OutlinedButton.icon(key: key, onPressed: onPressed, icon: icon0, label: label);
  }

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _button(
            key: ShopwatchKeys.start,
            title: ShopwatchStrings.shop,
            icon: Icons.shopping_cart_outlined,
            onPressed: start,
          ),
          _button(
            key: ShopwatchKeys.pause,
            title: paused ? ShopwatchStrings.resume : ShopwatchStrings.pause,
            icon: paused ? Icons.shopping_cart_checkout : Icons.storefront_outlined,
            onPressed: pause,
          ),
          _button(
            key: ShopwatchKeys.add,
            title: ShopwatchStrings.add,
            icon: Icons.add_shopping_cart,
            onPressed: add,
            primary: true,
          ),
          _button(
            key: ShopwatchKeys.pay,
            title: ShopwatchStrings.pay,
            icon: Icons.contactless,
            onPressed: pay,
          ),
        ],
      );
}
