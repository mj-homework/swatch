/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:swatch/features/shopwatch/shopwatch_strings.dart';

class ShoppingControls extends StatelessWidget {
  const ShoppingControls({
    super.key,
    this.start,
    this.pause,
    this.add,
    this.pay,
    this.onDoubleStart,
    this.onDoublePause,
    this.onDoubleAdd,
    this.onDoublePay,
    this.paused = false,
  });

  final VoidCallback? start, pause, add, pay;
  final VoidCallback? onDoubleStart, onDoublePause, onDoubleAdd, onDoublePay;
  final bool paused;

  Widget _button({
    required Key key,
    required String title,
    required IconData icon,
    required VoidCallback? onPressed,
    VoidCallback? onDoublePressed,
    bool primary = false,
  }) {
    final icon0 = Icon(icon);
    final label = Text(title);
    return _DoublePressAction(
      onPressed: onPressed,
      onDoublePressed: onDoublePressed,
      builder: (handlePress) => primary
          ? FilledButton.icon(
              key: key,
              onPressed: handlePress,
              icon: icon0,
              label: label,
            )
          : OutlinedButton.icon(
              key: key,
              onPressed: handlePress,
              icon: icon0,
              label: label,
            ),
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
            onPressed: start,
            onDoublePressed: onDoubleStart,
          ),
          _button(
            key: ShopwatchKeys.pause,
            title: paused ? ShopwatchStrings.resume : ShopwatchStrings.pause,
            icon: paused ? Icons.shopping_cart_checkout : Icons.storefront_outlined,
            onPressed: pause,
            onDoublePressed: onDoublePause,
          ),
          _button(
            key: ShopwatchKeys.add,
            title: ShopwatchStrings.add,
            icon: Icons.add_shopping_cart,
            onPressed: add,
            onDoublePressed: onDoubleAdd,
            primary: true,
          ),
          _button(
            key: ShopwatchKeys.pay,
            title: ShopwatchStrings.pay,
            icon: Icons.contactless,
            onPressed: pay,
            onDoublePressed: onDoublePay,
          ),
        ],
      );
}

class _DoublePressAction extends StatefulWidget {
  const _DoublePressAction({
    required this.onPressed,
    required this.onDoublePressed,
    required this.builder,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onDoublePressed;
  final Widget Function(VoidCallback? onPressed) builder;

  @override
  State<_DoublePressAction> createState() => _DoublePressActionState();
}

class _DoublePressActionState extends State<_DoublePressAction> {
  Timer? _singlePressTimer;

  @override
  void didUpdateWidget(_DoublePressAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) {
      _singlePressTimer?.cancel();
      _singlePressTimer = null;
    }
  }

  @override
  void dispose() {
    _singlePressTimer?.cancel();
    super.dispose();
  }

  void _handlePress() {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;

    final onDoublePressed = widget.onDoublePressed;
    if (onDoublePressed == null) {
      onPressed();
      return;
    }

    final pendingPress = _singlePressTimer;
    if (pendingPress != null) {
      pendingPress.cancel();
      _singlePressTimer = null;
      onDoublePressed();
      return;
    }

    _singlePressTimer = Timer(kDoubleTapTimeout, () {
      _singlePressTimer = null;
      if (mounted) widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(
        widget.onPressed == null ? null : _handlePress,
      );
}
