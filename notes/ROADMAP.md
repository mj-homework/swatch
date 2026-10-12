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
