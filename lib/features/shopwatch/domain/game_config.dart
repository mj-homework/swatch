import 'package:flutter/foundation.dart';

@immutable
class GameConfig {
  GameConfig({
    this.minGoal = const Duration(seconds: 5),
    this.maxGoal = const Duration(seconds: 15),
    this.minGap = const Duration(seconds: 3),
    this.maxGap = const Duration(seconds: 13),
    this.normalHideAfter = const Duration(seconds: 2),
    this.perfect = const Duration(milliseconds: 50),
    this.close = const Duration(milliseconds: 250),
    this.fair = const Duration(milliseconds: 750),
  }) {
    if (minGoal.inMilliseconds < 1 ||
        maxGoal < minGoal ||
        minGap.inMilliseconds < 1 ||
        maxGap < minGap ||
        normalHideAfter.isNegative ||
        perfect.isNegative ||
        close < perfect ||
        fair < close) {
      throw ArgumentError('Invalid game configuration');
    }
  }

  /// The first goal is in [minGoal, maxGoal] from the start; every next goal is
  /// the previous click time plus a gap in [minGap, maxGap].
  final Duration minGoal,
      maxGoal,
      minGap,
      maxGap,
      normalHideAfter,
      perfect,
      close,
      fair;
  Accuracy accuracy(Duration error) {
    final absolute = error.abs();
    if (absolute <= perfect) return Accuracy.perfect;
    if (absolute <= close) return Accuracy.close;
    if (absolute <= fair) return Accuracy.fair;
    return Accuracy.missed;
  }
}

enum Difficulty { easy, normal, hard }

enum Accuracy { perfect, close, fair, missed }
