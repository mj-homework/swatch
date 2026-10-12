/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'package:audioplayers/audioplayers.dart';

import 'package:swatch/features/shopwatch/domain/game_config.dart';

/// Plays feature-specific sound effects.
///
/// Keep the interface independent of any audio package so Shopwatch UI and
/// tests can use a production player or a lightweight fake implementation.
abstract interface class SoundPlayer {
  Future<void> playCheckoutBeep();

  Future<void> playScan(Accuracy accuracy);

  Future<void> startTicking();

  Future<void> stopTicking();

  Future<void> dispose();
}

String scanAssetForAccuracy(Accuracy accuracy) => switch (accuracy) {
      Accuracy.perfect => 'sounds/scan_perfect.wav',
      Accuracy.close => 'sounds/scan_blip.wav',
      Accuracy.fair => 'sounds/scan_low.wav',
      Accuracy.missed => 'sounds/scan_error.wav',
    };

class AudioSoundPlayer implements SoundPlayer {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _tickPlayer = AudioPlayer();
  bool _disposed = false;
  bool _ticking = false;
  int _tickRequest = 0;

  @override
  Future<void> playCheckoutBeep() async {
    await _playAsset('sounds/pos_beep.wav');
  }

  @override
  Future<void> playScan(Accuracy accuracy) => _playAsset(scanAssetForAccuracy(accuracy));

  @override
  Future<void> startTicking() async {
    if (_disposed || _ticking) return;
    _ticking = true;
    final request = ++_tickRequest;
    try {
      await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _tickPlayer.setReleaseMode(ReleaseMode.loop);
      await _tickPlayer.setAudioContext(_audioContext);
      if (!_disposed && _ticking && request == _tickRequest) {
        await _tickPlayer.play(AssetSource('sounds/tick_loop_10.wav'), volume: 0.2);
      }
    } catch (_) {
      // Audio must never interfere with stopwatch operation.
    }
  }

  @override
  Future<void> stopTicking() async {
    _ticking = false;
    ++_tickRequest;
    try {
      await _tickPlayer.stop();
    } catch (_) {
      // Audio must never interfere with stopwatch operation.
    }
  }

  AudioContext get _audioContext => AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.assistanceSonification,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      );

  Future<void> _playAsset(String asset) async {
    if (_disposed) return;
    try {
      await _player.setAudioContext(_audioContext);
      if (!_disposed) await _player.play(AssetSource(asset), volume: 0.33);
    } catch (_) {
      // Audio must never block gameplay or checkout.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopTicking();
    try {
      await _player.dispose();
    } catch (_) {
      // Some platforms do not support audio.
    }
    try {
      await _tickPlayer.dispose();
    } catch (_) {
      // Some platforms do not support audio.
    }
  }
}
