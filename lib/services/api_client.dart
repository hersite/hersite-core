import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../database/local_database.dart';
import '../models/evaluacion_riesgo.dart';
import '../models/perfil_gestante.dart';
import 'api_config.dart';
import 'pin_security_service.dart';
import 'session_state_service.dart';

class ApiSyncResponse {
  final bool ok;
  final String serverId;
  final String message;
  final int statusCode;
  final Map<String, dynamic> data;
  const ApiSyncResponse({
    required this.ok,
    required this.serverId,
    required this.message,
    this.statusCode = 0,
    this.data = const {},
  });
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  static final instance = ApiClient();
  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  final _claves = <int, Future<String>>{};
  final requiereRecuperacion = ValueNotifier<int?>(null);

  Map<String, dynamic> _perfilPayload(PerfilGestante perfil) => {
    ...(perfil.toMapDb()
      ..removeWhere((key, _) => key == 'pin_hash' || key == 'pin_salt')),
    'edad_materna': perfil.edadActual,
    'actualizado_en': perfil.actualizadoEn,
  };

  Future<void> _verificarCuenta(int id, int generation) async {
    final closed = await SessionStateService.instance.isSessionClosed();
    final active = await SessionStateService.instance.getActiveProfileId();
    if (SessionStateService.instance.generation != generation ||
        closed ||
        active != id) {
      throw StateError('La cuenta cambió. Se detuvo la sincronización.');
    }
  }

  Future<String> _clave(int id) async {
    final pending = _claves.putIfAbsent(id, () => _leerOCrearClave(id));
    try {
      return await pending;
    } catch (_) {
      if (identical(_claves[id], pending)) _claves.remove(id);
      rethrow;
    }
  }

  Future<String> _leerOCrearClave(int id) async {
    final key = _claveStorage(id);
    var secret = await _storage.read(key: key);
    if (secret == null) {
      secret = PinSecurityService.instance.generateSalt().replaceAll('=', '');
      await _storage.write(key: key, value: secret);
    }
    return secret;
  }

  String _claveStorage(int id) =>
      'sync_key_${sha256.convert(utf8.encode(ApiConfig.baseUrl))}_$id';

  Future<void> guardarClaveRecuperada(int id, String secret) async {
    // Espera cualquier creación anterior para que no sobrescriba la clave nueva.
    final anterior = _claves[id];
    if (anterior != null) {
      try {
        await anterior;
      } catch (_) {
        /* Se reemplaza por la recuperada. */
      }
    }
    await _storage.write(key: _claveStorage(id), value: secret);
    if (await _storage.read(key: _claveStorage(id)) != secret) {
      throw StateError(
        'No pudimos guardar tu cuenta en este teléfono. Inténtalo otra vez.',
      );
    }
    _claves[id] = Future.value(secret);
    requiereRecuperacion.value = null;
  }

