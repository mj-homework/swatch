/*
 * Copyright (c) 2026 Juhász Mátyás
 * SPDX-License-Identifier: MIT
 */

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swatch/features/shopwatch/domain/game_config.dart';
import 'package:swatch/features/shopwatch/services/sound_player.dart';
import '../../../tool/generate_beep.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('original WAV is reproducible, mono PCM, 260 ms and bounded with silence', () {
    final bytes = generateBeep();
    final data = ByteData.sublistView(bytes);
    expect(bytes, File('assets/sounds/pos_beep.wav').readAsBytesSync());
    expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
    expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    expect(data.getUint16(22, Endian.little), 1);
    expect(data.getUint32(24, Endian.little), 44100);
    expect(data.getUint16(34, Endian.little), 16);
    expect((bytes.length - 44) / 2 / 44100, closeTo(.26, .00001));
    for (var offset = 44; offset < bytes.length; offset += 2) {
      expect(data.getInt16(offset, Endian.little).abs(), lessThanOrEqualTo(6500));
    }
    expect(data.getInt16(44 + 5292 * 2, Endian.little), 0);
  });

  test('scan sound follows the cart accuracy', () {
    expect(scanAssetForAccuracy(Accuracy.perfect), 'sounds/scan_perfect.wav');
    expect(scanAssetForAccuracy(Accuracy.close), 'sounds/scan_blip.wav');
    expect(scanAssetForAccuracy(Accuracy.fair), 'sounds/scan_low.wav');
    expect(scanAssetForAccuracy(Accuracy.missed), 'sounds/scan_error.wav');
  });

  test('scan sounds are bundled', () async {
    for (final asset in [
      'assets/sounds/scan_perfect.wav',
      'assets/sounds/scan_blip.wav',
      'assets/sounds/scan_low.wav',
      'assets/sounds/scan_error.wav',
      'assets/sounds/tick_loop_20.wav',
    ]) {
      expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(44));
    }
  });
}
