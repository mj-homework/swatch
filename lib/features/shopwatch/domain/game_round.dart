/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/shop_item.dart';

enum RoundStatus { setup, ready, playing, finished }

@immutable
class GameItem {
  const GameItem(this.shopItem, this.goal);
  final ShopItem shopItem;
  final Duration goal;
}

@immutable
class ItemResult {
  const ItemResult(this.item, this.actual, this.accuracy);
  final GameItem item;
  final Duration actual;
  final Accuracy accuracy;
  Duration get difference => actual - item.goal;
}

@immutable
class GameRound {
  /// [goals] are absolute times on the round's single running clock. Only the
  /// goals reached so far are known: each next goal depends on the click time.
  GameRound(
      {required this.config,
      required this.difficulty,
      required this.id,
      List<ShopItem> items = const [],
      this.limit,
      List<Duration> goals = const [],
      List<ItemResult> results = const [],
      this.status = RoundStatus.setup})
      : items = List.unmodifiable(items),
        goals = List.unmodifiable(goals),
        results = List.unmodifiable(results);
  final GameConfig config;
  final Difficulty difficulty;
  final String id;

  /// Number of items to buy; null means an endless round.
  final int? limit;
  final List<ShopItem> items;
  final List<Duration> goals;
  final List<ItemResult> results;
  final RoundStatus status;
  bool get isEndless => limit == null;
  int get itemCount => limit ?? items.length;
  Duration get totalError =>
      results.fold(Duration.zero, (sum, r) => sum + r.difference.abs());
  Duration get averageError => results.isEmpty
      ? Duration.zero
      : Duration(microseconds: totalError.inMicroseconds ~/ results.length);

  /// Click time of the last item on the continuous clock.
  Duration get totalTime =>
      results.isEmpty ? Duration.zero : results.last.actual;

  GameItem? get currentItem =>
      results.length < items.length && results.length < goals.length
          ? GameItem(items[results.length], goals[results.length])
          : null;
  GameRound copyWith(
          {RoundStatus? status,
          List<ItemResult>? results,
          List<Duration>? goals,
          List<ShopItem>? items}) =>
      GameRound(
        config: config,
        difficulty: difficulty,
        id: id,
        limit: limit,
        items: items ?? this.items,
        goals: goals ?? this.goals,
        results: results ?? this.results,
        status: status ?? this.status,
      );
}
