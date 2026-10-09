import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/generate_beep.dart';

void main() {
  test('original WAV is reproducible, mono PCM, 260 ms and bounded with silence', () {
    final bytes = generateBeep(); final data = ByteData.sublistView(bytes);
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
}
