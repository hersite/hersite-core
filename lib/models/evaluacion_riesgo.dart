import 'dart:convert';

class EvaluacionRiesgo {
  final String idLocal;
  final int perfilId;
  final String fechaHora;
  final Map<String, dynamic> formData;
  final List<String> sintomasDetectados;
  final String nivelRiesgo;
  final String mensaje;
  final dynamic probabilidades;
  final String syncStatus;

  final String? serverId;
  final String? syncedAt;
  final int syncAttempts;
  final String? lastSyncError;

  const EvaluacionRiesgo({
    required this.idLocal,
    required this.perfilId,
    required this.fechaHora,
    required this.formData,
    required this.sintomasDetectados,
    required this.nivelRiesgo,
    required this.mensaje,
    required this.probabilidades,
    required this.syncStatus,
    this.serverId,
    this.syncedAt,
    this.syncAttempts = 0,
    this.lastSyncError,
  });

  Map<String, dynamic> toMapDb() {
    return {
      'id_local': idLocal,
      'perfil_id': perfilId,
      'fecha_hora': fechaHora,
      'form_data_json': jsonEncode(formData),
      'sintomas_detectados_json': jsonEncode(sintomasDetectados),
      'nivel_riesgo': nivelRiesgo,
      'mensaje': mensaje,
      'probabilidades_json': jsonEncode(probabilidades),
      'sync_status': syncStatus,
      'server_id': serverId,
      'synced_at': syncedAt,
      'sync_attempts': syncAttempts,
      'last_sync_error': lastSyncError,
      'created_at': fechaHora,
    };
  }

  factory EvaluacionRiesgo.fromMapDb(Map<String, dynamic> map) {
    return EvaluacionRiesgo(
      idLocal: map['id_local'] as String,
      perfilId: map['perfil_id'] as int? ?? 0,
      fechaHora: map['fecha_hora'] as String,
      formData: jsonDecode(map['form_data_json'] as String) as Map<String, dynamic>,
      sintomasDetectados: List<String>.from(
        jsonDecode(map['sintomas_detectados_json'] as String),
      ),
      nivelRiesgo: map['nivel_riesgo'] as String,
      mensaje: map['mensaje'] as String,
      probabilidades: map['probabilidades_json'] == null
          ? null
          : jsonDecode(map['probabilidades_json'] as String),
      syncStatus: map['sync_status'] as String,
    );
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'id_local': idLocal,
      'perfil_id_local': perfilId,
      'fecha_hora': fechaHora,
      'form_data': formData,
      'sintomas_detectados': sintomasDetectados,
      'nivel_riesgo': nivelRiesgo,
      'mensaje': mensaje,
      'probabilidades': probabilidades,
      'sync_status_local': syncStatus,
      'origen': 'flutter_offline',
    };
  }
}