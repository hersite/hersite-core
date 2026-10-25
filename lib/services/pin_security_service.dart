import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinSecurityService {
  PinSecurityService._internal();

  static final PinSecurityService instance = PinSecurityService._internal();
  static const _iterations = 600000;
  final _storage = const FlutterSecureStorage();

  String generateSalt() {
    final random = Random.secure();

    final bytes = List<int>.generate(32, (_) => random.nextInt(256));

    return base64UrlEncode(bytes);
  }

  Future<String> hashPin({required String pin, required String salt}) async {
    final derived = await Isolate.run(
      () => _derive(pin.trim(), salt, _iterations),
    );
    return 'pbkdf2_sha256\$$_iterations\$$derived';
  }

  Future<bool> verifyPin({
    required String inputPin,
    required String storedHash,
    required String storedSalt,
  }) async {
    if (storedHash.startsWith('pbkdf2_sha256\$')) {
      final parts = storedHash.split('\$');
      if (parts.length != 3 || parts[1] != '$_iterations') return false;
      final inputHash = await hashPin(pin: inputPin, salt: storedSalt);
      return _constantTimeEquals(inputHash, storedHash);
    }
    // Compatibilidad: tras un ingreso válido se migra el hash antiguo.
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(storedHash)) return false;
    final old = sha256
        .convert(utf8.encode('$storedSalt:${inputPin.trim()}'))
        .toString();
    return _constantTimeEquals(old, storedHash);
  }

  static String _derive(String pin, String salt, int rounds) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    final output = List<int>.from(block);
    for (var i = 1; i < rounds; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < output.length; j++) {
        output[j] ^= block[j];
      }
    }
    return base64UrlEncode(output);
  }

  Future<bool> verificarConLimite({
    required int perfilId,
    required String pin,
    required String hash,
    required String salt,
  }) async {
    final key = 'pin_attempts_$perfilId';
    final raw = await _storage.read(key: key);
    final state = raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch;
    final until = state['until'] as int? ?? 0;
    if (until > now) {
      throw StateError(
        'Demasiados intentos. Intenta de nuevo en ${((until - now) / 60000).ceil()} minutos.',
      );
    }
    final valid = await verifyPin(
      inputPin: pin,
      storedHash: hash,
      storedSalt: salt,
    );
    if (valid) {
      await _storage.delete(key: key);
    } else {
      final attempts = until > 0 ? 1 : (state['attempts'] as int? ?? 0) + 1;
      await _storage.write(
        key: key,
        value: jsonEncode({
          'attempts': attempts,
          'until': attempts >= 5
              ? now + const Duration(minutes: 15).inMilliseconds
              : 0,
        }),
      );
    }
    return valid;
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;

    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  Future<void> limpiarIntentos(int id) =>
      _storage.delete(key: 'pin_attempts_$id');
}
