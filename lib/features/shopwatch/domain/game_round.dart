import 'package:flutter/foundation.dart';
import 'game_config.dart';

enum RoundStatus { setup, ready, playing, finished }

@immutable
class GameItem {
  const GameItem(this.name, this.goal);
  final String name;
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
  GameRound({required this.config, required this.difficulty, required this.nickname,
    required this.id, List<GameItem> items = const [], List<ItemResult> results = const [],
    this.status = RoundStatus.setup, this.ownedNickname = false})
      : items = List.unmodifiable(items), results = List.unmodifiable(results);
  final GameConfig config;
  final Difficulty difficulty;
  final String nickname, id;
  final bool ownedNickname;
  final List<GameItem> items;
  final List<ItemResult> results;
  final RoundStatus status;
  Duration get totalError => results.fold(Duration.zero, (sum, r) => sum + r.difference.abs());
  Duration get totalTime => results.fold(Duration.zero, (sum, r) => sum + r.actual);
  GameItem? get currentItem => results.length < items.length ? items[results.length] : null;
  GameRound copyWith({RoundStatus? status, List<ItemResult>? results}) => GameRound(
    config: config, difficulty: difficulty, nickname: nickname, id: id,
    ownedNickname: ownedNickname, items: items, results: results ?? this.results,
    status: status ?? this.status,
  );
}
