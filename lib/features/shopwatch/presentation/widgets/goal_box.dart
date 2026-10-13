/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/material.dart';
import 'package:swatch/core/formatting/duration_format.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';

/// Shopping list line under the clock: the current item and its goal time,
/// or the game's tagline when no item is due.
class GoalBox extends StatelessWidget {
  const GoalBox({super.key, required this.round});

  /// Current round; null before the first round starts.
  final GameRound? round;

  @override
  Widget build(BuildContext context) {
    final round = this.round;
    final item = round?.currentItem;
    final titleStyle = TextTheme.of(context).titleMedium;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: secondary)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item == null)
            Text(
              'Add to cart at exactly the right millisecond!',
              textAlign: TextAlign.center,
              style: titleStyle,
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Collect ${item.shopItem.receiptLabel} at',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatElapsed(item.goal),
                  style: titleStyle?.copyWith(color: secondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          if (item != null && !round!.isEndless)
            Text(
              'Item ${round.results.length + 1} / ${round.itemCount}',
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
