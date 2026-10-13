/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

import 'package:swatch/features/shopwatch/presentation/shopwatch_keys.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_strings.dart';

class ShoppingButtons extends StatelessWidget {
  const ShoppingButtons({
    super.key,
    this.onStart,
    this.onPause,
    this.onAdd,
    this.onPay,
    this.onLongStart,
    this.onLongPay,
    this.paused = false,
    this.landscape = false,
    this.inGame = false,
  });

  final VoidCallback? onStart, onPause, onAdd, onPay;
  final VoidCallback? onLongStart, onLongPay;
  final bool paused;
  final bool landscape;
  final bool inGame;

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
  Widget build(BuildContext context) {
    final startButton = _button(
      key: ShopwatchKeys.start,
      title: ShopwatchStrings.shop,
      icon: Icons.shopping_cart_outlined,
      onPressed: onStart,
      onLongPressed: onLongStart,
      primary: true,
    );

    final pauseButton = _button(
      key: ShopwatchKeys.pause,
      title: paused ? ShopwatchStrings.resume : ShopwatchStrings.pause,
      icon: paused ? Icons.shopping_cart_checkout : Icons.storefront_outlined,
      onPressed: onPause,
    );

    final addButton = _button(
      key: ShopwatchKeys.add,
      title: ShopwatchStrings.add,
      icon: Icons.add_shopping_cart,
      onPressed: onAdd,
      primary: true,
    );

    final payButton = _button(
      key: ShopwatchKeys.pay,
      title: ShopwatchStrings.pay,
      icon: Icons.contactless,
      onPressed: onPay,
      onLongPressed: onLongPay,
    );

    if (landscape) {
      return Column(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          pauseButton,
          payButton,
          inGame ? addButton : startButton,
        ],
      );
    }

    return Column(spacing: 8, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(spacing: 8, children: [Expanded(child: pauseButton), Expanded(child: payButton)]),
      inGame ? addButton : startButton
    ]);
  }
}
