import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Original 2500 Hz double beep: 100 ms tone, 60 ms silence, 100 ms tone.
Uint8List generateBeep() {
  const rate = 44100;
  const frames = rate * 260 ~/ 1000;
  final bytes = ByteData(44 + frames * 2);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, rate, Endian.little);
  bytes.setUint32(28, rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final t = i / rate;
    final local = t < 0.1
        ? t
        : t >= 0.16
            ? t - 0.16
            : -1.0;
    final fade = local < 0 ? 0.0 : min(1.0, min(local / 0.005, (0.1 - local) / 0.005)).clamp(0.0, 1.0);
    bytes.setInt16(44 + i * 2, (sin(2 * pi * 2500 * local) * fade * 6500).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

void main() {
  final file = File('assets/sounds/pos_beep.wav');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(generateBeep());
}
