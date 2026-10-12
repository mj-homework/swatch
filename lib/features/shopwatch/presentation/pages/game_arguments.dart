/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import '../../domain/game_config.dart';

class GameArguments {
  const GameArguments({
    required this.nickname,
    required this.count,
    required this.difficulty,
    required this.owned,
  });

  final String nickname;
  final int count;
  final Difficulty difficulty;
  final bool owned;
}
