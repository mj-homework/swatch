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

With three or more laps, the fastest lap is highlighted in the primary colour
and the slowest in the error colour.

### Shopwatch (the game)

The app opens on Shopwatch. On the first screen a hint overlay points at the
most important controls; tap anywhere or **Got it** to close it. It can be
reopened from the **About** dialog (**Show hints**).

The timer icon on the left of the app bar opens the **Classic Stopwatch**, and
the back button returns to Shopwatch. The icon is available while no shopping
round is in progress.

---

## How to play

1. **Start shopping.** Tap **Shop!** and choose how many items to collect:
   *Unlimited* (the default) or 1–99. The sheet starts the round by itself
   after 5 seconds; typing a number stops the countdown.
   *Long press* **Shop!** to skip the sheet and start straight away with the
   last chosen item count (unlimited the first time). **Add to cart** appears
   where **Shop!** was, so it stays disabled for 300 ms after a long-press
   start – a quick follow-up tap cannot add an item by accident.
2. **Read your shopping list.** The current item and its goal time appear
   under the clock, e.g. *Collect HAUNTED TOASTER at 00:07.350*. The goal is
   also marked on the clock face with a green tick.
3. **Add to cart at the right moment.** The clock runs continuously. Tap
   **Add to cart** when it reaches the goal time. The item is printed on the
   receipt, and the next item appears at once with a new goal 3–13 seconds
   after your tap. The first goal is 5–15 seconds after the start.
4. **Take a break if you need one.** **Coffee break** pauses the clock;
   **Back to it** continues. The goals are on the same clock, so nothing is
   lost.
5. **Start over if it went badly.** **Put it all back** (under the receipt)
   empties the cart and restarts at item 1 without resetting the clock.
6. **Finish.** With a fixed number of items, the clock stops after the last
   one: *Cart complete — pay to see your receipt.* In unlimited mode you decide
   when to stop.
7. **Pay.** See [Checkout](#checkout-pay) below.

**Scoring:** for each item the receipt prints the goal, the time you got and
the signed difference (`+` too late, `−` too early). Your score is the
**average difference** – lower is better.

| \|difference\| | Rating | Colour |
|---|---|---|
| ≤ 0.050 s | PERFECT | green |
| ≤ 0.250 s | CLOSE | light green |
| ≤ 0.750 s | FAIR | amber |
| > 0.750 s | MISSED | red |

The rating is always printed as text and the difference as a number, so colour
is never the only signal. Each rating also has its own scanner sound.

---

## Controls

Every Shopwatch button maps to a stopwatch action from the spec:

| Spec action | Shopwatch button | Behaviour |
|---|---|---|
| Start | **Shop!** | Tap: opens the item count sheet. Long press: quick start. Disabled while a round is in progress. |
| Lap | **Add to cart** | Takes the place of **Shop!** during a round; disabled for 300 ms after a long-press start. Records the current item on the receipt; the receipt scrolls to the newest line. |
| Pause / Resume | **Coffee break** / **Back to it** | One toggle button; enabled while a round is being played. |
| Clear laps | **Put it all back** | Under the receipt; empties the cart and restarts at item 1. |
| Reset | **Pay** | Tap: opens the checkout. Long press: ends the round immediately and resets the clock. |

The app bar also has a **mute** button and an **About** dialog (licence and
**Show hints**).

### Checkout (Pay)

1. Tapping **Pay** pauses the clock and opens the payment sheet, which shows
   your average difference.
2. **Tap the pulsing contactless icon** to pay: a terminal beep and a short
   vibration confirm it, and the final receipt appears on the same sheet.
3. **Bag it & go** ends the round and resets the clock to `00:00.000`.
4. **Cancel** (or **Continue shopping** in unlimited mode) closes the sheet;
   a running round continues where it was.

With an empty cart, **Pay** asks first: **Checkout anyway** ends the round,
**Continue** goes back to shopping.

### Sounds

All sounds are generated in code (no third-party or brand sounds): scanner
blips for adding items (one per rating), a terminal beep on payment, and a soft
tick while the clock runs. The mute button in the app bar silences everything,
on both screens.

---

## Light and dark theme

The app follows the device's **system theme** – switch the phone (or the
desktop OS) to dark mode and the app follows; there is no in-app switch.

- Both themes are built from the same Material 3 colour scheme with a green
  palette: dark green `#00674C` and lime `#6EC72D`.
  - **Light:** dark green is the primary colour, lime the accent.
  - **Dark:** lime becomes the primary colour, always with dark text on it for
    contrast.
- Widgets take their colours from the theme (`ColorScheme`), so the clock
  face, buttons, hint bubbles and lap list adapt automatically.
- The **receipt stays white paper in both themes** on purpose: it is a printed
  receipt. Its ink and rating colours were chosen for contrast on white.
- Text sizes come from the theme's text styles (scaled to 0.9 so the layout
  fits average phone screens), so the user's accessibility text size setting
  is still respected.

To try dark mode: change the device's display setting, or on Android run
`adb shell cmd uimode night yes` (`no` to switch back).

---

## Responsive layout

- **Phones (portrait):** clock on top, buttons below, receipt / lap list at
  the bottom.
- **Wide screens (720 px and up), tablets, landscape and desktop windows:** the
  receipt or lap list moves to the side, next to the clock and the buttons.
- The time display uses tabular figures, so the digits don't jitter while
  counting.

---

## Design decisions

- **Elapsed time is computed, not counted.** The stopwatch reads an injectable,
  monotonic `TimeSource` instead of adding up timer ticks, so it never drifts
  and is fully deterministic in tests.
- **One engine, two faces.** The Classic Stopwatch and the Shopwatch game both
  run on the same `StopwatchController`; the game maps each lap to the current
  item.
- **Only the time repaints.** A `Ticker` drives the digital readout and the
  clock face; the rest of the screen rebuilds only on state changes.
- **Everything nondeterministic is injected** – time, randomness, sound,
  haptics and the "hints seen" store – so unit and widget tests run fast,
  silent and repeatable.
- **Reset also clears the laps.** In the Classic Stopwatch, Reset returns to a
  clean start (`00:00.000`, no laps); **Clear** removes only the laps without
  touching the running time.
- **No real brands.** The checkout says *Pay* and *Contactless*; no card-scheme
  names, logos or sounds are used.

---

## Getting started

Requirements: Flutter (stable channel) and a device, emulator or desktop
target.

```bash
flutter pub get
flutter run
```

No external services or API keys are needed.

## Tests

```bash
flutter test
flutter analyze
```

The tests cover the assignment's test cases 1–5, laps, the analog clock maths,
and the Shopwatch flows (start, pause, add to cart, checkout, sounds and the
item count sheet).

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
- **Remember the hints** – show the hint overlay only on the first launch
  (e.g. with `shared_preferences`), behind the existing `HintsSeenStore`
  interface.

## License

Shopwatch is licensed under the MIT License. See [LICENSE](LICENSE) for details.
