/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:flutter/foundation.dart';

/// A recorded lap.
@immutable
class Lap {
  const Lap({
    required this.number,
    required this.lapTime,
    required this.splitTime,
  });

  /// 1-based position of the lap in the current lap list.
  final int number;

  /// Time elapsed since the previous lap (or since the start for the first).
  final Duration lapTime;

  /// Total elapsed shopwatch time at the moment the lap was recorded.
  final Duration splitTime;

  @override
  bool operator ==(Object other) =>
      other is Lap && other.number == number && other.lapTime == lapTime && other.splitTime == splitTime;

  @override
  int get hashCode => Object.hash(number, lapTime, splitTime);

  @override
  String toString() => 'Lap(#$number, lap: $lapTime, split: $splitTime)';
}
