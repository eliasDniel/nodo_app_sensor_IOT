import '../config/centinela_config.dart';

class MetadataPayload {
  MetadataPayload({
    required this.codigoNodo,
    required this.latitud,
    required this.longitud,
    required this.timestamp,
    required this.duracion,
    required this.eventoId,
    required this.nivelAudio,
  });

  final String codigoNodo;
  final double latitud;
  final double longitud;
  final int timestamp;
  final int duracion;
  final String eventoId;
  final double nivelAudio;

  factory MetadataPayload.fromJson(Map<String, dynamic> json) {
    return MetadataPayload(
      codigoNodo: (json['codigo_nodo'] ?? json['nodo_id']) as String,
      latitud: (json['latitud'] as num?)?.toDouble() ?? CentinelaConfig.latitud,
      longitud: (json['longitud'] as num?)?.toDouble() ?? CentinelaConfig.longitud,
      timestamp: json['timestamp'] as int,
      duracion: json['duracion'] as int,
      eventoId: json['evento_id'] as String,
      nivelAudio: (json['nivel_audio'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo_nodo': codigoNodo,
        'latitud': latitud,
        'longitud': longitud,
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
      codigoNodo: CentinelaConfig.codigoNodo,
      latitud: CentinelaConfig.latitud,
      longitud: CentinelaConfig.longitud,
      timestamp: timestamp,
      duracion: CentinelaConfig.totalEventSeconds,
      eventoId: eventoId,
      nivelAudio: nivelAudio,
    );
  }
}
