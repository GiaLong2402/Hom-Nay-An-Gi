// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Sinh file WAV nhỏ cho hiệu ứng âm thanh (chạy: dart run tool/generate_sfx.dart).
void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  File('assets/sounds/wheel_tick.wav').writeAsBytesSync(
    _generateTone(
      frequency: 1400,
      durationMs: 35,
      volume: 0.35,
      decay: true,
    ),
  );

  File('assets/sounds/wheel_win.wav').writeAsBytesSync(
    _generateChime(
      frequencies: [523.25, 659.25, 783.99, 1046.5],
      noteMs: 120,
      volume: 0.45,
    ),
  );

  File('assets/sounds/card_swipe.wav').writeAsBytesSync(
    _generateSwipeWhoosh(
      durationMs: 140,
      volume: 0.4,
    ),
  );

  print(
    'Generated assets/sounds/wheel_tick.wav, wheel_win.wav, card_swipe.wav',
  );
}

Uint8List _generateTone({
  required double frequency,
  required int durationMs,
  required double volume,
  bool decay = false,
}) {
  const sampleRate = 22050;
  final sampleCount = (sampleRate * durationMs / 1000).round();
  final samples = Int16List(sampleCount);

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final envelope = decay ? exp(-t * 80) : 1.0;
    final value = sin(2 * pi * frequency * t) * volume * envelope;
    samples[i] = (value * 32767).clamp(-32768, 32767).round();
  }

  return _wrapWav(samples, sampleRate);
}

Uint8List _generateChime({
  required List<double> frequencies,
  required int noteMs,
  required double volume,
}) {
  const sampleRate = 22050;
  final noteSamples = (sampleRate * noteMs / 1000).round();
  final totalSamples = noteSamples * frequencies.length;
  final samples = Int16List(totalSamples);

  for (var n = 0; n < frequencies.length; n++) {
    for (var i = 0; i < noteSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-t * 6);
      final value =
          sin(2 * pi * frequencies[n] * t) * volume * envelope;
      samples[n * noteSamples + i] =
          (value * 32767).clamp(-32768, 32767).round();
    }
  }

  return _wrapWav(samples, sampleRate);
}

Uint8List _generateSwipeWhoosh({
  required int durationMs,
  required double volume,
}) {
  const sampleRate = 22050;
  final sampleCount = (sampleRate * durationMs / 1000).round();
  final samples = Int16List(sampleCount);
  final random = Random(42);

  for (var i = 0; i < sampleCount; i++) {
    final t = i / sampleRate;
    final progress = i / sampleCount;
    // Noise + tone trượt xuống — giống tiếng quẹt thẻ.
    final freq = 900 - progress * 550;
    final envelope = sin(pi * progress) * exp(-progress * 2.2);
    final tone = sin(2 * pi * freq * t);
    final noise = (random.nextDouble() * 2 - 1) * 0.55;
    final value = (tone * 0.45 + noise * 0.55) * volume * envelope;
    samples[i] = (value * 32767).clamp(-32768, 32767).round();
  }

  return _wrapWav(samples, sampleRate);
}

Uint8List _wrapWav(Int16List samples, int sampleRate) {
  final byteData = ByteData(44 + samples.length * 2);
  byteData.setUint32(0, 0x52494646, Endian.big); // RIFF
  byteData.setUint32(4, 36 + samples.length * 2, Endian.little);
  byteData.setUint32(8, 0x57415645, Endian.big); // WAVE
  byteData.setUint32(12, 0x666d7420, Endian.big); // fmt
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little); // PCM
  byteData.setUint16(22, 1, Endian.little); // mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  byteData.setUint32(36, 0x64617461, Endian.big); // data
  byteData.setUint32(40, samples.length * 2, Endian.little);

  for (var i = 0; i < samples.length; i++) {
    byteData.setInt16(44 + i * 2, samples[i], Endian.little);
  }

  return byteData.buffer.asUint8List();
}
