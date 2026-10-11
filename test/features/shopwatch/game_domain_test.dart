import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_game_cubit.dart';
import 'package:swatch/features/shopwatch/domain/shop_item.dart';
import 'package:swatch/features/shopwatch/data/leaderboard_repository.dart';
import '../../core/stopwatch/helpers/fake_time_source.dart';

void main() {
  ShopwatchGameCubit game(FakeTimeSource time, {int count = 3}) =>
      ShopwatchGameCubit(
          config: GameConfig(
              minGoal: const Duration(seconds: 5),
              maxGoal: const Duration(seconds: 5),
              minGap: const Duration(seconds: 3),
              maxGap: const Duration(seconds: 3)),
          difficulty: Difficulty.normal,
          itemCount: count,
          nickname: 'Player',
          roundId: 'test',
          random: Random(7),
          timeSource: time);
  test('seeded generated items, inclusive goals, and immutable lists',
      () async {
    final config = GameConfig();
    ShopwatchGameCubit create() => ShopwatchGameCubit(
        config: config,
        difficulty: Difficulty.easy,
        itemCount: 8,
        nickname: 'Player',
        roundId: 'id',
        random: Random(123));
    final first = create(), second = create();
    expect(first.state.items, isEmpty);
    first.start();
    second.start();
    expect(first.state.items, second.state.items);
    expect(itemProperties, contains(first.state.items.single.property));
    expect(itemNames, contains(first.state.items.single.name));
    expect(first.state.items.single.pieces,
        inInclusiveRange(minPieces, maxPieces));
    expect(first.state.goals, second.state.goals);
    expect(
        first.state.goals.single >= config.minGoal &&
            first.state.goals.single <= config.maxGoal,
        isTrue);
    for (var i = 0; i < 8; i++) {
      first.addToCart();
    }
    expect(first.state.items.toSet().length, 8);
    expect(() => first.state.items.clear(), throwsUnsupportedError);
    await first.close();
    await second.close();
  });
  test('one continuous clock: each goal is the previous click plus the gap',
      () async {
    final time = FakeTimeSource();
    final cubit = game(time);
    cubit.addToCart();
    expect(cubit.state.results, isEmpty);
    cubit.start();
    cubit.start();
    expect(cubit.state.currentItem!.goal, const Duration(seconds: 5));
    time.advance(const Duration(milliseconds: 5050));
    cubit.addToCart();
    expect(cubit.state.results.single.difference.inMilliseconds, 50);
    expect(cubit.state.currentItem!.goal, const Duration(milliseconds: 8050));
    cubit.pause();
    cubit.clear();
    cubit.reset();
    expect(cubit.state.status, RoundStatus.playing);
    time.advance(const Duration(milliseconds: 2750));
    cubit.addToCart();
    expect(cubit.state.currentItem!.goal, const Duration(milliseconds: 10800));
    time.advance(const Duration(milliseconds: 3001));
    cubit.addToCart();
    expect(cubit.state.results.map((r) => r.difference.inMilliseconds),
        [50, -250, 1]);
    expect(cubit.state.totalError.inMilliseconds, 301);
    expect(cubit.state.averageError.inMicroseconds, 100333);
    expect(cubit.state.totalTime, const Duration(milliseconds: 10801));
    expect(cubit.state.status, RoundStatus.finished);
    expect(cubit.isRunning, isFalse);
    cubit.addToCart();
    expect(cubit.state.results.length, 3);
    cubit.reset();
    expect(cubit.state.status, RoundStatus.ready);
    expect(cubit.elapsed, Duration.zero);
    expect(cubit.state.goals, [const Duration(seconds: 5)]);
    cubit.start();
    time.advance(const Duration(seconds: 1));
    cubit.addToCart();
    expect(cubit.state.results, hasLength(1));
    await cubit.close();
    cubit.start();
    cubit.addToCart();
  });
  test('empty cart restarts at item 1 without resetting the clock', () async {
    final time = FakeTimeSource();
    final cubit = game(time);
    cubit.start();
    time.advance(const Duration(seconds: 5));
    cubit.addToCart();
    time.advance(const Duration(seconds: 4));
    cubit.emptyCart();
    expect(cubit.state.results, isEmpty);
    expect(cubit.state.status, RoundStatus.playing);
    expect(cubit.elapsed, const Duration(seconds: 9));
    expect(cubit.state.goals, [const Duration(seconds: 12)]);
    time.advance(const Duration(seconds: 4));
    cubit.addToCart();
    expect(cubit.state.results.single.actual, const Duration(seconds: 13));
    expect(cubit.state.results.single.difference, const Duration(seconds: 1));
    await cubit.close();
  });
  test('endless round never finishes and keeps producing items', () async {
    final time = FakeTimeSource();
    final cubit = ShopwatchGameCubit(
        config: GameConfig(),
        difficulty: Difficulty.easy,
        itemCount: null,
        nickname: 'Player',
        roundId: 'r',
        random: Random(1),
        timeSource: time);
    cubit.start();
    for (var i = 0; i < 8; i++) {
      expect(cubit.state.currentItem, isNotNull);
      time.advance(const Duration(seconds: 6));
      cubit.addToCart();
    }
    expect(cubit.state.results.length, 8);
    expect(cubit.state.status, RoundStatus.playing);
    expect(cubit.state.isEndless, isTrue);
    await cubit.close();
  });
  test('gaps stay within the configured range', () async {
    final time = FakeTimeSource();
    final config = GameConfig();
    final cubit = ShopwatchGameCubit(
        config: config,
        difficulty: Difficulty.easy,
        itemCount: 5,
        nickname: 'Player',
        roundId: 'r',
        random: Random(3),
        timeSource: time);
    cubit.start();
    expect(
        cubit.state.goals.single >= config.minGoal &&
            cubit.state.goals.single <= config.maxGoal,
        isTrue);
    for (var i = 0; i < 4; i++) {
      time.advance(const Duration(seconds: 4));
      cubit.addToCart();
      final gap = cubit.state.goals.last - cubit.state.results.last.actual;
      expect(gap >= config.minGap && gap <= config.maxGap, isTrue);
    }
    await cubit.close();
  });
  test('accuracy boundary buckets and invalid configurations', () {
    final config = GameConfig();
    for (final pair in [
      (50, Accuracy.perfect),
      (51, Accuracy.close),
      (250, Accuracy.close),
      (251, Accuracy.fair),
      (750, Accuracy.fair),
      (751, Accuracy.missed)
    ]) {
      expect(config.accuracy(Duration(milliseconds: pair.$1)), pair.$2);
      expect(config.accuracy(Duration(milliseconds: -pair.$1)), pair.$2);
    }
    expect(() => GameConfig(minGoal: Duration.zero), throwsArgumentError);
    expect(() => GameConfig(perfect: const Duration(seconds: 1)),
        throwsArgumentError);
    expect(
        () => ShopwatchGameCubit(
            config: GameConfig(),
            difficulty: Difficulty.easy,
            itemCount: shopItemCombinationCount + 1,
            nickname: 'Player',
            roundId: 'id',
            random: Random(1)),
        throwsArgumentError);
  });
  test('normalization, bad words, invalid keys and explicit offline behavior',
      () async {
    const policy = NicknamePolicy();
    expect(policy.normalize(' ÁRVÍZTŰRŐ '), 'arvizturo');
    expect(policy.normalize('Jo\u0301zsi'), 'jozsi');
    for (final name in [
      'ab',
      'a/b',
      'admin1',
      'a b',
      'abcdefghijklmnopq',
      '💰💰💰'
    ]) {
      expect(policy.isValid(name), isFalse);
    }
    expect(policy.isValid('Józsi_12'), isTrue);
    const repository = OfflineLeaderboardRepository();
    expect(await repository.reserve('Jozsi'), NicknameStatus.offline);
    expect(await repository.top(1, Difficulty.easy), isNull);
  });
}
