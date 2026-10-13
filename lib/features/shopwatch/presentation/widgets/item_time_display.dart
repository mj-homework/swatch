/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swatch/core/formatting/duration_format.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/presentation/shopwatch_keys.dart';

/// Digital readout on the clock face. Harder rounds hide the time, fully or
/// after [GameConfig.normalHideAfter].
class ItemTimeDisplay extends StatelessWidget {
  const ItemTimeDisplay({super.key, required this.elapsed, required this.round});

  final ValueListenable<Duration> elapsed;

  /// Current round; null before the first round starts.
  final GameRound? round;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Duration>(
        valueListenable: elapsed,
        builder: (context, value, _) {
          final round = this.round;
          final showTime = round == null ||
              round.difficulty == Difficulty.easy ||
              (round.difficulty == Difficulty.normal && value < round.config.normalHideAfter);
          final text = showTime ? formatElapsed(value) : '--:--.---';
          final colors = Theme.of(context).colorScheme;
          return DecoratedBox(
            decoration: ShapeDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: StadiumBorder(side: BorderSide(color: colors.outlineVariant)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                text,
                key: ShopwatchKeys.time,
                semanticsLabel: showTime ? 'Item time $text' : 'Item time hidden',
                style: TextTheme.of(context).titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          );
        },
      );
}
