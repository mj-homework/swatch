/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'package:audioplayers/audioplayers.dart';

import '../domain/game_config.dart';

/// Plays feature-specific sound effects.
///
/// Keep the interface independent of any audio package so Shopwatch UI and
/// tests can use a production player or a lightweight fake implementation.
abstract interface class SoundPlayer {
  Future<void> playCheckoutBeep();

  Future<void> playScan(Accuracy accuracy);

  Future<void> dispose();
}

String scanAssetForAccuracy(Accuracy accuracy) => switch (accuracy) {
      Accuracy.perfect => 'sounds/scan_perfect.wav',
      Accuracy.close => 'sounds/scan_blip.wav',
      Accuracy.fair => 'sounds/scan_low.wav',
      Accuracy.missed => 'sounds/scan_error.wav',
    };

class CheckoutSoundPlayer implements SoundPlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _disposed = false;

  @override
  Future<void> playCheckoutBeep() async {
    await _playAsset('sounds/pos_beep.wav');
  }

  @override
  Future<void> playScan(Accuracy accuracy) =>
      _playAsset(scanAssetForAccuracy(accuracy));

  Future<void> _playAsset(String asset) async {
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
      if (!_disposed) await _player.play(AssetSource(asset), volume: 0.33);
    } catch (_) {
      // Audio must never block gameplay or checkout.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (_) {
      // Some platforms do not support audio.
    }
  }
}
