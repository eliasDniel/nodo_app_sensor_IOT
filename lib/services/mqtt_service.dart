import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' as typed;

import '../config/centinela_config.dart';
import '../models/connection_status.dart';
import '../models/metadata_payload.dart';

typedef OnConnectionChanged = void Function(ConnectionStatus status);
typedef OnLog = void Function(String message);

class MqttService {
  MqttServerClient? _client;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  OnConnectionChanged? onConnectionChanged;
  OnLog? onLog;

  ConnectionStatus get status => _status;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    _client?.disconnect();

    final client = MqttServerClient.withPort(
      CentinelaConfig.brokerHost,
      CentinelaConfig.clientId,
      CentinelaConfig.brokerPort,
    );
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.onAutoReconnect = _onReconnecting;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    _client = client;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(CentinelaConfig.clientId)
        .startClean();

    client.connectionMessage = connMessage;
    _setStatus(ConnectionStatus.reconnecting);

    try {
      await client.connect();
    } catch (e) {
      _setStatus(ConnectionStatus.disconnected);
      onLog?.call('Error MQTT: $e');
    }
  }

  void _onConnected() {
    _setStatus(ConnectionStatus.connected);
    onLog?.call(
      'MQTT conectado a ${CentinelaConfig.brokerHost}:${CentinelaConfig.brokerPort}',
    );
  }

  void _onDisconnected() {
    if (_status != ConnectionStatus.reconnecting) {
      _setStatus(ConnectionStatus.disconnected);
      onLog?.call('MQTT desconectado');
    }
  }

  void _onReconnecting() {
    _setStatus(ConnectionStatus.reconnecting);
    onLog?.call('MQTT reconectando...');
  }

  void _setStatus(ConnectionStatus status) {
    _status = status;
    onConnectionChanged?.call(status);
  }

  Future<bool> publishEvent({
    required Uint8List wavBytes,
    required MetadataPayload meta,
  }) async {
    if (!isConnected || _client == null) return false;

    for (var attempt = 1; attempt <= CentinelaConfig.mqttRetryAttempts; attempt++) {
      try {
        final metaBuilder = MqttClientPayloadBuilder();
        metaBuilder.addString(jsonEncode(meta.toJson()));
        _client!.publishMessage(
          CentinelaConfig.topicMeta,
          MqttQos.atLeastOnce,
          metaBuilder.payload!,
        );

        final audioBuffer = typed.Uint8Buffer()..addAll(wavBytes);
        final audioBuilder = MqttClientPayloadBuilder()..addBuffer(audioBuffer);
        _client!.publishMessage(
          CentinelaConfig.topicAudio,
          MqttQos.atLeastOnce,
          audioBuilder.payload!,
        );

        onLog?.call('Publicado evento ${meta.eventoId}');
        return true;
      } catch (e) {
        onLog?.call('Reintento $attempt/${CentinelaConfig.mqttRetryAttempts}: $e');
        if (attempt < CentinelaConfig.mqttRetryAttempts) {
          await Future<void>.delayed(
            const Duration(milliseconds: CentinelaConfig.mqttRetryDelayMs),
          );
        }
      }
    }
    return false;
  }

  void disconnect() {
    _client?.disconnect();
    _setStatus(ConnectionStatus.disconnected);
  }
}
