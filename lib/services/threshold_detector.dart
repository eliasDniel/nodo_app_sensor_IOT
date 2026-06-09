import 'dart:math';
import 'dart:typed_data';

import '../config/centinela_config.dart';

class ThresholdDetector {
  double measureDb(Uint8List pcm16Le) {
    if (pcm16Le.length < 2) return 0;

    // Stream chunks may be views with unaligned byte offsets.
    final Uint8List bytes = pcm16Le.offsetInBytes.isOdd
        ? Uint8List.fromList(pcm16Le)
        : pcm16Le;
    final evenLength = bytes.length & ~1;
    if (evenLength < 2) return 0;

    final samples = bytes.buffer.asInt16List(
      bytes.offsetInBytes,
      evenLength ~/ 2,
    );

    double sum = 0;
    for (final sample in samples) {
      sum += sample * sample;
    }

    final rms = sqrt(sum / samples.length);
    if (rms <= 0) return 0;

    const maxAmp = 32768.0;
    final dbfs = 20 * log(rms / maxAmp) / ln10;
    return 100 + dbfs;
  }

  bool isTriggered(Uint8List chunk) =>
      measureDb(chunk) >= CentinelaConfig.thresholdDb;
}
