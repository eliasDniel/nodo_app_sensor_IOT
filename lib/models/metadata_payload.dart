import '../config/centinela_config.dart';

class MetadataPayload {
  MetadataPayload({
    required this.nodoId,
    required this.timestamp,
    required this.duracion,
    required this.eventoId,
    required this.nivelAudio,
  });

  final String nodoId;
  final int timestamp;
  final int duracion;
  final String eventoId;
  final double nivelAudio;

  factory MetadataPayload.fromJson(Map<String, dynamic> json) {
    return MetadataPayload(
      nodoId: json['nodo_id'] as String,
      timestamp: json['timestamp'] as int,
      duracion: json['duracion'] as int,
      eventoId: json['evento_id'] as String,
      nivelAudio: (json['nivel_audio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nodo_id': nodoId,
        'timestamp': timestamp,
        'duracion': duracion,
        'evento_id': eventoId,
        'nivel_audio': nivelAudio,
      };

  factory MetadataPayload.fromEvent({
    required String eventoId,
    required int timestamp,
    required double nivelAudio,
  }) {
    return MetadataPayload(
      nodoId: CentinelaConfig.clientId,
      timestamp: timestamp,
      duracion: CentinelaConfig.totalEventSeconds,
      eventoId: eventoId,
      nivelAudio: nivelAudio,
    );
  }
}