  Future<ApiSyncResponse> _post(
    String path,
    Map<String, dynamic> data, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await _client
          .post(
            ApiConfig.uri(path),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ...headers,
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 12));
      final decoded = jsonDecode(response.body);
      final body = decoded is Map ? decoded : <String, dynamic>{};
      final ok =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['ok'] == true;
      final detail = body['detail'];
      return ApiSyncResponse(
        ok: ok,
        serverId: '${body['server_id'] ?? ''}',
        statusCode: response.statusCode,
        data: Map<String, dynamic>.from(body),
        message: ok
            ? '${body['message'] ?? 'Recibido'}'
            : detail is String
            ? detail
            : response.statusCode == 422
            ? 'Revisa que tus datos estén completos.'
            : response.statusCode == 429
            ? 'Has intentado varias veces. Espera 15 minutos y vuelve a intentar.'
            : 'No se pudo enviar el registro.',
      );
    } catch (error) {
      return ApiSyncResponse(
        ok: false,
        serverId: '',
        message: error is StateError
            ? error.message
            : 'No pudimos conectar. Tus datos siguen guardados en este teléfono.',
      );
    }
  }

  Future<bool> comprobarConexion() async {
    try {
      final result = await _client
          .get(ApiConfig.uri('/health'))
          .timeout(const Duration(seconds: 3));
      if (result.statusCode != 200) return false;
      final data = jsonDecode(result.body);
      return data is Map &&
          data['status'] == 'ok' &&
          data['service'] == 'riesgo-materno-api';
    } catch (_) {
      return false;
    }
  }

  Future<ApiSyncResponse> vincularPerfil(int perfilId, {String? codigo}) async {
    final generation = SessionStateService.instance.generation;
    await _verificarCuenta(perfilId, generation);
    final perfil = await LocalDatabase.instance.obtenerPerfilPorId(perfilId);
    if (perfil == null) throw StateError('No se encontró la cuenta.');
    final secret = await _clave(perfilId);
    await _verificarCuenta(perfilId, generation);
    final result = await _post('/api/mobile/registro', {
      'perfil': _perfilPayload(perfil),
      'sync_key': secret,
      if (perfil.pinHash.startsWith('pbkdf2_sha256\$600000\$'))
        'recovery_pin': {'hash': perfil.pinHash, 'salt': perfil.pinSalt},
      if (codigo != null) 'codigo_vinculacion': codigo.trim(),
    });
    await _verificarCuenta(perfilId, generation);
    if (result.statusCode == 409 && result.message.contains('PIN')) {
      requiereRecuperacion.value = perfilId;
    } else if (result.ok && requiereRecuperacion.value == perfilId) {
      requiereRecuperacion.value = null;
    }
    return result;
  }

  Future<ApiSyncResponse> solicitarRecuperacion(String dni, String pin) =>
      _post('/api/mobile/recuperar', {'dni': dni, 'pin': pin});

  Future<ApiSyncResponse> confirmarRecuperacion(String token, String secret) =>
      _post('/api/mobile/confirmar-recuperacion', {
        'token': token,
        'sync_key': secret,
      });

  Future<ApiSyncResponse> respaldarRecordatorios(
    int id,
    Map<String, dynamic> copia,
  ) async {
    final generation = SessionStateService.instance.generation;
    final perfil = await LocalDatabase.instance.obtenerPerfilPorId(id);
    final secret = await _clave(id);
    await _verificarCuenta(id, generation);
    final headers = {
      'Authorization': 'Bearer $secret',
      'X-Profile-DNI': perfil!.dni,
    };
    var result = await _post(
      '/api/mobile/recordatorios',
      copia,
      headers: headers,
    );
    if (result.statusCode == 409 && result.data['version'] is int) {
      // Un corte puede perder la confirmación de la copia anterior. Solo hay un
      // teléfono autorizado y SyncService serializa las copias: reintenta una vez
      // con la revisión que confirmó el servicio, sin pedir recuperar la cuenta.
      await _verificarCuenta(id, generation);
      result = await _post('/api/mobile/recordatorios', {
        ...copia,
        'base_version': result.data['version'],
      }, headers: headers);
    }
    return result;
  }

  Future<void> cambiarPin(
    int id,
    String actual,
    String hash,
    String salt,
  ) async {
    final generation = SessionStateService.instance.generation;
    final linked = await vincularPerfil(id);
    if (!linked.ok) throw StateError(linked.message);
    final perfil = await LocalDatabase.instance.obtenerPerfilPorId(id);
    final secret = await _clave(id);
    await _verificarCuenta(id, generation);
    final result = await _post(
      '/api/mobile/cambiar-pin',
      {
        'actual': actual,
        'nuevo': {'hash': hash, 'salt': salt},
      },
      headers: {
        'Authorization': 'Bearer $secret',
        'X-Profile-DNI': perfil!.dni,
      },
    );
    await _verificarCuenta(id, generation);
    if (!result.ok) {
      throw StateError(
        result.statusCode == 0
            ? 'Conéctate a internet para cambiar tu PIN.'
            : result.message,
      );
    }
  }

  Future<ApiSyncResponse> enviarPerfil(PerfilGestante perfil) async {
    if (perfil.id == null) {
      throw StateError('El perfil debe estar guardado antes de enviarlo.');
    }
    final generation = SessionStateService.instance.generation;
    await _verificarCuenta(perfil.id!, generation);
    final secret = await _clave(perfil.id!);
    final link = await vincularPerfil(perfil.id!);
    if (!link.ok) return link;
    await _verificarCuenta(perfil.id!, generation);
    return _post(
      '/api/perfiles',
      _perfilPayload(perfil),
      headers: {'Authorization': 'Bearer $secret', 'X-Profile-DNI': perfil.dni},
    );
  }

  Future<ApiSyncResponse> enviarEvaluacionRiesgo(
    EvaluacionRiesgo evaluacion,
  ) async {
    final generation = SessionStateService.instance.generation;
    await _verificarCuenta(evaluacion.perfilId, generation);
    // Nunca se usa aquí un perfil distinto del propietario del registro.
    final perfil = await LocalDatabase.instance.obtenerPerfilPorId(
      evaluacion.perfilId,
    );
    if (perfil == null) {
      throw StateError('No se encontró el propietario de la evaluación.');
    }
    final secret = await _clave(evaluacion.perfilId);
    await _verificarCuenta(evaluacion.perfilId, generation);
    return _post(
      '/api/evaluaciones',
      {...evaluacion.toApiPayload(), 'perfil': _perfilPayload(perfil)},
      headers: {'Authorization': 'Bearer $secret', 'X-Profile-DNI': perfil.dni},
    );
  }
}
