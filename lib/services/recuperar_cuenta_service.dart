import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/local_database.dart';
import 'api_client.dart';
import 'pin_security_service.dart';
import 'recordatorios_service.dart';
import 'session_state_service.dart';

class RecuperarCuentaService {
  RecuperarCuentaService({ApiClient? api}) : api = api ?? ApiClient.instance;
  final ApiClient api;
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> consultar(String dni, String pin) async {
    final generation = SessionStateService.instance.generation;
    final result = await api.solicitarRecuperacion(dni, pin);
    if (generation != SessionStateService.instance.generation) {
      throw StateError('Vuelve a abrir Recuperar mi cuenta.');
    }
    if (!result.ok) {
      throw StateError(
        result.statusCode == 0
            ? 'Para recuperar tu cuenta, conéctate a internet e inténtalo otra vez.'
            : result.message,
      );
    }
    if ((result.data['perfil'] as Map)['dni'] != dni) {
      throw StateError('No pudimos recuperar tu cuenta. Inténtalo otra vez.');
    }
    return result.data;
  }

  Future<void> recuperar(String dni, String pin, String token) async {
    final generation = SessionStateService.instance.generation;
    final secret = PinSecurityService.instance.generateSalt().replaceAll(
      '=',
      '',
    );
    final salt = PinSecurityService.instance.generateSalt();
    final hash = await PinSecurityService.instance.hashPin(
      pin: pin,
      salt: salt,
    );
    if (generation != SessionStateService.instance.generation) {
      throw StateError('Vuelve a abrir Recuperar mi cuenta.');
    }
    final result = await api.confirmarRecuperacion(token, secret);
    if (!result.ok) throw StateError(result.message);
    if (generation != SessionStateService.instance.generation ||
        (result.data['perfil'] as Map)['dni'] != dni) {
      throw StateError('Vuelve a abrir Recuperar mi cuenta.');
    }
    // Copia cifrada de seguridad antes de modificar los datos locales. Si falla
    // el almacenamiento, se puede repetir la recuperación sin perder la copia central.
    final anterior = await LocalDatabase.instance.obtenerPerfilPorDni(dni);
    final pendingKey = 'recuperacion_pendiente_$dni';
    await _storage.write(
      key: pendingKey,
      value: jsonEncode({
        'copia': result.data,
        'clave': secret,
        if (anterior != null) 'perfil_anterior': anterior.toMapDb(),
      }),
    );
    await SessionStateService.instance.markSessionClosed();
    try {
      final id = await LocalDatabase.instance.restaurarCuenta(
        Map<String, dynamic>.from(result.data['perfil'] as Map),
        result.data['evaluaciones'] as List,
        hash: hash,
        salt: salt,
      );
      await api.guardarClaveRecuperada(id, secret);
      await PinSecurityService.instance.limpiarIntentos(id);
      await SessionStateService.instance.setActiveProfileId(id);
      await SessionStateService.instance.markSessionActive();
      await RecordatoriosService.instance.restaurarRespaldo(
        id,
        Map<String, dynamic>.from(result.data['recordatorios'] as Map),
      );
      await _storage.delete(key: pendingKey);
    } catch (_) {
      await SessionStateService.instance.markSessionClosed();
      rethrow;
    }
  }
}
