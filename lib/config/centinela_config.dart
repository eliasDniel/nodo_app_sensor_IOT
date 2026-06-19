class CentinelaConfig {
  // --- Configuración de conexión dinámica (editable en runtime) ---
  static String connectionName = 'CENTINELA';
  /// Código registrado previamente en el Centro de Comando (identidad del nodo).
  static String codigoNodo = '';
  static double latitud = -0.2;
  static double longitud = -78.5;
  static String brokerHost = '192.168.1.27';
  static int brokerPort = 1883;

  // --- Topic unificado (audio + metadata en un solo mensaje JSON) ---
  static const topicEvent = 'centinela/evento';

  // --- Parámetros de audio (constantes de hardware) ---
  static const sampleRate = 16000;
  static const channels = 1;
  static const bitsPerSample = 16;
  static const bytesPerSample = bitsPerSample ~/ 8;

  static const preBufferSeconds = 1;  // fijo: audio previo al disparo

  /// Duración total del evento en segundos. Rango válido: 3–5.
  static int eventDurationSeconds = 4;

  static int get postBufferSeconds => eventDurationSeconds - preBufferSeconds;

  static int get preBufferBytes =>
      sampleRate * preBufferSeconds * bytesPerSample * channels;

  static int get postBufferBytes =>
      sampleRate * postBufferSeconds * bytesPerSample * channels;

  static int get totalEventSeconds => eventDurationSeconds;

  /// Umbral de detección en dB. Rango válido: 30–90 dB. Default: 60 dB.
  static double thresholdDb = 60.0;

  static const mqttRetryAttempts = 3;
  static const mqttRetryDelayMs = 2000;

  static const triggerCooldownMs = 300;
}
