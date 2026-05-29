import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'session_state_service.dart';
import 'sync_service.dart';

class ConnectivitySyncService {
  ConnectivitySyncService._internal();

  static final ConnectivitySyncService instance =
      ConnectivitySyncService._internal();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _started = false;
  bool _syncRunning = false;

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        debugPrint('Error escuchando conectividad: $error');
      },
    );

    // Intenta sincronizar al iniciar la app.
    // No bloquea el arranque visual de Flutter.
    unawaited(
      trySyncNow(reason: 'inicio de app'),
    );

    debugPrint('ConnectivitySyncService iniciado.');
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    debugPrint('Cambio de conectividad detectado: $results');

    final hayConexionBasica = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hayConexionBasica) {
      debugPrint('Sin conexión básica. No se intenta sincronizar.');
      return;
    }

    unawaited(
      trySyncNow(reason: 'cambio de conectividad'),
    );
  }

  Future<int> trySyncNow({String reason = 'manual'}) async {
    if (_syncRunning) {
      debugPrint('Sync ignorado por "$reason": ya hay uno en curso.');
      return 0;
    }

    _syncRunning = true;

    try {
      final sessionClosed =
          await SessionStateService.instance.isSessionClosed();

      if (sessionClosed) {
        debugPrint('Sync omitido por "$reason": la sesión está cerrada.');
        return 0;
      }

      final activeProfileId =
          await SessionStateService.instance.getActiveProfileId();

      if (activeProfileId == null) {
        debugPrint('Sync omitido por "$reason": no hay perfil activo.');
        return 0;
      }

      final tieneInternetReal = await InternetConnection().hasInternetAccess;

      if (!tieneInternetReal) {
        debugPrint(
          'Sync omitido por "$reason": hay red, pero no internet real.',
        );
        return 0;
      }

      debugPrint('Sync iniciado por "$reason". Perfil activo: $activeProfileId');

      final sincronizadas =
          await SyncService.instance.sincronizarEvaluacionesPendientesDelPerfilActivo();

      debugPrint(
        'Sync finalizado por "$reason". Evaluaciones sincronizadas: $sincronizadas',
      );

      return sincronizadas;
    } catch (e) {
      debugPrint('Error general en trySyncNow por "$reason": $e');
      return 0;
    } finally {
      _syncRunning = false;
    }
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _started = false;
  }
}