import 'dart:typed_data';

import 'package:uuid/uuid.dart';

class AudioEvent {
  AudioEvent({
    required this.id,
    required this.timestampMs,
    required this.detectedLevelDb,
    required this.preBuffer,
    Uint8List? postBuffer,
    this.isComplete = false,
  }) : postBuffer = postBuffer ?? Uint8List(0);

  final String id;
  final int timestampMs;
  final double detectedLevelDb;
  final Uint8List preBuffer;
  Uint8List postBuffer;
  bool isComplete;

  factory AudioEvent.create({
    required Uint8List preBuffer,
    required double levelDb,
  }) {
    return AudioEvent(
      id: const Uuid().v4(),
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      detectedLevelDb: levelDb,
      preBuffer: preBuffer,
    );
  }

  Uint8List get fullPcm => Uint8List.fromList([...preBuffer, ...postBuffer]);
}
