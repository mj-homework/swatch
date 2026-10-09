import 'package:audioplayers/audioplayers.dart';

/// Plays feature-specific sound effects.
///
/// Keep the interface independent of any audio package so Shopwatch UI and
/// tests can use a production player or a lightweight fake implementation.
abstract interface class SoundPlayer {
  Future<void> playCheckoutBeep();

  Future<void> dispose();
}

class CheckoutSoundPlayer implements SoundPlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;
  @override
  Future<void> playCheckoutBeep() async {
    if (_disposed) return;
    try {
      await _player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.assistanceSonification,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
      if (!_disposed) await _player.play(AssetSource('sounds/pos_beep.wav'), volume: 0.5);
    } catch (_) { /* Audio must never block checkout. */ }
  }
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try { await _player.dispose(); } catch (_) { /* Unsupported platform. */ }
  }
}
