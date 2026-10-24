import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static Uri uri(String path) {
    final base = Uri.parse(baseUrl);
    final localDebug =
        kDebugMode &&
        {'10.0.2.2', '127.0.0.1', 'localhost'}.contains(base.host);
    if (base.scheme != 'https' && !(localDebug && base.scheme == 'http')) {
      throw StateError(
        'Configura API_BASE_URL con HTTPS. HTTP solo se permite en desarrollo local.',
      );
    }
    return Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');
  }
}
