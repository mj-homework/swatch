import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/core/widgets/analog_clock.dart';
import 'package:swatch/core/formatting/duration_format.dart';

void main() {
  group('formatElapsed', () {
    test('zero', () => expect(formatElapsed(Duration.zero), '00:00.000'));

    test('pads minutes, seconds and milliseconds', () {
      expect(
        formatElapsed(const Duration(minutes: 1, seconds: 2, milliseconds: 3)),
        '01:02.003',
      );
    });

    test('drops sub-millisecond precision', () {
      expect(
        formatElapsed(const Duration(milliseconds: 999, microseconds: 999)),
        '00:00.999',
      );
    });

    test('minutes keep counting past an hour', () {
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 15, seconds: 30)),
        '75:30.000',
      );
    });

    test('negative values are clamped to zero', () {
      expect(formatElapsed(const Duration(seconds: -1)), '00:00.000');
    });
  });

  group('handAngles', () {
    const quarter = math.pi / 2;

    test('all hands at 12 o\'clock at zero', () {
      final a = handAngles(Duration.zero);
      expect(a.second, 0);
      expect(a.minute, 0);
      expect(a.hour, 0);
    });

    test('second hand at 3 o\'clock after 15 seconds', () {
      expect(handAngles(const Duration(seconds: 15)).second, closeTo(quarter, 1e-9));
    });

    test('second hand moves smoothly between whole seconds', () {
      final a = handAngles(const Duration(milliseconds: 500)).second;
      expect(a, closeTo(math.pi / 60, 1e-9));
    });

    test('minute hand at 3 o\'clock after 15 minutes', () {
      expect(handAngles(const Duration(minutes: 15)).minute, closeTo(quarter, 1e-9));
    });

    test('hour hand at 3 o\'clock after 3 hours, wraps after 12', () {
      expect(handAngles(const Duration(hours: 3)).hour, closeTo(quarter, 1e-9));
      expect(handAngles(const Duration(hours: 15)).hour, closeTo(quarter, 1e-9));
    });
  });
}
