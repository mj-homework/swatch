/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';
import 'package:flutter/services.dart';
import 'package:swatch/core/swatch/time_source.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/services/hints_seen_store.dart';
import 'package:swatch/core/services/sound_player.dart';

/// App-wide services, created once in `main` and shared by every page
/// (Stopwatch and Shopwatch alike).
///
/// [sound] is the single app-wide [SoundPlayer]; pages use it but never
/// dispose it.
class AppDependencies {
  AppDependencies(
      {this.timeSource,
      Random? random,
      GameConfig? config,
      SoundPlayer? sound,
      HintsSeenStore? hintsStore,
      Future<void> Function()? haptic})
      : random = random ?? Random(),
        config = config ?? GameConfig(),
        sound = sound ?? AudioSoundPlayer(),
        hintsStore = hintsStore ?? InMemoryHintsSeenStore(),
        haptic = haptic ?? HapticFeedback.mediumImpact;

  final TimeSource? timeSource;
  final Random random;
  final GameConfig config;
  final SoundPlayer sound;
  final HintsSeenStore hintsStore;
  final Future<void> Function() haptic;
  int _sequence = 0;

  String newRoundId() => '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}_${random.nextInt(1 << 32)}';
}
