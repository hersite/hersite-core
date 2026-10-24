import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'api_client.dart';
import 'session_state_service.dart';
import 'sync_service.dart';

class ConnectivitySyncService with WidgetsBindingObserver {
  ConnectivitySyncService._internal();
  static final instance = ConnectivitySyncService._internal();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retry;
  bool _started = false;
  bool _running = false;

  Future<void> start() async {
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addObserver(this);
      _subscription = Connectivity().onConnectivityChanged.listen((_) {
        unawaited(trySyncNow(reason: 'cambio de red'));
      }, onError: (Object _) {});
      _retry = Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(trySyncNow(reason: 'reintento'));
      });
    }
    unawaited(trySyncNow(reason: 'sesión iniciada'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started) {
      unawaited(trySyncNow(reason: 'app reanudada'));
    }
  }

  Future<int> trySyncNow({String reason = 'manual'}) async {
    if (_running) return 0;
    _running = true;
    final generation = SessionStateService.instance.generation;
    try {
      if (await SessionStateService.instance.isSessionClosed()) return 0;
      final id = await SessionStateService.instance.getActiveProfileId();
      if (id == null) return 0;
      // Comprueba el servidor real, también cuando está en una red local sin internet público.
      final connected = await ApiClient.instance.comprobarConexion();
      if (generation != SessionStateService.instance.generation) return 0;
      if (!connected) {
        SyncService.instance.estado.value = const EstadoSync(
          FaseSync.desconectado,
        );
        return 0;
      }
      return await SyncService.instance
          .sincronizarEvaluacionesPendientesDelPerfilActivo();
    } catch (_) {
      if (generation == SessionStateService.instance.generation) {
        SyncService.instance.estado.value = const EstadoSync(
          FaseSync.error,
          detalle:
              'No se pudo completar la sincronización. Los datos siguen guardados.',
        );
      }
      return 0;
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() async {
    _started = false;
    _retry?.cancel();
    _retry = null;
    await _subscription?.cancel();
    _subscription = null;
    WidgetsBinding.instance.removeObserver(this);
    SyncService.instance.estado.value = const EstadoSync(FaseSync.comprobando);
  }
}
