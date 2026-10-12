/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:swatch/features/shopwatch/services/sound_player.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';

class FakeSound implements SoundPlayer {
  int plays = 0, disposals = 0;
  final scanAccuracies = <Accuracy>[];
  @override
  Future<void> playCheckoutBeep() async {
    plays++;
  }

  @override
  Future<void> playScan(Accuracy accuracy) async {
    scanAccuracies.add(accuracy);
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}
