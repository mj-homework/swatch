# Stopwatch – OTP Bank Flutter homework

A stopwatch app with start / pause (resume) / reset, laps and an analog clock.
No third-party packages – only the Flutter SDK.

| Task | Status |
|---|---|
| Task 1 – start, pause/resume, reset, `MM:SS.mmm` display, responsive UI | ✅ |
| Task 1 – test cases 1–5 | ✅ |
| Task 2 – laps (lap + clear) | ✅ with tests |
| Nice-to-have – analog clock with smooth hour/minute/second hands | ✅ with tests |

## Running

Requires Flutter ≥ 3.27 (Dart ≥ 3.6).

```bash
# The repository contains only the Dart sources. Generate the platform
# folders once (existing files are not overwritten):
flutter create --project-name otp_stopwatch .

flutter pub get
flutter run          # any device: Android, iOS, web, desktop
flutter test         # unit + widget tests
flutter analyze
```

## Architecture

```
lib/
  main.dart
  src/
    app.dart                         MaterialApp, light/dark theme
    stopwatch/
      time_source.dart               clock abstraction (+ monotonic implementation)
      stopwatch_controller.dart      all business logic (ChangeNotifier)
      lap.dart                       immutable lap value object
    util/duration_format.dart        MM:SS.mmm formatting
    ui/
      stopwatch_page.dart            screen, Ticker, responsive layout
      stopwatch_keys.dart            keys used by widget tests
      widgets/
        elapsed_time_display.dart
        control_buttons.dart
        lap_panel.dart
        analog_clock.dart            CustomPainter
test/
  stopwatch_controller_test.dart     test cases 1, 2, 3, 5 + laps
  widget_test.dart                   test case 4 (+ laps, edge cases, narrow layout)
  duration_format_test.dart          formatting + clock hand angles
  helpers/fake_time_source.dart
```

### Key decisions

**Time is computed, not counted.** The controller stores the time accumulated
before the last start plus the timestamp of that start, and computes
`elapsed = accumulated + (now − startedAt)` on demand. Incrementing a counter in
a `Timer.periodic` callback would drift (timers are not exact and are throttled
in the background); this approach is exact regardless of frame rate or app
lifecycle.

**Injectable `TimeSource`.** The controller never reads the clock directly. In
production it uses a monotonic `Stopwatch` (not affected by system clock
changes); tests inject `FakeTimeSource` and advance time manually. Tests are
therefore deterministic and fast – no `sleep`, no flakiness. (One unit test
still uses the real clock to verify the production implementation.)

**Logic separated from UI.** `StopwatchController` is a plain `ChangeNotifier`
with no widget dependency, so it is unit-tested in isolation. It notifies only
on state changes (start, pause, lap…), not on every tick. For this scope
`ChangeNotifier` + `ListenableBuilder` is enough; the controller would map 1:1
to a Cubit/Riverpod notifier in a larger app.

**Efficient repainting.** While running, a `Ticker` (vsync-synchronised, paused
automatically when the app is not visible) pushes the elapsed time into a
`ValueNotifier`. Only the digital readout and the clock listen to it; the clock's
`CustomPainter` uses it as its `repaint` listenable, so each frame is a repaint
of one canvas inside a `RepaintBoundary` rather than a widget rebuild.

**Explicit state machine.** `idle → running ⇄ paused → (reset) idle`. Every
action is a no-op in states where it makes no sense (e.g. start while running,
lap while paused) and does not notify listeners. Buttons are disabled in those
states so the UI always reflects what is possible.

### Behaviour details

- **Pause** toggles between *Pause* and *Resume*. *Start* while paused also resumes.
- **Reset** sets the time to zero, stops the stopwatch and clears the laps.
- **Lap** is available only while running. Each lap shows its own duration and
  the total time; the newest lap is on top. With three or more laps the fastest
  and slowest are highlighted.
- **Clear** empties the lap list without stopping the stopwatch. The next lap
  is still measured from the last recorded lap, so its duration stays correct.
- Minutes are not wrapped at an hour (`75:30.000`).
- **Analog clock:** second hand = 1 turn/minute, minute hand = 1 turn/hour,
  hour hand = 1 turn/12 hours, plus a ring showing progress within the current
  minute. Angles are computed from the elapsed time with sub-millisecond
  precision every frame, so the hands sweep smoothly.
- **Responsive:** side-by-side layout (stopwatch | laps) at ≥ 720 px width,
  stacked layout on phones; the clock scales to the available space. Light and
  dark theme follow the system setting. Tabular figures keep the digits from
  jittering.

## Tests

| Requirement | Test |
|---|---|
| 1. Start starts the stopwatch, time increases | `stopwatch_controller_test.dart` › *Test case 1* |
| 2. Pause stops the time; pressing again resumes | › *Test case 2* |
| 3. Reset sets zero and stops the time | › *Test case 3* |
| 4. Widget test simulating taps | `widget_test.dart` |
| 5. Edge cases (repeated start, no-ops when idle, …) | › *Test case 5* + `widget_test.dart` |
| Laps (optional) | › *Task 2 – laps* + `widget_test.dart` |
| Clock hands (optional) | `duration_format_test.dart` › *handAngles* |
