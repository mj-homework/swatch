import 'package:flutter/widgets.dart';

/// Stable keys used by widget tests (and handy for integration tests).
abstract final class StopwatchKeys {
  static const elapsedText = Key('elapsedText');
  static const startButton = Key('startButton');
  static const pauseButton = Key('pauseButton');
  static const resetButton = Key('resetButton');
  static const lapButton = Key('lapButton');
  static const clearLapsButton = Key('clearLapsButton');
  static const lapList = Key('lapList');
  static const analogClock = Key('analogClock');
}
