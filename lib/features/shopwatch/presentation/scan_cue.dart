/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:swatch/core/services/sound_player.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';

SoundCue scanCueForAccuracy(Accuracy accuracy) => switch (accuracy) {
      Accuracy.perfect => SoundCue.scanPerfect,
      Accuracy.close => SoundCue.scanClose,
      Accuracy.fair => SoundCue.scanFair,
      Accuracy.missed => SoundCue.scanError,
    };
