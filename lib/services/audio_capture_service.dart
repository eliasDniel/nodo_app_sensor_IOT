import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../config/centinela_config.dart';
import '../models/audio_event.dart';
import 'circular_audio_buffer.dart';
import 'threshold_detector.dart';

typedef OnEventDetected = void Function(AudioEvent event);
typedef OnLevelUpdate = void Function(double db);
typedef OnLog = void Function(String message);

class _RecordingContext {
  _RecordingContext(this.event);

  final AudioEvent event;
  final BytesBuilder accumulator = BytesBuilder(copy: false);
}

class AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();
  final CircularAudioBuffer _buffer = CircularAudioBuffer(
    capacityBytes: CentinelaConfig.preBufferBytes,
  );
  final ThresholdDetector _detector = ThresholdDetector();

  StreamSubscription<Uint8List>? _subscription;
  bool _active = false;
  final List<_RecordingContext> _activeRecordings = [];
  DateTime? _lastTrigger;

  OnEventDetected? onEventDetected;
  OnLevelUpdate? onLevelUpdate;
  OnLog? onLog;

  bool get isActive => _active;

  Future<bool> start() async {
    if (_active) return true;
    if (!await _recorder.hasPermission()) return false;

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: CentinelaConfig.sampleRate,
        numChannels: CentinelaConfig.channels,
      ),
    );

    _active = true;
    _subscription = stream.listen(_onChunk);
    onLog?.call('Micrófono activo — monitoreo continuo iniciado');
    return true;
  }

  void _onChunk(Uint8List chunk) {
    if (!_active) return;

    _buffer.write(chunk);
    final db = _detector.measureDb(chunk);
    onLevelUpdate?.call(db);

    final completed = <_RecordingContext>[];
    for (final ctx in _activeRecordings) {
      ctx.accumulator.add(chunk);
      if (ctx.accumulator.length >= CentinelaConfig.postBufferBytes) {
        completed.add(ctx);
      }
    }

    for (final ctx in completed) {
      _finalizeRecording(ctx);
    }

    if (_detector.isTriggered(chunk)) {
      final now = DateTime.now();
      if (_lastTrigger == null ||
          now.difference(_lastTrigger!).inMilliseconds >
              CentinelaConfig.triggerCooldownMs) {
        _lastTrigger = now;
        _startRecording(db);
      }
    }
  }

  void _startRecording(double db) {
    final pre = _buffer.snapshotLastSeconds(
      sampleRate: CentinelaConfig.sampleRate,
      bytesPerSample: CentinelaConfig.bytesPerSample,
      seconds: CentinelaConfig.preBufferSeconds,
    );
    final event = AudioEvent.create(preBuffer: pre, levelDb: db);
    _activeRecordings.add(_RecordingContext(event));
    onLog?.call(
      'Evento detectado: ${event.id} (${db.toStringAsFixed(1)} dB)',
    );
  }

  void _finalizeRecording(_RecordingContext ctx) {
    final bytes = ctx.accumulator.toBytes();
    ctx.event.postBuffer = Uint8List.fromList(
      bytes.sublist(0, CentinelaConfig.postBufferBytes),
    );
    ctx.event.isComplete = true;
    _activeRecordings.remove(ctx);
    onEventDetected?.call(ctx.event);
  }

  Future<void> stop() async {
    _active = false;
    await _subscription?.cancel();
    _subscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    _activeRecordings.clear();
    _buffer.clear();
    _lastTrigger = null;
    onLog?.call('Micrófono detenido — colas de grabación canceladas');
  }
}
