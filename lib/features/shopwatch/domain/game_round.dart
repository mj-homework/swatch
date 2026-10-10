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
  /// [goals] are absolute times on the round's single running clock. Only the
  /// goals reached so far are known: each next goal depends on the click time.
  GameRound(
      {required this.config,
      required this.difficulty,
      required this.nickname,
      required this.id,
      List<String> names = const [],
      List<Duration> goals = const [],
      List<ItemResult> results = const [],
      this.status = RoundStatus.setup,
      this.ownedNickname = false})
      : names = List.unmodifiable(names),
        goals = List.unmodifiable(goals),
        results = List.unmodifiable(results);
  final GameConfig config;
  final Difficulty difficulty;
  final String nickname, id;
  final bool ownedNickname;
  final List<String> names;
  final List<Duration> goals;
  final List<ItemResult> results;
  final RoundStatus status;
  int get itemCount => names.length;
  Duration get totalError =>
      results.fold(Duration.zero, (sum, r) => sum + r.difference.abs());

  /// Click time of the last item on the continuous clock.
  Duration get totalTime =>
      results.isEmpty ? Duration.zero : results.last.actual;
  GameItem? get currentItem =>
      results.length < names.length && results.length < goals.length
          ? GameItem(names[results.length], goals[results.length])
          : null;
  GameRound copyWith(
          {RoundStatus? status,
          List<ItemResult>? results,
          List<Duration>? goals}) =>
      GameRound(
        config: config,
        difficulty: difficulty,
        nickname: nickname,
        id: id,
        ownedNickname: ownedNickname,
        names: names,
        goals: goals ?? this.goals,
        results: results ?? this.results,
        status: status ?? this.status,
      );
}
