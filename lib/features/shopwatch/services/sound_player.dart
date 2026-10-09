/// Plays feature-specific sound effects.
///
/// Keep the interface independent of any audio package so Shopwatch UI and
/// tests can use a production player or a lightweight fake implementation.
abstract interface class SoundPlayer {
  Future<void> playCheckoutBeep();

  Future<void> dispose();
}
