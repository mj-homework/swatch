import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/stopwatch/stopwatch_controller.dart';
import '../../../../core/stopwatch/time_source.dart';
import 'game_config.dart';
import 'game_round.dart';

/// Owns its engine; external callers only receive read-only timing values.
class ShopwatchGameCubit extends Cubit<GameRound> {
  ShopwatchGameCubit({required GameConfig config, required Difficulty difficulty,
    required int itemCount, required String nickname, required String roundId,
    required Random random, TimeSource? timeSource, bool ownedNickname = false})
      : _engine = StopwatchController(timeSource: timeSource),
        super(_prepare(config, difficulty, itemCount, nickname, roundId, random, ownedNickname)) {
    _engine.addListener(_capture);
  }
  final StopwatchController _engine;
  bool _capturing = false;
  Duration get elapsed => _engine.elapsed;
  Duration get itemElapsed => elapsed - state.totalTime;
  bool get isRunning => _engine.isRunning;
  static GameRound _prepare(GameConfig config, Difficulty difficulty, int count,
      String nickname, String id, Random random, bool owned) {
    if (count < 1 || count > config.items.length) throw ArgumentError.value(count, 'itemCount');
    final names = config.items.toList()..shuffle(random);
    final low = config.minGoal.inMilliseconds;
    final range = config.maxGoal.inMilliseconds - low + 1;
    return GameRound(config: config, difficulty: difficulty, nickname: nickname, id: id,
      ownedNickname: owned, status: RoundStatus.ready,
      items: names.take(count).map((name) => GameItem(name, Duration(milliseconds: low + random.nextInt(range)))).toList());
  }
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
      for (final lap in _engine.laps.skip(results.length)) {
        if (results.length >= state.items.length) break;
        final item = state.items[results.length];
        results.add(ItemResult(item, lap.lapTime, state.config.accuracy(lap.lapTime - item.goal)));
      }
      if (results.length == state.results.length) return;
      final finished = results.length == state.items.length;
      // pause synchronously notifies: the guard prevents duplicate capture.
      if (finished) _engine.pause();
      emit(state.copyWith(results: results, status: finished ? RoundStatus.finished : RoundStatus.playing));
    } finally { _capturing = false; }
  }
  // These operations deliberately cannot change an active round.
  void pause() {}
  void clear() {}
  void reset() {
    if (isClosed || state.status == RoundStatus.playing) return;
    _engine.reset();
    emit(state.copyWith(results: [], status: RoundStatus.ready));
  }
  @override
  Future<void> close() {
    _engine.removeListener(_capture);
    _engine.dispose();
    return super.close();
  }
}
