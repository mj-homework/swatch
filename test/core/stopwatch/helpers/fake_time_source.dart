/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'package:swatch/core/stopwatch/time_source.dart';

/// Manually controlled clock for deterministic tests.
class FakeTimeSource implements TimeSource {
  Duration _now = Duration.zero;

  @override
  Duration now() => _now;

  void advance(Duration by) => _now += by;
}
