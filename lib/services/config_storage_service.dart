import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/centinela_config.dart';

/// Persists and restores the MQTT connection settings to/from a local JSON file.
class ConfigStorageService {
  static const _fileName = 'centinela_config.json';

  Future<File> _configFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File(p.join(appDir.path, _fileName));
  }

  /// Saves the current [CentinelaConfig] dynamic fields to disk.
  Future<void> save({
    required String connectionName,
    required String codigoNodo,
    required double latitud,
    required double longitud,
    required String brokerHost,
    required int brokerPort,
    required int eventDurationSeconds,
    required double thresholdDb,
  }) async {
    final file = await _configFile();
    final data = {
      'connectionName': connectionName,
      'codigoNodo': codigoNodo,
      'latitud': latitud,
      'longitud': longitud,
      'brokerHost': brokerHost,
      'brokerPort': brokerPort,
      'eventDurationSeconds': eventDurationSeconds,
      'thresholdDb': thresholdDb,
    };
    await file.writeAsString(jsonEncode(data));
  }

  /// Loads saved settings from disk and applies them to [CentinelaConfig].
  /// Returns true if a saved config was found and loaded, false otherwise.
  Future<bool> load() async {
    try {
      final file = await _configFile();
      if (!file.existsSync()) return false;

      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;

      CentinelaConfig.connectionName =
          data['connectionName'] as String? ?? CentinelaConfig.connectionName;
      CentinelaConfig.codigoNodo = data['codigoNodo'] as String? ??
          data['clientId'] as String? ??
          CentinelaConfig.codigoNodo;
      CentinelaConfig.latitud =
          (data['latitud'] as num?)?.toDouble() ?? CentinelaConfig.latitud;
      CentinelaConfig.longitud =
          (data['longitud'] as num?)?.toDouble() ?? CentinelaConfig.longitud;
      CentinelaConfig.brokerHost =
          data['brokerHost'] as String? ?? CentinelaConfig.brokerHost;
      CentinelaConfig.brokerPort =
          (data['brokerPort'] as num?)?.toInt() ?? CentinelaConfig.brokerPort;
      CentinelaConfig.eventDurationSeconds =
          (data['eventDurationSeconds'] as num?)?.toInt() ??
              CentinelaConfig.eventDurationSeconds;
      CentinelaConfig.thresholdDb =
          (data['thresholdDb'] as num?)?.toDouble() ?? CentinelaConfig.thresholdDb;

      return true;
    } catch (_) {
      return false;
    }
  }
}
