import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/core/stopwatch/lap.dart';
import 'package:swatch/core/stopwatch/stopwatch_controller.dart';
import 'package:swatch/core/stopwatch/time_source.dart';

import 'helpers/fake_time_source.dart';

void main() {
  late FakeTimeSource time;
  late StopwatchController controller;
  late int notifications;

  setUp(() {
    time = FakeTimeSource();
    controller = StopwatchController(timeSource: time);
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('initial state is idle at zero with no laps', () {
    expect(controller.status, StopwatchStatus.idle);
    expect(controller.elapsed, Duration.zero);
    expect(controller.laps, isEmpty);
  });

  group('Test case 1 – start', () {
    test('starts counting up from zero and elapsed time increases', () {
      controller.start();
      expect(controller.isRunning, isTrue);
      expect(controller.elapsed, Duration.zero);

      time.advance(const Duration(milliseconds: 100));
      expect(controller.elapsed, const Duration(milliseconds: 100));

      time.advance(const Duration(seconds: 2, milliseconds: 250));
      expect(controller.elapsed, const Duration(seconds: 2, milliseconds: 350));
    });

    test('elapsed time increases with the real monotonic clock', () async {
      final real = StopwatchController(timeSource: MonotonicTimeSource());
      addTearDown(real.dispose);

      real.start();
      final first = real.elapsed;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final second = real.elapsed;

      expect(second, greaterThan(first));
      expect(second, greaterThanOrEqualTo(const Duration(milliseconds: 30)));
    });

    test('time passing before start is not counted', () {
      time.advance(const Duration(minutes: 5));
      controller.start();
      time.advance(const Duration(seconds: 1));
      expect(controller.elapsed, const Duration(seconds: 1));
    });
  });

  group('Test case 2 – pause', () {
    test('pausing freezes the elapsed time', () {
      controller.start();
      time.advance(const Duration(seconds: 3));
      controller.pause();

      expect(controller.isPaused, isTrue);
      expect(controller.elapsed, const Duration(seconds: 3));

      time.advance(const Duration(seconds: 10));
      expect(controller.elapsed, const Duration(seconds: 3));
    });

    test('pressing pause again resumes from where it left off', () {
      controller.start();
      time.advance(const Duration(seconds: 3));
      controller.togglePause(); // pause
      time.advance(const Duration(seconds: 10));
      controller.togglePause(); // resume

      expect(controller.isRunning, isTrue);
      time.advance(const Duration(milliseconds: 500));
      expect(controller.elapsed, const Duration(seconds: 3, milliseconds: 500));
    });

    test('multiple pause/resume cycles accumulate correctly', () {
      controller.start();
      for (var i = 0; i < 5; i++) {
        time.advance(const Duration(seconds: 1));
        controller.togglePause();
        time.advance(const Duration(hours: 1)); // must be ignored
        controller.togglePause();
      }
      expect(controller.elapsed, const Duration(seconds: 5));
    });
  });

  group('Test case 3 – reset', () {
    test('resets to zero and stops the elapsed time', () {
      controller.start();
      time.advance(const Duration(seconds: 7));
      controller.reset();

      expect(controller.isIdle, isTrue);
      expect(controller.elapsed, Duration.zero);

      time.advance(const Duration(seconds: 5));
      expect(controller.elapsed, Duration.zero);
    });

    test('reset while paused returns to zero', () {
      controller.start();
      time.advance(const Duration(seconds: 2));
      controller.pause();
      controller.reset();

      expect(controller.isIdle, isTrue);
      expect(controller.elapsed, Duration.zero);
    });

    test('can start again from zero after reset', () {
      controller.start();
      time.advance(const Duration(seconds: 9));
      controller.reset();
      controller.start();
      time.advance(const Duration(seconds: 1));
      expect(controller.elapsed, const Duration(seconds: 1));
    });

    test('reset also clears the laps', () {
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.lap();
      controller.reset();
      expect(controller.laps, isEmpty);
    });
  });

  group('Test case 5 – edge cases', () {
    test('pressing start multiple times does not restart or double count', () {
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.start();
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.start();

      expect(controller.isRunning, isTrue);
      expect(controller.elapsed, const Duration(seconds: 2));
      // Only the first start changed the state.
      expect(notifications, 1);
    });

    test('start while paused resumes instead of restarting', () {
      controller.start();
      time.advance(const Duration(seconds: 4));
      controller.pause();
      time.advance(const Duration(seconds: 4));
      controller.start();
      time.advance(const Duration(seconds: 1));
      expect(controller.elapsed, const Duration(seconds: 5));
    });

    test('pause, resume and lap are no-ops when idle', () {
      controller.pause();
      controller.resume();
      controller.togglePause();

      expect(controller.lap(), isNull);
      expect(controller.isIdle, isTrue);
      expect(controller.elapsed, Duration.zero);
      expect(notifications, 0);
    });

    test('pausing twice keeps the first paused value', () {
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.pause();
      time.advance(const Duration(seconds: 1));
      controller.pause();
      expect(controller.elapsed, const Duration(seconds: 1));
      expect(notifications, 2);
    });

    test('reset when already idle does not notify', () {
      controller.reset();
      expect(notifications, 0);
    });

    test('displays durations longer than an hour', () {
      controller.start();
      time.advance(const Duration(hours: 2, minutes: 3));
      expect(controller.elapsed.inMinutes, 123);
    });
  });

  group('Task 2 – laps', () {
    test('records lap time and split time', () {
      controller.start();
      time.advance(const Duration(seconds: 2));
      final first = controller.lap();
      time.advance(const Duration(seconds: 3));
      final second = controller.lap();

      expect(
        first,
        const Lap(
          number: 1,
          lapTime: Duration(seconds: 2),
          splitTime: Duration(seconds: 2),
        ),
      );
      expect(
        second,
        const Lap(
          number: 2,
          lapTime: Duration(seconds: 3),
          splitTime: Duration(seconds: 5),
        ),
      );
      expect(controller.laps, [first, second]);
    });

    test('paused time is not part of a lap', () {
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.pause();
      time.advance(const Duration(minutes: 1));
      controller.resume();
      time.advance(const Duration(seconds: 1));

      expect(controller.lap()!.lapTime, const Duration(seconds: 2));
    });

    test('cannot record a lap while paused', () {
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.pause();
      expect(controller.lap(), isNull);
      expect(controller.laps, isEmpty);
    });

    test('clearLaps empties the list but keeps the shopwatch running', () {
      controller.start();
      time.advance(const Duration(seconds: 1));
      controller.lap();
      time.advance(const Duration(seconds: 1));
      controller.lap();

      controller.clearLaps();

      expect(controller.laps, isEmpty);
      expect(controller.isRunning, isTrue);
      expect(controller.elapsed, const Duration(seconds: 2));

      time.advance(const Duration(seconds: 4));
      final next = controller.lap()!;
      expect(next.number, 1);
      expect(next.lapTime, const Duration(seconds: 4));
      expect(next.splitTime, const Duration(seconds: 6));
    });

    test('notifies listeners when laps change', () {
      controller.start(); // 1
      controller.lap(); // 2
      controller.clearLaps(); // 3
      controller.clearLaps(); // no-op
      expect(notifications, 3);
    });

    test('exposed lap list cannot be modified from outside', () {
      controller.start();
      controller.lap();
      expect(() => controller.laps.clear(), throwsUnsupportedError);
    });
  });
}
