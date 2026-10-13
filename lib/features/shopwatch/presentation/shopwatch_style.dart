/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';

abstract final class ShopwatchStyle {
  static const paper = Colors.white;
  static const ink = Color(0xFF242724);
  static const tag = Color(0xFFFFD85B);
  static const approved = Color(0xFF237B46);
  static const receipt = TextStyle(fontFamily: 'monospace', color: ink);

  /// Receipt line colour per scan accuracy; dark enough to read on [paper].
  static Color accuracy(Accuracy accuracy) => switch (accuracy) {
        Accuracy.perfect => const Color(0xFF126A36),
        Accuracy.close => const Color(0xFF407221),
        Accuracy.fair => const Color(0xFF8C5800),
        Accuracy.missed => const Color(0xFFB32121),
      };
}
