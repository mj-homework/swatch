/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';
import 'package:flutter/services.dart';
import 'package:swatch/core/stopwatch/time_source.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/services/sound_player.dart';

/// App-scoped services; pages own the sound players produced by the factory.
class ShopwatchDependencies {
  ShopwatchDependencies({this.timeSource, Random? random, GameConfig? config,
    SoundPlayer Function()? soundFactory, Future<void> Function()? haptic})
      : random = random ?? Random(), config = config ?? GameConfig(),
        soundFactory = soundFactory ?? CheckoutSoundPlayer.new,
        haptic = haptic ?? HapticFeedback.mediumImpact;
  final TimeSource? timeSource;
  final Random random;
  final GameConfig config;
  final SoundPlayer Function() soundFactory;
  final Future<void> Function() haptic;
  int _sequence = 0;
  String newRoundId() => '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}_${random.nextInt(1 << 32)}';
}
