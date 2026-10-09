import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/domain/game_round.dart';
import 'package:swatch/features/shopwatch/domain/shopwatch_game_cubit.dart';
import 'package:swatch/features/shopwatch/data/leaderboard_repository.dart';
import '../../core/stopwatch/helpers/fake_time_source.dart';

void main() {
  ShopwatchGameCubit game(FakeTimeSource time, {int count = 3}) => ShopwatchGameCubit(
    config: GameConfig(items: ['a', 'b', 'c'], minGoal: const Duration(seconds: 5), maxGoal: const Duration(seconds: 5)),
    difficulty: Difficulty.normal, itemCount: count, nickname: 'Player', roundId: 'test', random: Random(7), timeSource: time);
  test('seeded selection, inclusive millisecond goals, immutable lists', () async {
    final config = GameConfig();
    ShopwatchGameCubit create() => ShopwatchGameCubit(config: config, difficulty: Difficulty.easy,
      itemCount: config.items.length, nickname: 'Player', roundId: 'id', random: Random(123));
    final first = create(), second = create();
    expect(first.state.items.map((i) => i.name), second.state.items.map((i) => i.name));
    expect(first.state.items.map((i) => i.goal), second.state.items.map((i) => i.goal));
    expect(first.state.items.map((i) => i.name).toSet().length, config.items.length);
    expect(first.state.items.every((i) => i.goal >= config.minGoal && i.goal <= config.maxGoal), isTrue);
    expect(() => first.state.items.clear(), throwsUnsupportedError);
    expect(() => config.items.clear(), throwsUnsupportedError);
    await first.close(); await second.close();
  });
  test('exact per-item signed errors, no reentrant duplicates, finish/reset/dispose', () async {
    final time = FakeTimeSource(); final cubit = game(time);
    cubit.addToCart(); expect(cubit.state.results, isEmpty);
    cubit.start(); cubit.start();
    time.advance(const Duration(milliseconds: 5050)); cubit.addToCart();
    expect(cubit.state.results.single.difference.inMilliseconds, 50);
    cubit.pause(); cubit.clear(); cubit.reset();
    expect(cubit.state.status, RoundStatus.playing);
    time.advance(const Duration(milliseconds: 4750)); cubit.addToCart();
    time.advance(const Duration(milliseconds: 6001)); cubit.addToCart();
    expect(cubit.state.results.map((r) => r.difference.inMilliseconds), [50, -250, 1001]);
    expect(cubit.state.totalError.inMilliseconds, 1301);
    expect(cubit.state.status, RoundStatus.finished); expect(cubit.isRunning, isFalse);
    cubit.addToCart(); expect(cubit.state.results.length, 3);
    cubit.reset(); expect(cubit.state.status, RoundStatus.ready); expect(cubit.elapsed, Duration.zero);
    await cubit.close(); cubit.start(); cubit.addToCart();
  });
  test('accuracy boundary buckets and invalid configurations', () {
    final config = GameConfig();
    for (final pair in [(50, Accuracy.perfect), (51, Accuracy.close), (250, Accuracy.close), (251, Accuracy.fair), (750, Accuracy.fair), (751, Accuracy.missed)]) {
      expect(config.accuracy(Duration(milliseconds: pair.$1)), pair.$2);
      expect(config.accuracy(Duration(milliseconds: -pair.$1)), pair.$2);
    }
    expect(() => GameConfig(items: []), throwsArgumentError);
    expect(() => GameConfig(items: ['a', 'a']), throwsArgumentError);
    expect(() => GameConfig(minGoal: Duration.zero), throwsArgumentError);
    expect(() => GameConfig(perfect: const Duration(seconds: 1)), throwsArgumentError);
    expect(() => game(FakeTimeSource(), count: 4), throwsArgumentError);
  });
  test('normalization, bad words, invalid keys and explicit offline behavior', () async {
    const policy = NicknamePolicy();
    expect(policy.normalize(' ÁRVÍZTŰRŐ '), 'arvizturo');
    expect(policy.normalize('Jo\u0301zsi'), 'jozsi');
    for (final name in ['ab', 'a/b', 'admin1', 'a b', 'abcdefghijklmnopq', '💰💰💰']) { expect(policy.isValid(name), isFalse); }
    expect(policy.isValid('Józsi_12'), isTrue);
    const repository = OfflineLeaderboardRepository();
    expect(await repository.reserve('Jozsi'), NicknameStatus.offline);
    expect(await repository.top(1, Difficulty.easy), isNull);
  });
}
