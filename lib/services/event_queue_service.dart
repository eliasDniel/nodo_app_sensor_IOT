import 'dart:collection';
import 'dart:typed_data';

import '../models/audio_event.dart';
import '../models/metadata_payload.dart';
import 'mqtt_service.dart';
import 'pending_storage_service.dart';
import 'wav_encoder.dart';

typedef OnLog = void Function(String message);

class _QueuedItem {
  _QueuedItem({required this.wav, required this.meta});

  final Uint8List wav;
  final MetadataPayload meta;
}

class EventQueueService {
  EventQueueService(this._mqtt, this._storage);

  final MqttService _mqtt;
  final PendingStorageService _storage;
  final Queue<_QueuedItem> _queue = Queue();
  bool _processing = false;

  int get pendingCount => _queue.length;

  void enqueue(AudioEvent event, {OnLog? onLog}) {
    final wav = WavEncoder.encodePcm16(event.fullPcm);
    final meta = MetadataPayload.fromEvent(
      eventoId: event.id,
      timestamp: event.timestampMs,
      nivelAudio: event.detectedLevelDb,
    );
    _queue.add(_QueuedItem(wav: wav, meta: meta));
    onLog?.call('En cola: ${event.id} (pendientes: ${_queue.length})');
    _processQueue(onLog: onLog);
  }

  Future<void> _processQueue({OnLog? onLog}) async {
    if (_processing) return;
    _processing = true;

    while (_queue.isNotEmpty) {
      final item = _queue.first;
      final ok = await _mqtt.publishEvent(
        wavBytes: item.wav,
        meta: item.meta,
      );

      if (ok) {
        _queue.removeFirst();
        onLog?.call('Enviado: ${item.meta.eventoId}');
      } else {
        await _storage.save(wavBytes: item.wav, meta: item.meta);
        _queue.removeFirst();
        onLog?.call('Broker offline, guardado local: ${item.meta.eventoId}');
      }
    }

    _processing = false;
  }

  Future<void> flushPending({OnLog? onLog}) async {
    final pending = await _storage.loadAll();
    for (final item in pending) {
      final ok = await _mqtt.publishEvent(
        wavBytes: item.wav,
        meta: item.meta,
      );
      if (ok) {
        await _storage.delete(item.meta.eventoId);
        onLog?.call('Reenviado desde disco: ${item.meta.eventoId}');
      } else {
        onLog?.call('No se pudo reenviar: ${item.meta.eventoId}');
        break;
      }
    }
  }

  void clear() => _queue.clear();
}
