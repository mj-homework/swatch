# Shopwatch

A Flutter stopwatch app built as a homework assignment. It has two faces:

- **Classic Stopwatch** – the clean, by-the-spec solution.
- **Shopwatch** – the same stopwatch idea turned into a shopping game: add items
  to your cart at exactly the right millisecond, then pay at a contactless
  terminal.

> *Stop**watch** → Sho**p**watch.* The same stopwatch, dressed up as a shopping trip.

---

## Features

### Classic Stopwatch (the assignment)

| Task | What it does |
|---|---|
| Task 1 | Start, pause / resume and reset, with a `MM:SS.mmm` display |
| Task 2 | Laps, with a button to clear them |
| Nice-to-have | Analog clock with smoothly sweeping hands |

### Shopwatch (the game)

The app opens on Shopwatch. The timer icon on the left of the app bar opens the
Classic Stopwatch, and the back button returns to Shopwatch.

**Goal:** press **Add to cart** exactly when the current item's goal time is
reached. The goal moment is also marked on the clock face with a light green
tick.

Each item is a random **property + name** pair (e.g. *HAUNTED TOASTER*), so
every shopping trip is different.

---

## Controls

Every Shopwatch button maps to a stopwatch action from the spec:

| Spec action | Shopwatch button | Behaviour |
|---|---|---|
| Start | **Shop!** | Tap: a sheet opens to choose the number of items (unlimited by default, or 1–99). Double tap: quick start in unlimited mode. Disabled while a game is running. |
| Pause / Resume | **Coffee break** / **Back to it** | One toggle button: pauses the game, and its label switches to *Back to it* to continue. |
| Lap | **Add to cart** | Puts the current item in the cart and prints it on the receipt, coloured by how close you were to the goal. The receipt scrolls to the newest line. |
| Clear laps | **Put it all back** | At the bottom of the receipt; empties the cart. |
| Reset | **Pay** | Tap: opens the payment sheet (see below). Double tap: resets the game immediately. |

### Checkout (Pay)

1. Tapping **Pay** opens the payment sheet, and the clock stops while it is open.
2. **Cancel** closes the sheet. A running game continues; a finished game just
   stays on screen.
3. **Tap to pay** plays a beep and shows the final receipt on a new sheet.
4. **Bag it & go** resets the game completely.

In a game with a fixed number of items, the clock stops automatically after the
last item.

### Receipt colours

Each receipt line shows the signed difference from the goal time (`+` too late,
`−` too early). The colour reflects the accuracy, but the number is always
printed, so colour is never the only signal.

| \|difference\| | Colour |
|---|---|
| ≤ 0.050 s | green (perfect) |
| ≤ 0.250 s | light green |
| ≤ 0.750 s | amber |
| > 0.750 s | red |

### Sounds

All sounds are generated in code (no third-party or brand sounds): scanner
blips for adding items, a terminal beep on payment, and a soft tick while the
clock runs.

---

## Design decisions

- **Elapsed time is computed, not counted.** The stopwatch reads an injectable,
  monotonic `TimeSource` instead of adding up timer ticks, so it never drifts
  and is fully deterministic in tests.
- **Only the time repaints.** A `Ticker` drives the digital readout and the
  clock face; the rest of the screen rebuilds only on state changes.
- **Everything nondeterministic is injected** – time, randomness and sound – so
  unit and widget tests run fast, silent and repeatable.
- **No real brands.** The checkout says *Pay* and *Contactless*; no card-scheme
  names, logos or sounds are used.

---

## Getting started

Requirements: Flutter (stable channel) and a device or emulator.

```bash
flutter pub get
flutter run
```

No external services or API keys are needed.

## License

Shopwatch is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Tests

```bash
flutter test
flutter analyze
```

The tests cover the assignment's test cases 1–5, laps, the analog clock maths,
and the Shopwatch flows.

---

## Roadmap

- **Internationalization (i18n)** – move all UI strings to ARB files with
  `flutter_localizations`; first targets: English and Hungarian.
- **Online leaderboard** – Cloud Firestore + Firebase Anonymous Auth;
  live, debounced nickname check while typing, atomic nickname reservation
  in a transaction; behind a `LeaderboardRepository` interface so tests and
  offline runs never depend on Firebase.
- **Item properties and names from a database** – load the generator's word
  lists from a remote source instead of hard-coded lists, with the bundled
  lists as an offline fallback.
- **Difficulty levels** – Easy (digits always visible), Normal (digits hidden
  2 s after each item starts), Hard (digits and clock hands hidden).
- **Long-press shortcuts** – replace the double-tap quick actions on Shop!
  and Pay with long press: no tap delay, and clearer intent.
- **Compact control layout** – left column: Coffee break / Back to it, with
  Pay below; right side: one large primary button that reads Shop! when idle
  and Add to cart while running. Because the same button starts the clock and
  records items, a short lap lockout (~300 ms) after start prevents a fast
  double tap from adding an item by accident; the long-press quick start
  removes the risk entirely.
