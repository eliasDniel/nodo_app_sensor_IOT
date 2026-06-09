class CentinelaConfig {
  static const connectionName = 'CENTINELA';
  static const clientId = 'nodo_audio_001';
  static const brokerHost = '192.168.1.3';
  static const brokerPort = 1883;
  static const topicAudio = 'centinela/audio';
  static const topicMeta = 'centinela/meta';

  static const sampleRate = 16000;
  static const channels = 1;
  static const bitsPerSample = 16;
  static const bytesPerSample = bitsPerSample ~/ 8;

  static const preBufferSeconds = 2;
  static const postBufferSeconds = 4;

  static int get preBufferBytes =>
      sampleRate * preBufferSeconds * bytesPerSample * channels;

  static int get postBufferBytes =>
      sampleRate * postBufferSeconds * bytesPerSample * channels;

  static int get totalEventSeconds => preBufferSeconds + postBufferSeconds;

  /// Umbral aproximado ~60 dB (calibrar en campo si es necesario).
  static const thresholdDb = 60.0;

  static const mqttRetryAttempts = 3;
  static const mqttRetryDelayMs = 2000;

  static const triggerCooldownMs = 300;
}
