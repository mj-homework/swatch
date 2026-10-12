# Shopwatch Test Coverage

| Case | Coverage |
|---|---|
| Start and elapsed time increases | **Partial.** `test/features/shopwatch/game_domain_test.dart` starts the game and uses a fake clock to check timing in gameplay results, but doesn’t directly assert that `elapsed` increases after advancing time. |
| Pause freezes elapsed time | **No effective test.** The domain test calls `pause()`, but that method is a no-op. I don’t see a test of the actual pause/resume behavior via `togglePause()`. |
| Reset to zero and stop | **Partial.** The domain test checks that `reset()` after a finished round returns the game to ready with elapsed time at zero; checkout’s `resetClock()` isn’t directly tested for stopping elapsed time. |
| Widget interactions | **Partial.** `shopping_controls_test.dart` checks that taps and long-presses invoke the right callbacks; `scan_feedback_test.dart` tests starting and adding items. I don’t see an end-to-end test of tapping pause/resume or checkout and verifying the clock. |
| Repeated start | **Partial.** The domain test calls `start()` twice, but doesn’t explicitly verify that elapsed time is unaffected by the second call. |
