# Shopwatch – code review fix notes (Oct 12, 2026)

Review of `mj-homework/swatch` at commit `6deb5c5` ("add copyright info").
Fix step by step, by hand, and review each change before committing.

`flutter analyze` and `flutter test` were **not** run during the review. Run them locally before and after the fixes.

**What's already strong:** elapsed time computed from an injected monotonic `TimeSource`, idempotent `start()`, `Ticker`-driven repaint, tests mapped 1:1 to test cases 1–5, tabular figures, `Semantics` labels, responsive layout.

Status: 🔧 = decided to fix · 🤔 = to think about / check

---

## Fix before submitting

### ✅ 1. 🤔 The assignment is hard to find
- `initialRoute` is `/shopwatch`, and the custom `onGenerateInitialRoutes` returns only that one route (`lib/app/app.dart:64–71`).
- Shopwatch replaces the back button with a timer icon, so the landing page is never shown.
- The Classic Stopwatch (what OTP grades) sits behind an unlabeled icon.
- Option: start on `/` (landing page).


### ✅ 2. 🔧 License headers → MIT
Keep the MIT `LICENSE`. Replace every `All rights reserved` file header with:

```dart
// Copyright (c) 2026 Juhász Mátyás
// SPDX-License-Identifier: MIT
```

- Update the Android Studio copyright profile text to the same two lines, so new files get it too.
- The About dialog already says MIT. Keep the name format the same everywhere (`LICENSE` and the About dialog use "Juhász Mátyás (gatsby82)").
- Update the expected text in `test/widget_test.dart` if the About text changes.

### ✅ 3. 🔧 The shared clock plays sound by itself
- `lib/core/widgets/analog_clock.dart` creates its own `AudioPlayer` for the tick loop.
- Consequences: the Classic Stopwatch ticks with no mute; the `SoundPlayer` interface is bypassed; widget tests create real audio players; the README's "everything nondeterministic is injected" isn't true.
- Fix: move ticking into `SoundPlayer` (`startTicking()` / `stopTicking()`), and make `AnalogClock` silent (drop `isRunning`/`muted` sound logic and the `audioplayers` import from `core/`).

### 4. 🤔 Dead and commented-out code
- ✅ ~80 commented lines in `shopwatch_page.dart`, including the whole `_GameOptions` class.
- ✅ `GamePage` and the `/shopwatch/game`, `/shopwatch/game/play` routes: nothing navigates there (only a test uses `GamePage`).
- Cubit: no-op `pause()` / `clear()`, unused `resetClock()`.
  - Latent bug: after `resetClock()`, `emptyCart()` calls `togglePause()` on an idle engine → round says "playing" but the clock is stopped.
- ✅ remove Firebase and leaderboard
- ✅ Option: remove, or move to a branch.

### ✅ 5. 🔧 Use `package:swatch/...` imports everywhere
Also fixes the wrong depth in `lib/features/shopwatch/domain/shopwatch_game_cubit.dart:7–8` (`../../../../core/...` should be `../../../`).

Steps:
1. Add the lint to `analysis_options.yaml`:
   ```yaml
   linter:
     rules:
       - always_use_package_imports
   ```
2. Preview, then apply the automatic fix:
   ```bash
   dart fix --dry-run --code=always_use_package_imports
   dart fix --apply --code=always_use_package_imports
   ```
3. If `dart fix` misses some, `flutter analyze` lists them; in Android Studio, Alt+Enter on each offers "Convert to package: import".
4. Run `dart format .`, `flutter analyze`, `flutter test`.
5. Commit separately: `refactor: use package imports`.

The lint keeps new relative imports out from now on.

---

## Should fix (interviewers will ask)

### 6. 🔧 State management is half-adopted
`flutter_bloc` is a dependency, but `ShopwatchPage` doesn't use `BlocProvider` / `BlocBuilder`. Instead it:
- subscribes to `cubit.stream` by hand;
- calls the private `_emptyCart()` through a `GlobalKey` (`shopwatch_page.dart:162`);
- changes state from inside `build` with `addPostFrameCallback` (`shopwatch_page.dart:467`).

Fix: provide the cubit with `BlocProvider`, rebuild with `BlocBuilder` / `BlocListener`, call actions via `context.read<ShopwatchGameCubit>()`. Or be ready to explain the choice.

### ✅ 7. 🔧 Buttons rebuild every frame
- A `ValueListenableBuilder` on `elapsed` wraps `ShoppingControls` (`shopwatch_page.dart:575`).
- Contradicts the README's "only the time repaints".
- Fix: rebuild the buttons on cubit state changes only.

### ✅ 8. 🤔 Reset also clears the laps
- `stopwatch_controller.dart:84`. Valid choice, but the spec has a separate Clear button.
- Document the decision in the README.

### ✅ 9. 🔧 Uneven formatting
- Dense files: `shopwatch_dependencies.dart`, `pos_terminal_sheet.dart` (lines over 150 chars).
- `shopwatch_strings.dart` starts with a BOM.
- Fix: `dart format .` (remove the BOM by hand if needed).

### ✅ 10. 🔧 Rename leftovers (Stopwatch → Shopwatch)
- `_ShopwatchSection` in the *classic* `stopwatch_page.dart` → e.g. `_StopwatchSection`.
- `test/core/stopwatch/shopwatch_controller_test.dart` tests `StopwatchController` → rename to `stopwatch_controller_test.dart`.
- "shopwatch time" in doc comments of `lap.dart` and `analog_clock.dart`.
- `ShopwatchStrings.clear` says "Empty cart", but `receipt_list.dart:140` hard-codes "Put it all back". Unused strings: `approved`, `finePrint`.

### ✅ 11. 🤔 Hard-coded text styles
- `fontSize: 22` and `18` in `pos_terminal_sheet.dart`, `16` on the clock's digital display in `shopwatch_page.dart`.
- They bypass the 0.9 theme scaling. Base them on `Theme.of(context).textTheme`.

### 12. Double-tapping Pay resets without confirmation
- Hidden destructive gesture; also delays single taps by ~300 ms.
- The README roadmap's long-press idea is the better fix.

---

## Repo hygiene (public repo) 🔧

- [ ] `android/.kotlin/errors/*.log` is committed → add `.kotlin/` to `.gitignore`, then `git rm -r --cached android/.kotlin`.
- [ ] `applicationId` / `namespace` is `com.example.swatch` (`android/app/build.gradle.kts`) → use your own, e.g. `hu.juhaszmatyas.swatch` (also move `MainActivity.kt` to the matching package folder).
- [ ] `skills/` folder: `shopwatch_concept.md` is outdated (pause disabled, total diff, old labels) and contains the line about parodying the interviewer's brand, while the app uses OTP's exact colours → remove `skills/` from the public repo, or update it.
- [ ] First commit "init - Claude generated code": nothing to change, but be ready to say which parts you wrote or reworked yourself.

---

## Before submitting
- [ ] `dart format .`
- [ ] `flutter analyze` – no issues
- [ ] `flutter test` – all green
- [ ] One commit per fix, with clear messages
