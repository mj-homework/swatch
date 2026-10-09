# Stopwatch · Sho**p**watch

A Flutter stopwatch app built for the OTP Bank Flutter homework, with a playful twist.

- **Stopwatch** – the classic solution, by the spec: start, pause/resume, reset, laps and an analog clock.
- **Shopwatch** – the same stopwatch engine, reskinned as a shopping trip with a contactless checkout, plus a timing game with a leaderboard.

> *Stop**watch** → Sho**p**watch.* One letter changed, one word, always.

---

## Contents

- [Status](#status)
- [Navigation](#navigation)
- [Landing page](#landing-page)
- [Stopwatch (classic)](#stopwatch-classic)
- [Shopwatch](#shopwatch)
- [Shopwatch Game](#shopwatch-game)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Testing](#testing)
- [Design decisions](#design-decisions)

---

## Status

| Part | Status |
|---|---|
| Stopwatch – Task 1 (start, pause/resume, reset, `MM:SS.mmm`, tests 1–5) | ✅ done |
| Stopwatch – Task 2 (laps, clear) | ✅ done |
| Stopwatch – Nice-to-have (analog clock) | ✅ done |
| Landing page + routing | 🚧 planned |
| State management → Cubit | 🚧 planned |
| Shopwatch skin (receipt, POS Pay) | 🚧 planned |
| Shopwatch Game + Firebase leaderboard | 🚧 planned |

---

## Navigation

The app uses [`go_router`](https://pub.dev/packages/go_router). Every screen has its own URL, so on web any screen can be opened directly.

| Route | Screen |
|---|---|
| `/` | Landing page – choose a direction |
| `/stopwatch` | Classic Stopwatch |
| `/shopwatch` | Shopwatch – free shopping mode |
| `/shopwatch/game` | Shopwatch Game – setup (nickname, items, difficulty) |
| `/shopwatch/game/play` | Shopwatch Game – the round |

```
            ┌──────────────┐
            │   Landing    │  /
            └──────┬───────┘
         ┌─────────┴──────────┐
         ▼                    ▼
  ┌─────────────┐      ┌─────────────┐
  │  Stopwatch  │      │  Shopwatch  │  /shopwatch
  │ /stopwatch  │      └──────┬──────┘
  └─────────────┘             ▼
                       ┌─────────────┐
                       │ Game setup  │  /shopwatch/game
                       └──────┬──────┘
                              ▼
                       ┌─────────────┐
                       │ Game round  │  /shopwatch/game/play
                       └─────────────┘
```

---

## Landing page

The entry screen offers two cards:

- **Stopwatch** – *"The serious one."* Clean, by the spec.
- **Shopwatch** – *"The fun one."* Shop against the clock.

Both cards show a small live preview of their style. On wide screens they sit side by side; on phones they stack.

---

## Stopwatch (classic)

The homework solution.

- **Start** counts up from zero.
- **Pause** freezes the time. Pressing it again (**Resume**) continues from where it left off.
- **Reset** stops the stopwatch, returns it to `00:00.000` and clears the laps.
- **Lap** records the current lap: each row shows the lap time and the total time, newest on top. With 3+ laps the fastest and slowest are highlighted.
- **Clear** empties the lap list without stopping the stopwatch.
- **Display**: `MM:SS.mmm`. Minutes keep counting past an hour (`75:30.000`).
- **Analog clock**: the second hand makes one turn per minute, the minute hand one per hour, the hour hand one per 12 hours, plus a ring showing progress within the current minute. The hands sweep smoothly, computed every frame from the elapsed time.
- Buttons are disabled whenever their action would do nothing (e.g. Start while running, Lap while paused).
- Responsive layout (side by side ≥ 720 px, stacked on phones), light and dark theme.

---

## Shopwatch

The same engine, dressed up as a shopping trip. You walk into the shop and start the clock. Every item you grab is a lap that goes into your cart. At the end, you pay at the terminal with a contactless tap.

### Buttons

Every button keeps a clear icon and the original action name as a subtitle, so the spec is never hidden.

| Spec action | Shopwatch label | Icon |
|---|---|---|
| Start | **Shop!** | 🛒 |
| Pause / Resume | **Window shopping** / **Back to it** | 🏪 |
| Lap | **Add to cart** | ➕🛒 |
| Clear laps | **Empty cart** | 🗑️ |
| Reset | **Pay** | contactless |

### The receipt

The lap list is a paper receipt: monospace text, dashed lines and a torn edge. Each lap is a line item, and the footer shows the total time. With 3+ items, the fastest is tagged **BEST DEAL** and the slowest **OVERPRICED**.

### Pay: the contactless checkout

**Pay** (Reset) runs a short terminal moment:

1. The clock freezes if it's running.
2. A POS terminal panel slides up showing the total, with pulsing contactless waves.
3. **Beep**, a green check and a haptic tap: **"Payment approved ✓"** (*"Sikeres fizetés"*).
4. The receipt is shown, then the stopwatch resets.

The animation is short and tap-to-skip, so it never gets in the way of the reset. The beep is a self-generated sound, not a real terminal or card-scheme sound. Pay is disabled at zero with an empty cart. Nobody pays for nothing.

### Extras

- **Mood line**: a status line that changes with elapsed time, from *"Just browsing…"* to *"The bag holder needs a bench."*
- **Price-tag clock**: the analog clock styled as a round price tag, with a "closing time" ring.

---

## Shopwatch Game

*Time is money.* Hit each item's goal time as precisely as you can.

### Setup (`/shopwatch/game`)

- **Nickname**: required. Availability is checked live while you type (debounced) against the leaderboard.
- **Number of items** to collect.
- **Difficulty**:

| Difficulty | Digital time | Analog clock |
|---|---|---|
| Easy | always visible | visible |
| Normal | hidden 2 s into each item | hands only |
| Hard | hidden from the start | hidden |

### Round (`/shopwatch/game/play`)

1. **Shop!** starts the clock. A random item appears with its goal time as a price tag: **BÜDÖS SAJT — 7,350**. That reads like 7 350 Ft, but means 7.350 seconds.
2. Goal times are random between **5 and 15 s** (configurable).
3. Press **Add to cart** as close to the goal as you can. Each goal is measured from the previous Add to cart.
4. The receipt prints the goal, what you got and the signed difference, coloured by accuracy.
5. After the last item, the clock stops and the total difference is printed. **Pay** is enabled.
6. **Pay** runs the checkout and returns you to setup.

Pause and Empty cart are disabled during a round.

```
BÜDÖS SAJT      goal   7.350
                got    7.512   +0.162
FARHÁT          goal  11.200
                got   10.954   −0.246
------------------------------------
TOTAL DIFF                      0.408
```

| \|diff\| | Colour |
|---|---|
| ≤ 0.050 s | green (perfect) |
| ≤ 0.250 s | light green |
| ≤ 0.750 s | amber |
| > 0.750 s | red |

### Leaderboard

- **Cloud Firestore**, with **Firebase Anonymous Auth** so each device owns its nickname.
- The nickname is reserved atomically when the round starts. The live check while typing is only a hint.
- Scores are ranked by total difference (lower is better), per item count and difficulty.
- **Works without Firebase:** if it isn't configured or is offline, the game runs normally and the leaderboard shows "offline".

---

## Architecture

Feature-first structure with three features: **landing**, **stopwatch** and **shopwatch**. They match the two directions of the landing page. Both stopwatch features run on **one shared stopwatch engine**; only the presentation differs.

The Shopwatch free mode and the Shopwatch Game are **one feature**. They share the receipt, the Pay checkout, the beep and the price-tag clock, so splitting them would only create cross-feature imports. Inside the feature, the game's logic (`domain/`) and its Firebase access (`data/`) have their own layers.

```
lib/
  main.dart
  app/
    app.dart                      MaterialApp, themes
    router.dart                   go_router routes
  core/
    stopwatch/                    the engine: Cubit, state, TimeSource, Lap
    formatting/                   MM:SS.mmm
    widgets/                      shared widgets (analog clock)
  features/
    landing/
      landing_page.dart
    stopwatch/                    classic presentation
      presentation/
    shopwatch/
      domain/                     GameConfig, GameRound, ShopwatchGameCubit
      data/                       LeaderboardRepository (+ Firestore impl)
      presentation/
        pages/                    shopwatch_page, game_setup_page, game_page
        widgets/                  receipt, pos_terminal_sheet, price_tag_clock, mood_line
      services/                   SoundPlayer (+ audioplayers impl)
      shopwatch_strings.dart      all labels and mood lines
assets/sounds/pos_beep.wav        generated, ours
test/                             mirrors lib/
docs/
  shopwatch_concept.md            the full concept
```

Key ideas:

- **Time is computed, not counted.** `elapsed = accumulated + (now − startedAt)` from a monotonic clock. There's no drifting timer counter.
- **Everything nondeterministic is injected**: `TimeSource` (clock), `Random` (items and goals), `SoundPlayer` (beep), `LeaderboardRepository` (Firebase). Tests replace each with a fake, so they are fast and deterministic.
- **The Cubit emits only on real events** (start, pause, lap, reset). Per-frame updates go through a `Ticker` to the readout and clock only, without rebuilding the widget tree.
- **Explicit state machine:** `idle → running ⇄ paused → idle`. Actions that make no sense in the current state are no-ops, and their buttons are disabled.

---

## Getting started

Requires Flutter ≥ 3.27 (Dart ≥ 3.6).

```bash
flutter pub get
flutter run            # Android, iOS, web or desktop
flutter test
flutter analyze
```

### Firebase (optional, Shopwatch Game leaderboard)

```bash
dart pub global activate flutterfire_cli
flutterfire configure            # generates lib/firebase_options.dart
```

Enable **Anonymous** sign-in and **Cloud Firestore** in the Firebase console, and deploy the security rules from `firestore.rules`. Without this step the app still runs; the leaderboard is simply offline.

---

## Testing

| Area | What is covered |
|---|---|
| Engine | start / pause / resume / reset, repeated start, no-ops when idle, laps, clear |
| Formatting | `MM:SS.mmm`, padding, over an hour, negatives |
| Analog clock | hand angles, smooth sweep, 12-hour wrap |
| Stopwatch UI | tapping buttons, live updates, button states, narrow layout |
| Shopwatch | Pay freezes, beeps once (fake player), resets; disabled at zero |
| Game | seeded items and goals, signed diffs and colours, auto-finish, difficulty hiding, debounced nickname check |

The homework's required test cases 1–5 are in `test/core/stopwatch/` and `test/features/stopwatch/`.

---

## Design decisions

- **Why two features?** The classic Stopwatch answers the spec exactly. Shopwatch shows the same engine can carry a completely different product, which is the payoff of keeping logic and UI apart.
- **Why Cubit?** Immutable state, a clear separation of logic and UI, and readable `blocTest`s. It's also a common choice in larger Flutter teams.
- **Why go_router?** Declarative routes, deep links on web, and easy navigation tests.
- **Why no real terminal sound or brand?** The beep is generated, and no bank or card-scheme branding appears in the UI. It's a parody in words only.

See [`docs/shopwatch_concept.md`](docs/shopwatch_concept.md) for the full Shopwatch concept.
