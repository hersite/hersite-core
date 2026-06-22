import 'package:flutter/foundation.dart';

import '../database/local_database.dart';
import 'api_client.dart';

class SyncService {
  SyncService._internal();

  static final SyncService instance = SyncService._internal();

  bool _sincronizando = false;

  Future<int> sincronizarEvaluacionesPendientesDelPerfilActivo() async {
    if (_sincronizando) {
      debugPrint('Sincronización ignorada: ya hay una sincronización en curso.');
      return 0;
    }

    _sincronizando = true;

    try {
      final pendientes =
          await LocalDatabase.instance.listarEvaluacionesPendientesDelPerfilActivo();

      if (pendientes.isEmpty) {
        debugPrint('No hay evaluaciones pendientes para sincronizar.');
        return 0;
      }

      debugPrint('Evaluaciones pendientes encontradas: ${pendientes.length}');

      var sincronizadas = 0;

      for (final evaluacion in pendientes) {
        try {
          final respuesta =
              await ApiClient.instance.enviarEvaluacionRiesgo(evaluacion);

          if (!respuesta.ok) {
            throw Exception(respuesta.message);
          }

          await LocalDatabase.instance.marcarComoSincronizada(
            evaluacion.idLocal,
            serverId: respuesta.serverId,
          );

          sincronizadas++;

          debugPrint(
            'Evaluación sincronizada: ${evaluacion.idLocal} | serverId: ${respuesta.serverId}',
          );
        } catch (e) {
          await LocalDatabase.instance.registrarErrorSincronizacion(
            evaluacion.idLocal,
            e.toString(),
          );

          debugPrint(
            'Error sincronizando evaluación ${evaluacion.idLocal}: $e',
          );
        }
      }

      debugPrint('Total sincronizadas: $sincronizadas');

      return sincronizadas;
    } finally {
      _sincronizando = false;
    }
  }
}