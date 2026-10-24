import 'package:flutter/foundation.dart';
import '../database/local_database.dart';
import 'api_client.dart';
import 'session_state_service.dart';

enum FaseSync { comprobando, desconectado, pendiente, enviando, alDia, error }

class EstadoSync {
  final FaseSync fase;
  final int pendientes;
  final String? detalle;
  const EstadoSync(this.fase, {this.pendientes = 0, this.detalle});
  String get texto => switch (fase) {
    FaseSync.comprobando => 'Comprobando conexión',
    FaseSync.desconectado => 'Sin conexión al servidor',
    FaseSync.pendiente => '$pendientes registro(s) pendiente(s)',
    FaseSync.enviando => 'Sincronizando…',
    FaseSync.alDia => 'Sincronizado',
    FaseSync.error => 'Error de sincronización',
  };
}

class SyncService {
  SyncService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  static final instance = SyncService();
  final ApiClient _api;
  final estado = ValueNotifier(const EstadoSync(FaseSync.comprobando));
  bool _sincronizando = false;

  Future<int> sincronizarEvaluacionesPendientesDelPerfilActivo() async {
    if (_sincronizando) return 0;
    final generation = SessionStateService.instance.generation;
    final id = await SessionStateService.instance.getActiveProfileId();
    if (id == null || await SessionStateService.instance.isSessionClosed()) {
      return 0;
    }
    _sincronizando = true;
    var enviadas = 0;
    var huboErrores = false;
    String? error;
    bool vigente() => generation == SessionStateService.instance.generation;
    try {
      if (!vigente()) return 0;
      estado.value = const EstadoSync(FaseSync.enviando);
      if (await LocalDatabase.instance.perfilPendiente(id)) {
        final perfil = await LocalDatabase.instance.obtenerPerfilPorId(id);
        if (perfil == null || !vigente()) return 0;
        final response = await _api.enviarPerfil(perfil);
        if (!response.ok) {
          await LocalDatabase.instance.registrarErrorPerfil(
            id,
            response.message,
          );
          throw StateError(response.message);
        }
        await LocalDatabase.instance.confirmarPerfilSincronizado(
          id,
          perfil.actualizadoEn!,
        );
      }
      final pendientes = await LocalDatabase.instance
          .listarEvaluacionesPendientesPorPerfil(id);
      for (final evaluacion in pendientes) {
        if (!vigente()) break;
        try {
          final response = await _api.enviarEvaluacionRiesgo(evaluacion);
          if (!response.ok) throw StateError(response.message);
          await LocalDatabase.instance.marcarComoSincronizada(
            evaluacion.idLocal,
            serverId: response.serverId,
          );
          enviadas++;
        } catch (failure) {
          huboErrores = true;
          error = failure is StateError
              ? failure.message
              : 'No se pudo enviar una evaluación.';
          await LocalDatabase.instance.registrarErrorSincronizacion(
            evaluacion.idLocal,
            error,
          );
        }
      }
    } catch (failure) {
      huboErrores = true;
      error = failure is StateError
          ? failure.message
          : 'No se pudo completar la sincronización.';
    } finally {
      _sincronizando = false;
      if (vigente()) {
        final pendientes = await LocalDatabase.instance.contarPendientes(id);
        estado.value = EstadoSync(
          huboErrores
              ? FaseSync.error
              : pendientes == 0
              ? FaseSync.alDia
              : FaseSync.pendiente,
          pendientes: pendientes,
          detalle: error,
        );
      }
    }
    return enviadas;
  }
}
