import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyService {
  DatabaseKeyService._internal();

  static final DatabaseKeyService instance = DatabaseKeyService._internal();

  static const String _databasePasswordKey = 'riesgo_materno_db_password';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> getOrCreateDatabasePassword() async {
    final existingPassword = await _secureStorage.read(
      key: _databasePasswordKey,
    );

    if (existingPassword != null && existingPassword.isNotEmpty) {
      return existingPassword;
    }

    final newPassword = _generateSecurePassword();

    await _secureStorage.write(
      key: _databasePasswordKey,
      value: newPassword,
    );

    return newPassword;
  }

  String _generateSecurePassword() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  Future<void> deleteDatabasePasswordForDevOnly() async {
    await _secureStorage.delete(
      key: _databasePasswordKey,
    );
  }
}