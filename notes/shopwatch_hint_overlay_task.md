# Task: first-launch hint overlay ("coach marks") for Shopwatch

## Context

Flutter app `swatch` (package name `swatch`). The app opens on `ShopwatchPage`
(`lib/features/shopwatch/presentation/pages/shopwatch_page.dart`), a shopping-themed
stopwatch game. The Classic Stopwatch (the actual homework) is opened by an
unlabeled timer icon (`Icons.timer_outlined`) in the app bar's `leading` slot.
Reviewers may not notice it.

Goal: when the app starts, show a dimmed overlay with spotlight cut-outs, arrows and
short hint texts pointing at the important controls.

## Rules for you (the AI assistant)

- Work in **small steps**. After each step, stop and explain what you changed and why.
  I review every change myself before continuing.
- Change **only** what this task needs. Do not refactor, rename or reformat unrelated code.
- No new packages unless a step below says so. Do **not** use `showcaseview`,
  `tutorial_coach_mark` or similar; build it by hand.
- Imports: `package:swatch/...` only (the `always_use_package_imports` lint is on).
- Every new file starts with:
  ```dart
  // Copyright (c) 2026 Juhász Mátyás
  // SPDX-License-Identifier: MIT
  ```
- Text styles come from `Theme.of(context).textTheme`, never a hard-coded `fontSize`.
- Strings go into `lib/features/shopwatch/shopwatch_strings.dart`,
  keys into `ShopwatchKeys` in the same file.
- After each step the code must pass `dart format lib test tool`, `flutter analyze`
  and `flutter test`.

## Requirements

### Hints (in this order)

| # | Target | Text |
|---|---|---|
| 1 | Timer icon in the app bar (`leading`) | **Classic Stopwatch** – the by-the-spec solution: start, pause, reset, laps, analog clock. |
| 2 | **Shop!** button (`ShopwatchKeys.start`) | **Start a shopping game** – add each item to the cart at its goal time. |
| 3 | **Pay** button (`ShopwatchKeys.pay`) | **Pay** – tap to check out; double-tap to reset at once. |

### Behaviour

- Shown automatically when `ShopwatchPage` first appears (after the first frame, so
  target positions are known).
- One overlay shows **all hints at once** (not a step-by-step tour).
- Dismiss: tap anywhere, a **Got it** button, or the Android back button (`PopScope`).
- A **Show hints** `IconButton` (`Icons.help_outline`, tooltip "Show hints") in the
  app bar `actions`, before the About icon, reopens it.
- Positions are recalculated when the layout changes (window resize, rotation,
  the 720 px `wideLayoutBreakpoint` switch). If a target is not on screen, skip its hint.
- The timer icon also gets `tooltip: 'Classic Stopwatch'` (helps screen readers and
  long-press even without the overlay).

### "Already seen" logic

Put it behind an interface, the same pattern as `TimeSource`:

```dart
abstract interface class HintsSeenStore {
  Future<bool> isSeen();
  Future<void> markSeen();
}
```

- `InMemoryHintsSeenStore` – the default: hints show on every app launch,
  once per launch.
- Inject it through `ShopwatchDependencies` (new optional parameter `hintsStore`),
  so tests pass a fake.
- (Optional, ask me first) a `SharedPreferences` implementation for "first launch only".

## Suggested structure

```
lib/features/shopwatch/presentation/widgets/hint_overlay.dart
    HintTarget            – GlobalKey + text + icon/title
    HintOverlay           – StatefulWidget: dim layer, cut-outs, bubbles, arrows, Got it
    _SpotlightPainter     – CustomPainter
lib/features/shopwatch/services/hints_seen_store.dart
    HintsSeenStore, InMemoryHintsSeenStore
```

### Drawing

- Read each target's rect after layout:
  `final box = key.currentContext?.findRenderObject() as RenderBox?;`
  then `box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size`.
- `_SpotlightPainter`: one `Path` with `fillType = PathFillType.evenOdd` containing the
  full-screen rect plus a rounded rect (padding ~8 px) per target; fill with
  `Colors.black.withValues(alpha: 0.7)`. `shouldRepaint` compares the target rects.
- Bubble: a `Positioned` card placed below the target if there is room, otherwise
  above; clamp it inside the screen with a 16 px margin.
- Arrow: a short line plus arrow head from the bubble to the target's nearest edge,
  drawn in the same painter.
- Show the overlay with an `OverlayEntry` (`Overlay.of(context)`), so it covers the
  app bar too. Remove the entry on dismiss and in `dispose`.
- Wrap in `Semantics` with a label summarizing the hints; the Got it button is focusable.

## Tests (`test/features/shopwatch/hint_overlay_test.dart`)

Use `pumpWidget` with `ShopwatchPage` and fake dependencies (see
`test/features/shopwatch/fakes.dart`), a 390×844 view and a 1024×768 view.

1. Overlay appears on start when the store says "not seen"; all three hint texts are found.
2. Overlay does not appear when the store says "seen".
3. Tapping **Got it** removes it and calls `markSeen()` once.
4. Tapping outside the bubbles removes it.
5. **Show hints** reopens it.
6. In the wide layout, the hints still point at the right rects (compare the spotlight
   rect with `tester.getRect(find.byKey(...))`).
7. No overflow errors in either view size.

## Steps

1. `HintsSeenStore` + `InMemoryHintsSeenStore` + wiring into `ShopwatchDependencies`.
2. `HintTarget` + `_SpotlightPainter` with the cut-outs only (no text yet).
3. Bubbles, arrows, Got it, dismiss handling.
4. Auto-show from `ShopwatchPage` + **Show hints** button + tooltip on the timer icon.
5. Tests.
6. README: one line under Shopwatch about the hints.
