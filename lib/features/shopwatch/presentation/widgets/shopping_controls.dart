/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

class ShoppingControls extends StatelessWidget {
  const ShoppingControls({
    super.key,
    this.onStart,
    this.onPause,
    this.onAdd,
    this.onPay,
    this.onLongStart,
    this.onLongPay,
    this.paused = false,
  });

  final VoidCallback? onStart, onPause, onAdd, onPay;
  final VoidCallback? onLongStart, onLongPay;
  final bool paused;

  Widget _button({
    required Key key,
    required String title,
    required IconData icon,
    required VoidCallback? onPressed,
    VoidCallback? onLongPressed,
    bool primary = false,
  }) {
    final icon0 = Icon(icon);
    final label = Text(title);
    final onLongPress = onPressed == null ? null : onLongPressed;
    return primary
        ? FilledButton.icon(
            key: key,
            onPressed: onPressed,
            onLongPress: onLongPress,
            icon: icon0,
            label: label,
          )
        : OutlinedButton.icon(
            key: key,
            onPressed: onPressed,
            onLongPress: onLongPress,
            icon: icon0,
            label: label,
          );
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
            onPressed: onStart,
            onLongPressed: onLongStart,
          ),
          _button(
            key: ShopwatchKeys.pause,
            title: paused ? ShopwatchStrings.resume : ShopwatchStrings.pause,
            icon: paused ? Icons.shopping_cart_checkout : Icons.storefront_outlined,
            onPressed: onPause,
          ),
          _button(
            key: ShopwatchKeys.add,
            title: ShopwatchStrings.add,
            icon: Icons.add_shopping_cart,
            onPressed: onAdd,
            primary: true,
          ),
          _button(
            key: ShopwatchKeys.pay,
            title: ShopwatchStrings.pay,
            icon: Icons.contactless,
            onPressed: onPay,
            onLongPressed: onLongPay,
          ),
        ],
      );
}
