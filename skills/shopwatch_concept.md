# Shopwatch – concept

> Naming: **Stopwatch → Shopwatch**, always one word (code: `Shopwatch…` classes, `shopwatch` files/folders/variables).

> *Stop**watch** → Sho**p**watch.* The same stopwatch, dressed up as a shopping trip.

Shopwatch is the playful second feature of the app. The landing page offers two doors:

- **Classic Stopwatch** – the clean, by-the-spec solution.
- **Shopwatch** – the same engine, reskinned as a shopping trip with a contactless checkout.

Both features run on **the same stopwatch engine** (`core/stopwatch`). Shopwatch changes only the presentation: labels, visuals, sound and haptics. All homework requirements and tests still apply unchanged.

---

## 1. The story

You walk into the shop and start the clock. Every item you grab is a lap that goes into your cart. You can stop to window-shop and then carry on. At the end you pay at the terminal with a contactless tap. The terminal beeps, prints a receipt of your trip, and the clock goes back to zero, ready for the next shopping trip.

## 2. Button mapping

Every button keeps a clear icon and the original action name as a small subtitle. A reviewer checking the spec line by line must never have to guess.

| Spec action | Shopwatch label | Subtitle | Icon |
|---|---|---|---|
| Start | **Shop!** | start | `Icons.shopping_cart_outlined` |
| Pause | **Window shopping** | pause | `Icons.storefront_outlined` |
| Resume | **Back to it** | resume | `Icons.shopping_cart_checkout` |
| Lap | **Add to cart** | lap | `Icons.add_shopping_cart` |
| Clear laps | **Empty cart** | clear laps | `Icons.remove_shopping_cart_outlined` |
| Reset | **Pay** | reset | `Icons.contactless` |

## 3. Lap list = the receipt

The lap list is styled as a paper receipt:

- monospace font, off-white "paper" background, dashed separator lines, zig-zag torn edge at the bottom;
- each lap is a line item: `ITEM 03 ........ 00:12.481` (lap time), with the running total in small print;
- the footer shows `TOTAL TIME  03:42.517` and the item count;
- with 3+ items: the fastest lap is tagged **BEST DEAL**, the slowest **OVERPRICED**;
- an empty cart shows *"Your cart is empty. Time is ticking though."*

## 4. Checkout: the contactless Pay flow (Reset)

The highlight of the feature. Pressing **Pay** runs a short terminal moment, then resets:

1. **Freeze** – if the clock is running, it is paused first, so the total doesn't change during payment.
2. **Terminal sheet** (≈ 1 s) – a small POS-terminal panel slides up showing `TOTAL: 03:42.517`, with the contactless waves pulsing.
3. **Approved** – a short beep, a green check and a medium haptic tap. Text: **"Payment approved ✓"** (Hungarian mode: **"Sikeres fizetés"**). Fine print: *"No money was harmed in this transaction."*
4. **Receipt** – the final receipt is shown and can be dismissed.
5. **Reset** – the stopwatch returns to `00:00.000` and the cart is emptied.

Rules:

- The animation is short and **tap-to-skip**, so it never blocks the reset behaviour the spec requires.
- **Pay is disabled at `00:00.000` with an empty cart.** Nobody pays for nothing.
- The sound respects the device's silent mode. A mute toggle sits in the app bar.

### The beep

- **Self-made sound only**: a generated short double beep (sine wave ≈ 2.5 kHz, ~100 ms per beep, short gap). It's ours and generated in code, so there are no licensing questions.
- Do **not** use real card-scheme or terminal sounds, and do not use scheme brand names (e.g. *PayPass*) in the UI. The UI simply says **Pay** / **Contactless**.

## 5. Mood lines (light touch)

A small status line under the time, rotating by elapsed time. It is purely cosmetic:

| Elapsed | Line |
|---|---|
| 0–1 min | "Just browsing…" |
| 1–5 min | "Ooh, that's on sale." |
| 5–15 min | "Do we really need a third one?" |
| 15+ min | "The bag holder needs a bench." |
| paused | "Window shopping. Look, don't touch." |

Keep it person-neutral: no "wife shops, husband waits" jokes.

## 6. Analog clock skin

