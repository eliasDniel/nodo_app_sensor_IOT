import 'dart:typed_data';

class CircularAudioBuffer {
  CircularAudioBuffer({required this.capacityBytes});

  final int capacityBytes;
  final BytesBuilder _builder = BytesBuilder(copy: false);
  int _length = 0;

  void write(Uint8List chunk) {
    _builder.add(chunk);
    _length += chunk.length;
    if (_length > capacityBytes) {
      final excess = _length - capacityBytes;
      final all = _builder.toBytes();
      _builder.clear();
      _builder.add(all.sublist(excess));
      _length = capacityBytes;
    }
  }

  Uint8List snapshotLastSeconds({
    required int sampleRate,
    required int bytesPerSample,
    required int seconds,
  }) {
    final needed = sampleRate * bytesPerSample * seconds;
    final all = _builder.toBytes();
    if (all.length <= needed) return Uint8List.fromList(all);
    return Uint8List.fromList(all.sublist(all.length - needed));
  }

  void clear() {
    _builder.clear();
    _length = 0;
  }
}
