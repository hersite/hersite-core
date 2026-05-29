import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PinSecurityService {
  PinSecurityService._internal();

  static final PinSecurityService instance = PinSecurityService._internal();

  String generateSalt() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    );

    return base64UrlEncode(bytes);
  }

  String hashPin({
    required String pin,
    required String salt,
  }) {
    final normalizedPin = pin.trim();
    final value = '$salt:$normalizedPin';

    return sha256.convert(utf8.encode(value)).toString();
  }

  bool verifyPin({
    required String inputPin,
    required String storedHash,
    required String storedSalt,
  }) {
    final inputHash = hashPin(
      pin: inputPin,
      salt: storedSalt,
    );

    return _constantTimeEquals(inputHash, storedHash);
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
}