- The dial is styled like a round price tag (a hole and a little string at 12 o'clock).
- The second-hand progress ring becomes a **"closing time"** bar that fills each minute.
- Hands stay exactly as in the classic clock (same `handAngles` math, same smooth sweep). Only colours and decorations change.

## 7. Visual identity

- Bright, retail palette: receipt white, price-tag yellow, a fresh green accent for "approved".
- Monospace only for receipt and terminal elements. The main time keeps tabular figures.
- **Branding caution:** "OPT" may appear as a wink in text, but there is no OTP logo, no exact brand colours and no brand name in the UI. A parody of the interviewer's brand works in words and is risky if it looks like their real app.

## 8. Architecture

Shopwatch is **one feature** that contains both the free shopping mode and the game (section 10). They share the receipt, the Pay checkout, the beep and the price-tag clock, so keeping them together avoids cross-feature imports. The game's logic and its Firebase access get their own layers inside the feature.

```
lib/
  core/stopwatch/                shared engine (Cubit, TimeSource, Lap) – unchanged
  features/shopwatch/
    domain/                      game only
      game_config.dart
      game_round.dart            immutable: items, goals, results, status
      shopwatch_game_cubit.dart  setup → playing → finished → (pay) → setup
    data/                        game only
      leaderboard_repository.dart            interface
      firestore_leaderboard_repository.dart  Firebase implementation
    presentation/
      pages/
        shopwatch_page.dart      free shopping mode
        game_setup_page.dart
        game_page.dart
      widgets/                   shared by free mode and game
        receipt_lap_list.dart
        pos_terminal_sheet.dart
        price_tag_clock.dart
        mood_line.dart
    services/
      sound_player.dart          interface + audioplayers implementation
    shopwatch_strings.dart       all labels and mood lines in one place
assets/sounds/pos_beep.wav       generated, ours
```

Routes: `/shopwatch` (free mode), `/shopwatch/game` (setup), `/shopwatch/game/play` (round).

- **No new business logic in free mode.** Pay = `pause()` → show sheet → `reset()`. Everything stays covered by the existing engine tests.
- **`SoundPlayer` interface**, the same idea as `TimeSource`. Production uses `audioplayers`; tests inject a fake. That keeps widget tests silent and lets them assert *"Pay played the beep exactly once."*
- **Haptics**: `HapticFeedback.mediumImpact()` on approval.
- **Strings centralised** in one file, which makes a Hungarian variant easy.

## 9. Tests (beyond the shared engine tests)

- Tapping **Pay** while running freezes the total shown on the terminal, then resets to `00:00.000`.
- Pay plays the beep once (fake `SoundPlayer`) and plays nothing when muted.
- Tap-to-skip finishes the checkout immediately.
- Pay is disabled when idle at zero with an empty cart.
- Receipt shows items newest-last with correct lap and total times; BEST DEAL / OVERPRICED tags appear only with 3+ items.
- Mood line changes at its thresholds (driven by the fake `TimeSource`).

## 10. Shopwatch Game ("Time is money")

A timing game built on the Shopwatch skin: hit each item's goal time as precisely as you can by pressing **Add to cart**.

### 10.1 Setup screen

- **Nickname**: required. Uniqueness is checked live against the leaderboard while typing (debounced, see 10.7).
- **Number of items**: 1 … size of the item list. Items are drawn **without repeats**.
- **Difficulty**:

| Difficulty | Digital time | Analog clock |
|---|---|---|
| Easy | always visible | visible |
| Normal | hidden 2 s after each item starts (`--:--.---`) | hands keep moving, no digits |
| Hard | hidden from the start | hidden |

- **Start shopping** enables the game screen.

### 10.2 Items

A configurable list of funny Hungarian shopping items, e.g. *farhát, büdös sajt, hajzselé, fokhagymás lángos, tescós zacskó, ananászos pizza, akciós pizsama, zokni páratlanul*.

### 10.3 Round flow

1. **Shop!** (Start) starts the stopwatch, and the first random item appears at the top with its **goal time shown as a price tag**: `BÜDÖS SAJT — 7,350` (it reads like 7 350 Ft, but it means 7.350 s).
2. The goal time is random in **[minGoal, maxGoal]**, by default 5–15 s, with millisecond resolution.
3. **Add to cart** (Lap) records the item. The goal is measured **per item, from the previous Add to cart** (the lap time), so the engine's existing lap logic is reused unchanged.
4. The receipt prints the line, and the next random item appears immediately while the clock keeps running.
5. After the last item, the stopwatch **stops automatically**, the receipt prints the total, and **Pay is enabled**.
6. **Pay** runs the checkout flow (section 4), resets the game and returns to the setup screen with the nickname pre-filled.

During a round, **Pause and Empty cart are disabled** (no cheating, no confusing states). **Pay** is disabled until the round is finished.

### 10.4 Receipt lines

```
BÜDÖS SAJT      goal   7.350
                got    7.512   +0.162
FARHÁT          goal  11.200
                got   10.954   −0.246
------------------------------------
TOTAL DIFF                      0.408
```

- `diff = got − goal`, shown signed (`+` = too late, `−` = too early).
- **Total diff = sum of absolute diffs.** Lower is better, and this is the leaderboard score.
- The line colour shows the accuracy of `|diff|`:

| \|diff\| | Colour |
|---|---|
| ≤ 0.050 s | green (perfect) |
| ≤ 0.250 s | light green |
| ≤ 0.750 s | amber |
| > 0.750 s | red |

Thresholds live in `GameConfig`. Colour is never the only signal, since the signed number is always printed.

### 10.5 Configuration (`GameConfig`)

- `items` (list of names)
- `minGoal`, `maxGoal` (default 5 s / 15 s)
- `normalHideAfter` (default 2 s)
- accuracy thresholds

### 10.6 Architecture

The game lives inside the `shopwatch` feature (see section 8): its logic in `domain/`, Firebase access in `data/`, and its pages next to the free mode's page, reusing the same receipt, terminal and clock widgets.

- The **stopwatch engine is unchanged**. The game cubit listens to lap events and maps each lap to the current item.
- **`Random` is injected**, the same pattern as `TimeSource`. Tests use a seeded `Random`, so item order and goal times are deterministic.
- **`LeaderboardRepository` is an interface**, with a fake in tests. Widget tests never touch Firebase.

### 10.7 Leaderboard (Firebase)

- **Cloud Firestore**, with a `players/{normalizedNickname}` doc for nickname ownership and a `scores` collection holding `{nickname, totalDiffMs, itemCount, difficulty, createdAt}`.
- **Firebase Anonymous Auth** gives each device a uid. A nickname doc stores its owner's uid, so a player can reuse their own nickname but nobody else can.
- **Live nickname check while typing**: debounced (~400 ms), with the states *checking… / available ✓ / taken ✗ / offline*. Stale responses are ignored (only the latest query counts).
- The live check is only a hint. The nickname is **reserved atomically in a transaction** on Start, which closes the race where two players check the same free nickname at once.
- Nickname rules: 3–16 chars, letters, digits, `_`; compared case- and accent-insensitively (normalized key). A small bad-word filter is used, since reviewers will see the board.
- The leaderboard is ranked **per item count and difficulty**, ordered by `totalDiffMs` ascending (top 10).
- **Security rules**: a user can only write their own nickname doc and their own scores, and scores are validated for shape and ranges.
- **Graceful fallback**: if Firebase isn't configured or is offline, the game still works and the leaderboard shows "offline". Reviewers can run the app without Firebase credentials.

### 10.8 Game tests

- Seeded `Random` → expected items and goals.
- Fake `TimeSource` → lap at a known time → correct signed diff, colour bucket and total.
- Round ends automatically after N items; Pay is enabled only then.
- Pause and Empty cart are disabled during a round.
- Difficulty hides or shows the digits at the right moment.
- Nickname check: debounce (one query per typing burst), stale responses ignored, the taken/available states rendered (fake repository).

## 11. Out of scope / maybe later

- Export the receipt as CSV / share it.
- Hungarian language toggle beyond the "Sikeres fizetés" line.
- "Time is money" meter (cost of your time at a playful hourly rate). It's fun, but it adds input and math, and it must read clearly as a toy.
