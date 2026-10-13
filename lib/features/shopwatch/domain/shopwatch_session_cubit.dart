/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:swatch/core/swatch/time_source.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_game_cubit.dart';

/// What the Shopwatch screen shows: the current round (null between rounds)
/// and whether its clock is running or on a coffee break.
@immutable
class ShopwatchSession {
  const ShopwatchSession({this.round, this.isRunning = false, this.isPaused = false});

  final GameRound? round;
  final bool isRunning;
  final bool isPaused;

  bool get inGame => round != null;

  @override
  bool operator ==(Object other) =>
      other is ShopwatchSession &&
      identical(other.round, round) &&
      other.isRunning == isRunning &&
      other.isPaused == isPaused;

  @override
  int get hashCode => Object.hash(identityHashCode(round), isRunning, isPaused);
}

/// Screen-level state shared by the controls, the receipt and the app bar.
///
/// Creates a [ShopwatchGameCubit] per round and closes it when the round
/// ends. Every command emits synchronously, so widgets see the new state in
/// the same frame.
class ShopwatchSessionCubit extends Cubit<ShopwatchSession> {
  ShopwatchSessionCubit({
    required GameConfig config,
    required Random random,
    required String Function() newRoundId,
    TimeSource? timeSource,
  })  : _config = config,
        _random = random,
        _newRoundId = newRoundId,
        _timeSource = timeSource,
        super(const ShopwatchSession());

  final GameConfig _config;
  final Random _random;
  final String Function() _newRoundId;
  final TimeSource? _timeSource;
  ShopwatchGameCubit? _game;

  /// Elapsed time on the round's clock; zero between rounds.
  Duration get elapsed => _game?.elapsed ?? Duration.zero;

  /// Starts a new round; [itemCount] null means endless. Ignored while a
  /// round is in progress.
  void start({required int? itemCount, required Difficulty difficulty}) {
    if (isClosed || _game != null) return;

    _game = ShopwatchGameCubit(
      config: _config,
      difficulty: difficulty,
      itemCount: itemCount,
      roundId: _newRoundId(),
      random: _random,
      timeSource: _timeSource,
    )..start();
    _sync();
  }

  void togglePause() => _run((game) => game.togglePause());

  void addToCart() => _run((game) => game.addToCart());

  void emptyCart() => _run((game) => game.emptyCart());

  /// Ends the round and resets the screen; the clock goes back to zero.
  Future<void> endRound() async {
    final game = _game;

    if (game == null) return;

    _game = null;
    _sync();

    await game.close();
  }

  void _run(void Function(ShopwatchGameCubit game) command) {
    final game = _game;

    if (game == null) return;

    command(game);

    _sync();
  }

  void _sync() {
    if (isClosed) return;

    final game = _game;

    emit(game == null
        ? const ShopwatchSession()
        : ShopwatchSession(round: game.state, isRunning: game.isRunning, isPaused: game.isPaused));
  }

  @override
  Future<void> close() async {
    final game = _game;
    _game = null;
    await game?.close();
    return super.close();
  }
}
