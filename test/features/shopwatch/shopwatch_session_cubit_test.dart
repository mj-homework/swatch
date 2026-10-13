/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_session_cubit.dart';
import '../../core/swatch/helpers/fake_time_source.dart';

void main() {
  late FakeTimeSource time;
  late ShopwatchSessionCubit session;
  var ids = 0;

  setUp(() {
    time = FakeTimeSource();
    session = ShopwatchSessionCubit(
      config: GameConfig(
        minGoal: const Duration(seconds: 5),
        maxGoal: const Duration(seconds: 5),
        minGap: const Duration(seconds: 3),
        maxGap: const Duration(seconds: 3),
      ),
      random: Random(7),
      newRoundId: () => 'round-${ids++}',
      timeSource: time,
    );
  });

  tearDown(() => session.close());

  test('starts with no round and a zero clock', () {
    expect(session.state.inGame, isFalse);
    expect(session.elapsed, Duration.zero);
  });

  test('start, pause and add to cart update the state synchronously', () {
    session.start(itemCount: 2, difficulty: Difficulty.easy);
    expect(session.state.round?.status, RoundStatus.playing);
    expect(session.state.isRunning, isTrue);

    time.advance(const Duration(seconds: 5));
    session.addToCart();
    expect(session.state.round!.results, hasLength(1));
    expect(session.state.round!.results.single.accuracy, Accuracy.perfect);

    session.togglePause();
    expect(session.state.isPaused, isTrue);
    expect(session.state.isRunning, isFalse);
  });

  test('a second start is ignored while a round is in progress', () {
    session.start(itemCount: 2, difficulty: Difficulty.easy);
    final round = session.state.round;
    session.start(itemCount: 5, difficulty: Difficulty.easy);
    expect(session.state.round?.id, round?.id);
  });

  test('empty cart drops results but keeps the round and its clock', () {
    session.start(itemCount: 3, difficulty: Difficulty.easy);
    time.advance(const Duration(seconds: 5));
    session.addToCart();
    final id = session.state.round!.id;

    session.emptyCart();
    expect(session.state.round!.id, id);
    expect(session.state.round!.results, isEmpty);
    expect(session.elapsed, const Duration(seconds: 5));
  });

  test('end round resets to no round and a zero clock; a new round gets a new id', () async {
    session.start(itemCount: 2, difficulty: Difficulty.easy);
    final firstId = session.state.round!.id;
    time.advance(const Duration(seconds: 2));

    await session.endRound();
    expect(session.state.inGame, isFalse);
    expect(session.state.isRunning, isFalse);
    expect(session.elapsed, Duration.zero);

    session.start(itemCount: 2, difficulty: Difficulty.easy);
    expect(session.state.round!.id, isNot(firstId));
  });

  test('commands without a round do nothing', () async {
    session
      ..togglePause()
      ..addToCart()
      ..emptyCart();
    await session.endRound();
    expect(session.state.inGame, isFalse);
  });
}
