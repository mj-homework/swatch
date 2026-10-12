/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'lap.dart';
import 'time_source.dart';

enum StopwatchStatus { idle, running, paused }

/// Pure business logic of the stopwatch, independent of any widget.
///
/// Elapsed time is not accumulated tick by tick (which would drift), it is
/// computed on demand from a monotonic [TimeSource]:
///
///     elapsed = accumulated + (now - runStartedAt)   while running
///     elapsed = accumulated                          otherwise
///
/// Listeners are notified on state changes only (start, pause, lap, ...),
/// not on every tick. The UI decides how often it wants to repaint.
class StopwatchController extends ChangeNotifier {
  StopwatchController({TimeSource? timeSource})
      : _timeSource = timeSource ?? MonotonicTimeSource();

  final TimeSource _timeSource;

  StopwatchStatus _status = StopwatchStatus.idle;
  Duration _accumulated = Duration.zero;
  Duration _runStartedAt = Duration.zero;
  Duration _lastLapSplit = Duration.zero;
  final List<Lap> _laps = [];

  StopwatchStatus get status => _status;
  bool get isIdle => _status == StopwatchStatus.idle;
  bool get isRunning => _status == StopwatchStatus.running;
  bool get isPaused => _status == StopwatchStatus.paused;

  /// Current elapsed time.
  Duration get elapsed => isRunning
      ? _accumulated + (_timeSource.now() - _runStartedAt)
      : _accumulated;

  /// Recorded laps in chronological order (oldest first).
  UnmodifiableListView<Lap> get laps => UnmodifiableListView(_laps);

  /// Starts counting. When paused, this resumes from the paused value.
  ///
  /// Calling it while already running is a no-op: it neither restarts the
  /// measurement nor notifies listeners.
  void start() {
    if (isRunning) return;
    _runStartedAt = _timeSource.now();
    _status = StopwatchStatus.running;
    notifyListeners();
  }

  /// Freezes the elapsed time. No-op unless running.
  void pause() {
    if (!isRunning) return;
    _accumulated = elapsed;
    _status = StopwatchStatus.paused;
    notifyListeners();
  }

  /// Continues from where it was paused. No-op unless paused.
  void resume() {
    if (!isPaused) return;
    start();
  }

  /// Behavior of the Pause button: pauses when running, resumes when
  /// paused, does nothing when idle.
  void togglePause() {
    if (isRunning) {
      pause();
    } else if (isPaused) {
      resume();
    }
  }

  /// Stops the stopwatch, sets it back to zero and clears the laps.
  void reset() {
    if (isIdle && _accumulated == Duration.zero && _laps.isEmpty) return;
    _status = StopwatchStatus.idle;
    _accumulated = Duration.zero;
    _lastLapSplit = Duration.zero;
    _laps.clear();
    notifyListeners();
  }

  /// Records a lap. Only possible while running; returns `null` otherwise.
  Lap? lap() {
    if (!isRunning) return null;
    final split = elapsed;
    final lap = Lap(
      number: _laps.length + 1,
      lapTime: split - _lastLapSplit,
      splitTime: split,
    );
    _lastLapSplit = split;
    _laps.add(lap);
    notifyListeners();
    return lap;
  }

  /// Empties the lap list without touching the running measurement.
  ///
  /// The next lap's lap time is still measured from the last recorded lap,
  /// so it always reflects the real duration of that lap.
  void clearLaps() {
    if (_laps.isEmpty) return;
    _laps.clear();
    notifyListeners();
  }
}
