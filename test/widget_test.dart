import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otp_stopwatch/src/app.dart';
import 'package:otp_stopwatch/src/ui/stopwatch_keys.dart';
import 'package:otp_stopwatch/src/ui/widgets/analog_clock.dart';

import 'helpers/fake_time_source.dart';

/// Test case 4 – widget tests simulating user interaction.
void main() {
  late FakeTimeSource time;

  setUp(() => time = FakeTimeSource());

  Future<void> pumpApp(WidgetTester tester) =>
      tester.pumpWidget(StopwatchApp(timeSource: time));

  /// Advances the fake clock and lets the ticker render one frame.
  Future<void> elapse(WidgetTester tester, Duration d) async {
    time.advance(d);
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  String displayedTime(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(StopwatchKeys.elapsedText)).data!;

  bool isEnabled(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

  testWidgets('initial UI shows zero, clock and correct button states',
      (tester) async {
    await pumpApp(tester);

    expect(displayedTime(tester), '00:00.000');
    expect(find.byType(AnalogClock), findsOneWidget);
    expect(find.text('No laps yet'), findsOneWidget);

    expect(isEnabled(tester, StopwatchKeys.startButton), isTrue);
    expect(isEnabled(tester, StopwatchKeys.pauseButton), isFalse);
    expect(isEnabled(tester, StopwatchKeys.lapButton), isFalse);
    expect(isEnabled(tester, StopwatchKeys.resetButton), isFalse);
    expect(isEnabled(tester, StopwatchKeys.clearLapsButton), isFalse);
  });

  testWidgets('start → pause → resume → reset updates the display',
      (tester) async {
    await pumpApp(tester);

    await tap(tester, StopwatchKeys.startButton);
    await elapse(tester, const Duration(seconds: 1, milliseconds: 250));
    expect(displayedTime(tester), '00:01.250');
    expect(isEnabled(tester, StopwatchKeys.startButton), isFalse);

    await tap(tester, StopwatchKeys.pauseButton);
    expect(find.text('Resume'), findsOneWidget);
    await elapse(tester, const Duration(seconds: 5));
    expect(displayedTime(tester), '00:01.250');

    await tap(tester, StopwatchKeys.pauseButton); // resume
    expect(find.text('Pause'), findsOneWidget);
    await elapse(tester, const Duration(milliseconds: 500));
    expect(displayedTime(tester), '00:01.750');

    await tap(tester, StopwatchKeys.resetButton);
    expect(displayedTime(tester), '00:00.000');
    await elapse(tester, const Duration(seconds: 3));
    expect(displayedTime(tester), '00:00.000');
    expect(isEnabled(tester, StopwatchKeys.startButton), isTrue);
    expect(isEnabled(tester, StopwatchKeys.resetButton), isFalse);
  });

  testWidgets('display keeps updating in real time while running',
      (tester) async {
    await pumpApp(tester);
    await tap(tester, StopwatchKeys.startButton);

    final seen = <String>[];
    for (var i = 0; i < 5; i++) {
      await elapse(tester, const Duration(milliseconds: 37));
      seen.add(displayedTime(tester));
    }
    expect(seen, [
      '00:00.037',
      '00:00.074',
      '00:00.111',
      '00:00.148',
      '00:00.185',
    ]);
  });

  testWidgets('tapping start repeatedly does not disturb the measurement',
      (tester) async {
    await pumpApp(tester);

    await tap(tester, StopwatchKeys.startButton);
    await elapse(tester, const Duration(seconds: 1));
    // Disabled while running – taps must have no effect.
    await tester.tap(find.byKey(StopwatchKeys.startButton), warnIfMissed: false);
    await tester.tap(find.byKey(StopwatchKeys.startButton), warnIfMissed: false);
    await elapse(tester, const Duration(seconds: 1));

    expect(displayedTime(tester), '00:02.000');
  });

  testWidgets('laps are recorded, listed newest first and cleared',
      (tester) async {
    await pumpApp(tester);
    final lapList = find.byKey(StopwatchKeys.lapList);

    await tap(tester, StopwatchKeys.startButton);
    await elapse(tester, const Duration(seconds: 2));
    await tap(tester, StopwatchKeys.lapButton);
    await elapse(tester, const Duration(seconds: 3));
    await tap(tester, StopwatchKeys.lapButton);

    expect(find.text('Laps (2)'), findsOneWidget);
    expect(find.descendant(of: lapList, matching: find.text('Lap 1')),
        findsOneWidget);
    expect(find.descendant(of: lapList, matching: find.text('Lap 2')),
        findsOneWidget);
    // Lap 2: lap time 3 s, total 5 s.
    expect(find.descendant(of: lapList, matching: find.text('00:03.000')),
        findsOneWidget);
    expect(find.descendant(of: lapList, matching: find.text('00:05.000')),
        findsOneWidget);
    // Newest on top.
    expect(
      tester.getTopLeft(find.text('Lap 2')).dy,
      lessThan(tester.getTopLeft(find.text('Lap 1')).dy),
    );

    await tap(tester, StopwatchKeys.clearLapsButton);
    expect(find.text('No laps yet'), findsOneWidget);
    expect(lapList, findsNothing);
    // Clearing laps does not stop the stopwatch.
    await elapse(tester, const Duration(seconds: 1));
    expect(displayedTime(tester), '00:06.000');
  });

  testWidgets('lap button is disabled while paused', (tester) async {
    await pumpApp(tester);
    await tap(tester, StopwatchKeys.startButton);
    await tap(tester, StopwatchKeys.pauseButton);
    expect(isEnabled(tester, StopwatchKeys.lapButton), isFalse);
  });

  testWidgets('narrow phone layout renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await tap(tester, StopwatchKeys.startButton);
    await elapse(tester, const Duration(seconds: 1));
    await tap(tester, StopwatchKeys.lapButton);

    expect(tester.takeException(), isNull);
    expect(find.text('Lap 1'), findsOneWidget);
  });
}
