import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  const ApiSyncResponse({
    required this.ok,
    required this.serverId,
    required this.message,
    this.statusCode = 0,
  });
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  static final instance = ApiClient();
  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  final _claves = <int, Future<String>>{};

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
    final origin = sha256.convert(utf8.encode(ApiConfig.baseUrl)).toString();
    final key = 'sync_key_${origin}_$id';
    var secret = await _storage.read(key: key);
    if (secret == null) {
      secret = PinSecurityService.instance.generateSalt().replaceAll('=', '');
      await _storage.write(key: key, value: secret);
    }
    return secret;
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
        message: ok
            ? '${body['message'] ?? 'Recibido'}'
            : detail is String
            ? detail
            : response.statusCode == 422
            ? 'El servidor rechazó datos incompletos o inválidos. Revisa tu perfil.'
            : 'No se pudo enviar el registro.',
      );
    } catch (error) {
      return ApiSyncResponse(
        ok: false,
        serverId: '',
        message: error is StateError
            ? error.message
            : 'No se pudo conectar con el servidor. Los datos siguen guardados en el teléfono.',
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
    return _post('/api/mobile/registro', {
      'perfil': _perfilPayload(perfil),
      'sync_key': secret,
      if (codigo != null) 'codigo_vinculacion': codigo.trim(),
    });
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
