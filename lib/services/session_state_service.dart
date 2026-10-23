import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'recordatorio_notificaciones.dart';

class SessionStateService {
  SessionStateService._internal();

  static final SessionStateService instance = SessionStateService._internal();

  static const String _sessionClosedKey = 'session_closed';
  static const String _activeProfileIdKey = 'active_profile_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<bool> isSessionClosed() async {
    final value = await _secureStorage.read(key: _sessionClosedKey);
    return value == 'true';
  }

  Future<void> markSessionClosed() async {
    // Cancela solo recordatorios; conserva los datos para el próximo ingreso.
    await RecordatorioNotificaciones.instance.cancelarTodos();
    await _secureStorage.write(
      key: _sessionClosedKey,
      value: 'true',
    );

    await clearActiveProfileId();
  }

  Future<void> markSessionActive() async {
    await _secureStorage.write(
      key: _sessionClosedKey,
      value: 'false',
    );
  }

  Future<void> setActiveProfileId(int profileId) async {
    if (await getActiveProfileId() != profileId) {
      await RecordatorioNotificaciones.instance.cancelarTodos();
    }
    await _secureStorage.write(
      key: _activeProfileIdKey,
      value: profileId.toString(),
    );
  }

  Future<int?> getActiveProfileId() async {
    final value = await _secureStorage.read(key: _activeProfileIdKey);

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  Future<void> clearActiveProfileId() async {
    await _secureStorage.delete(key: _activeProfileIdKey);
  }

  Future<void> clearSessionStateForDevOnly() async {
    await _secureStorage.delete(key: _sessionClosedKey);
    await _secureStorage.delete(key: _activeProfileIdKey);
  }
}
