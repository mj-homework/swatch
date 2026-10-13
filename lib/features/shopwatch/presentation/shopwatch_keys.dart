/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';

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
