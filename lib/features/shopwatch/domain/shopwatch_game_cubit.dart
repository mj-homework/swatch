import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/stopwatch/stopwatch_controller.dart';
import '../../../../core/stopwatch/time_source.dart';
import 'game_config.dart';
import 'game_round.dart';

/// Owns its engine; external callers only receive read-only timing values.
class ShopwatchGameCubit extends Cubit<GameRound> {
  ShopwatchGameCubit(
      {required GameConfig config,
      required Difficulty difficulty,
      required int? itemCount,
      required String nickname,
      required String roundId,
      required Random random,
      TimeSource? timeSource,
      bool ownedNickname = false})
      : _engine = StopwatchController(timeSource: timeSource),
        _random = random,
        super(_prepare(config, difficulty, itemCount, nickname, roundId, random,
            ownedNickname)) {
    _engine.addListener(_capture);
  }
  final StopwatchController _engine;
  final Random _random;
  int _lapBase = 0;
  bool _capturing = false;
  Duration get elapsed => _engine.elapsed;
  bool get isRunning => _engine.isRunning;
  static GameRound _prepare(GameConfig config, Difficulty difficulty,
      int? count, String nickname, String id, Random random, bool owned) {
    if (count != null && (count < 1 || count > config.items.length)) {
      throw ArgumentError.value(count, 'itemCount');
    }
    final names = config.items.toList()..shuffle(random);
    return GameRound(
        config: config,
        difficulty: difficulty,
        nickname: nickname,
        id: id,
        ownedNickname: owned,
        status: RoundStatus.ready,
        limit: count,
        names: count == null ? [names.first] : names.take(count).toList(),
        goals: [_between(random, config.minGoal, config.maxGoal)]);
  }

  /// Random duration in [low, high], millisecond resolution, inclusive.
  static Duration _between(Random random, Duration low, Duration high) =>
      Duration(
          milliseconds: low.inMilliseconds +
              random.nextInt(high.inMilliseconds - low.inMilliseconds + 1));

  void start() {
    if (isClosed || state.status != RoundStatus.ready) return;
    emit(state.copyWith(status: RoundStatus.playing));
    _engine.start();
  }

  void addToCart() {
    if (!isClosed && state.status == RoundStatus.playing) _engine.lap();
  }

  void _capture() {
    if (isClosed || _capturing || state.status != RoundStatus.playing) return;
    _capturing = true;
    try {
      final results = state.results.toList();
      final goals = state.goals.toList();
      final limit = state.limit;
      final names = state.names.toList();
      for (final lap in _engine.laps.skip(_lapBase + results.length)) {
        if (limit != null && results.length >= limit) break;
        final item = GameItem(names[results.length], goals[results.length]);
        results.add(ItemResult(item, lap.splitTime,
            state.config.accuracy(lap.splitTime - item.goal)));
        if (limit == null || results.length < limit) {
          goals.add(lap.splitTime +
              _between(_random, state.config.minGap, state.config.maxGap));
          if (limit == null && names.length <= results.length) {
            names.add(_nextName(names.last));
          }
        }
      }
      if (results.length == state.results.length) return;
      final finished = limit != null && results.length == limit;
      // pause synchronously notifies: the guard prevents duplicate capture.
      if (finished) _engine.pause();
      emit(state.copyWith(
          results: results,
          goals: goals,
          names: names,
          status: finished ? RoundStatus.finished : RoundStatus.playing));
    } finally {
      _capturing = false;
    }
  }

  /// Endless rounds: a random item that differs from the previous one.
  String _nextName(String previous) {
    final items = state.config.items;
    if (items.length < 2) return items.first;
    String next;
    do {
      next = items[_random.nextInt(items.length)];
    } while (next == previous);
    return next;
  }

  bool get isPaused => _engine.isPaused;

  /// Coffee break: freezes the clock; goals are on that clock, so nothing
  /// else changes.
  void togglePause() {
    if (!isClosed && state.status == RoundStatus.playing) _engine.togglePause();
  }

  /// Empty cart: drops the results and restarts at item 1 without touching
  /// the clock. The new first goal is "now" plus a regular gap.
  void emptyCart() {
    if (isClosed ||
        (state.status != RoundStatus.playing &&
            state.status != RoundStatus.finished)) {
      return;
    }
    final wasFinished = state.status == RoundStatus.finished;
    _lapBase = _engine.laps.length;
    emit(state.copyWith(results: [], goals: [
      _engine.elapsed +
          _between(_random, state.config.minGap, state.config.maxGap)
    ], status: RoundStatus.playing));
    if (wasFinished) _engine.togglePause();
  }

  /// Pay: zeroes and stops the clock but keeps the cart (results) as it is.
  void resetClock() {
    if (isClosed ||
        (state.status != RoundStatus.playing &&
            state.status != RoundStatus.finished)) {
      return;
    }
    emit(state.copyWith(status: RoundStatus.finished));
    _engine.reset();
  }

  // These operations deliberately cannot change an active round.
  void pause() {}
  void clear() {}
  void reset() {
    if (isClosed || state.status == RoundStatus.playing) return;
    _engine.reset();
    emit(state.copyWith(
        results: [],
        goals: state.goals.take(1).toList(),
        status: RoundStatus.ready));
  }

  @override
  Future<void> close() {
    _engine.removeListener(_capture);
    _engine.dispose();
    return super.close();
  }
}
