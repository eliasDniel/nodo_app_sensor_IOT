import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/connection_status.dart';
import '../models/node_status.dart';
import '../services/audio_capture_service.dart';
import '../services/event_queue_service.dart';
import '../services/mqtt_service.dart';
import '../services/pending_storage_service.dart';

class CentinelaProvider extends ChangeNotifier {
  final MqttService mqtt = MqttService();
  final AudioCaptureService audio = AudioCaptureService();
  final PendingStorageService storage = PendingStorageService();
  late final EventQueueService queue = EventQueueService(mqtt, storage);

  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;
  NodeStatus nodeStatus = NodeStatus.inactive;
  MicStatus micStatus = MicStatus.off;
  int eventCount = 0;
  double currentDb = 0;
  final List<String> logs = [];

  CentinelaProvider() {
    mqtt.onConnectionChanged = (status) {
      connectionStatus = status;
      if (status == ConnectionStatus.connected) {
        queue.flushPending(onLog: _addLog);
      }
      notifyListeners();
    };
    mqtt.onLog = _addLog;

    audio.onLog = _addLog;
    audio.onLevelUpdate = (db) {
      currentDb = db;
      notifyListeners();
    };
    audio.onEventDetected = (event) {
      eventCount++;
      queue.enqueue(event, onLog: _addLog);
      notifyListeners();
    };
  }

  Future<void> init() async {
    _addLog('Iniciando conexión MQTT...');
    await mqtt.connect();
    notifyListeners();
  }

  Future<void> encenderNodo() async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      micStatus = MicStatus.error;
      _addLog('Permiso de micrófono denegado');
      notifyListeners();
      return;
    }

    final started = await audio.start();
    if (started) {
      nodeStatus = NodeStatus.active;
      micStatus = MicStatus.listening;
      _addLog('Nodo encendido');
    } else {
      micStatus = MicStatus.error;
      _addLog('No se pudo iniciar el micrófono');
    }
    notifyListeners();
  }

  Future<void> apagarNodo() async {
    await audio.stop();
    queue.clear();
    nodeStatus = NodeStatus.inactive;
    micStatus = MicStatus.off;
    currentDb = 0;
    _addLog('Nodo apagado');
    notifyListeners();
  }

  void _addLog(String message) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    logs.insert(0, '[$time] $message');
    if (logs.length > 100) {
      logs.removeLast();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    audio.stop();
    mqtt.disconnect();
    super.dispose();
  }
}
