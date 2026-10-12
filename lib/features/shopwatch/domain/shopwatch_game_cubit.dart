/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swatch/core/stopwatch/stopwatch_controller.dart';
import 'package:swatch/core/stopwatch/time_source.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shop_item.dart';

/// Owns its engine; external callers only receive read-only timing values.
class ShopwatchGameCubit extends Cubit<GameRound> {
  ShopwatchGameCubit(
      {required GameConfig config,
      required Difficulty difficulty,
      required int? itemCount,
      required String roundId,
      required Random random,
      TimeSource? timeSource})
      : _engine = StopwatchController(timeSource: timeSource),
        _random = random,
        super(_prepare(config, difficulty, itemCount, roundId, random)) {
    _engine.addListener(_capture);
  }

  final StopwatchController _engine;
  final Random _random;
  final List<ShopItem> _usedItems = [];
  int _lapBase = 0;
  bool _capturing = false;

  Duration get elapsed => _engine.elapsed;

  bool get isRunning => _engine.isRunning;

  static GameRound _prepare(GameConfig config, Difficulty difficulty, int? count, String id, Random random) {
    if (count != null && (count < 1 || count > shopItemCombinationCount)) {
      throw ArgumentError.value(count, 'itemCount');
    }
    return GameRound(
        config: config,
        difficulty: difficulty,
        id: id,
        status: RoundStatus.ready,
        limit: count,
        goals: [_between(random, config.minGoal, config.maxGoal)]);
  }

  /// Random duration in [low, high], millisecond resolution, inclusive.
  static Duration _between(Random random, Duration low, Duration high) =>
      Duration(milliseconds: low.inMilliseconds + random.nextInt(high.inMilliseconds - low.inMilliseconds + 1));

  void start() {
    if (isClosed || state.status != RoundStatus.ready) return;
    final item = _generateItem();
    emit(state.copyWith(status: RoundStatus.playing, items: [item]));
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
      final items = state.items.toList();
      final limit = state.limit;
      for (final lap in _engine.laps.skip(_lapBase + results.length)) {
        if (limit != null && results.length >= limit) break;
        final item = GameItem(items[results.length], goals[results.length]);
        results.add(ItemResult(item, lap.splitTime, state.config.accuracy(lap.splitTime - item.goal)));
        if (limit == null || results.length < limit) {
          goals.add(lap.splitTime + _between(_random, state.config.minGap, state.config.maxGap));
          items.add(_generateItem());
        }
      }
      if (results.length == state.results.length) return;
      final finished = limit != null && results.length == limit;
      // pause synchronously notifies: the guard prevents duplicate capture.
      if (finished) _engine.pause();
      emit(state.copyWith(
          results: results, goals: goals, items: items, status: finished ? RoundStatus.finished : RoundStatus.playing));
    } finally {
      _capturing = false;
    }
  }

  bool get isPaused => _engine.isPaused;

  ShopItem _generateItem() {
    final item = nextItem(_usedItems, _random);
    _usedItems.add(item);
    return item;
  }

  /// Coffee break: freezes the clock; goals are on that clock, so nothing
  /// else changes.
  void togglePause() {
    if (!isClosed && state.status == RoundStatus.playing) _engine.togglePause();
  }

  /// Empty cart: drops the results and restarts at item 1 without touching
  /// the clock. The new first goal is "now" plus a regular gap.
  void emptyCart() {
    if (isClosed || (state.status != RoundStatus.playing && state.status != RoundStatus.finished)) {
      return;
    }
    final wasFinished = state.status == RoundStatus.finished;
    _lapBase = _engine.laps.length;
    final item = _generateItem();
    emit(state.copyWith(
        results: [],
        goals: [_engine.elapsed + _between(_random, state.config.minGap, state.config.maxGap)],
        items: [item],
        status: RoundStatus.playing));
    if (wasFinished) _engine.togglePause();
  }

  /// Pay: zeroes and stops the clock but keeps the cart (results) as it is.
  void resetClock() {
    if (isClosed || (state.status != RoundStatus.playing && state.status != RoundStatus.finished)) {
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
    _lapBase = 0;
    _usedItems.clear();
    emit(state.copyWith(results: [], goals: state.goals.take(1).toList(), items: [], status: RoundStatus.ready));
  }

  @override
  Future<void> close() {
    _engine.removeListener(_capture);
    _engine.dispose();
    return super.close();
  }
}
