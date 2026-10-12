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
  static const clear = 'Put it all back';
  static const pay = 'Pay';
  static const empty = 'Your cart is empty.';
  static const gotIt = 'Got it';
  static const showHints = 'Show hints';
  static const hintsLabel = 'Hints';
  static const classicHintTitle = 'Classic Stopwatch';
  static const classicHintText = 'The by-the-spec solution: start, pause, reset, laps, analog clock.';
  static const shopHintTitle = 'Start a shopping game';
  static const shopHintText = 'Tap to start with item number config; long-tap to start at once.';
  static const payHintTitle = 'Pay';
  static const payHintText = 'Tap to check out; long-tap to reset at once.';
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
  static const hintsOverlay = ValueKey('shop-hints-overlay');
  static const hintsGotIt = ValueKey('shop-hints-got-it');
}
