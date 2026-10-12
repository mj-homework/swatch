/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';

abstract final class ShopwatchStrings {
  static const shop = 'Shop!';
  static const pause = 'Coffee break';
  static const resume = 'Back to it';
  static const add = 'Add to cart';
  static const clear = 'Empty cart';
  static const pay = 'Pay';
  static const empty = 'Your cart is empty.';
  static const approved = 'Payment approved ✓';
  static const finePrint = 'No money was harmed in this transaction.';
  static String mood(Duration elapsed, bool paused) {
    if (paused) return 'Coffee break. Back in a minute.';
    if (elapsed.inMinutes < 1) return 'Just browsing…';
    if (elapsed.inMinutes < 5) return "Ooh, that's on sale.";
    if (elapsed.inMinutes < 15) return 'Do we really need a third one?';
    return 'The bag holder needs a bench.';
  }
}

abstract final class ShopwatchStyle {
  static const paper = Colors.white;
  static const ink = Color(0xFF242724);
  static const tag = Color(0xFFFFD85B);
  static const approved = Color(0xFF237B46);
  static const receipt = TextStyle(fontFamily: 'monospace', color: ink);
}

abstract final class ShopwatchKeys {
  static const start = ValueKey('shop-start');
  static const pause = ValueKey('shop-pause');
  static const add = ValueKey('shop-add');
  static const clear = ValueKey('shop-clear');
  static const pay = ValueKey('shop-pay');
  static const mute = ValueKey('shop-mute');
  static const time = ValueKey('shop-time');
  static const skip = ValueKey('shop-skip');
  static const itemsDropdown = ValueKey('shop-items-dropdown');
  static const shopConfirm = ValueKey('shop-setup-confirm');
  static const shopCancel = ValueKey('shop-setup-cancel');
  static const cancelShopping = ValueKey('shop-cancel-shopping');
  static const continueShopping = ValueKey('shop-continue-shopping');
  static const confirmPay = ValueKey('shop-confirm-pay');
  static const dismiss = ValueKey('shop-dismiss');
}
