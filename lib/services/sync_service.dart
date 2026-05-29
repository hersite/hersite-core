import 'package:flutter/foundation.dart';

import '../database/local_database.dart';

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
          // ============================================================
          // SIMULACIÓN DE ENVÍO A SERVIDOR
          // ============================================================
          // Más adelante, aquí irá el POST real hacia FastAPI.
          // Por ahora se simula una pequeña espera para representar
          // el envío de datos cuando exista conexión.
          await Future.delayed(const Duration(milliseconds: 350));

          await LocalDatabase.instance.marcarComoSincronizada(
            evaluacion.idLocal,
          );

          sincronizadas++;

          debugPrint(
            'Evaluación sincronizada: ${evaluacion.idLocal}',
          );
        } catch (e) {
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