import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../database/local_database.dart';
import '../models/evaluacion_riesgo.dart';
import 'api_config.dart';
import '../models/perfil_gestante.dart';

class ApiSyncResponse {
  final bool ok;
  final String serverId;
  final String message;

  const ApiSyncResponse({
    required this.ok,
    required this.serverId,
    required this.message,
  });
}

class ApiClient {
  ApiClient._internal();

  static final ApiClient instance = ApiClient._internal();

  Future<ApiSyncResponse> enviarEvaluacionRiesgo(
    EvaluacionRiesgo evaluacion,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/evaluaciones');

    final payload = evaluacion.toApiPayload();

    final perfil = await LocalDatabase.instance.obtenerPerfilActivo();

    if (perfil != null) {
      payload['perfil'] = {
        'dni': perfil.dni,
        'nombre': perfil.nombre,
        'celular': perfil.celular,
        'edad_materna': perfil.edadMaterna,
        'semanas_gestacion': perfil.semanasGestacion,
        'numero_embarazos': perfil.numeroEmbarazos,
        'cesarea_previa': perfil.cesareaPrevia,
        'diabetes': perfil.diabetes,
        'hipertension_previa': perfil.hipertensionPrevia,
        'preeclampsia_previa': perfil.preeclampsiaPrevia,
        'anemia_gestacional': perfil.anemiaGestacional,
        'presion_basal_sistolica': perfil.presionBasalSistolica,
        'presion_basal_diastolica': perfil.presionBasalDiastolica,
      };
    }

    debugPrint('API REAL: enviando evaluación ${evaluacion.idLocal} a $url');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('API REAL: statusCode ${response.statusCode}');
      debugPrint('API REAL: body ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ApiSyncResponse(
          ok: false,
          serverId: '',
          message: 'Error HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return ApiSyncResponse(
        ok: data['ok'] == true,
        serverId: data['server_id']?.toString() ?? '',
        message: data['message']?.toString() ?? 'Respuesta sin mensaje.',
      );
    } catch (e) {
      debugPrint('API REAL: error enviando evaluación: $e');

      return ApiSyncResponse(ok: false, serverId: '', message: e.toString());
    }
  }

  Future<ApiSyncResponse> enviarPerfil(PerfilGestante perfil) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/perfiles');

    final payload = {
      "dni": perfil.dni,
      "nombre": perfil.nombre,
      "celular": perfil.celular,

      "edad_materna": perfil.edadMaterna,

      "semanas_gestacion": perfil.semanasGestacion,

      "numero_embarazos": perfil.numeroEmbarazos,

      "cesarea_previa": perfil.cesareaPrevia,

      "diabetes": perfil.diabetes,

      "hipertension_previa": perfil.hipertensionPrevia,

      "preeclampsia_previa": perfil.preeclampsiaPrevia,

      "anemia_gestacional": perfil.anemiaGestacional,

      "presion_basal_sistolica": perfil.presionBasalSistolica,

      "presion_basal_diastolica": perfil.presionBasalDiastolica,
    };

    final response = await http.post(
  url,
  headers: {
    "Content-Type": "application/json",
  },
  body: jsonEncode(payload),
);

debugPrint("JSON ENVIADO:");
debugPrint(jsonEncode(payload));

debugPrint("STATUS: ${response.statusCode}");

debugPrint("RESPUESTA:");
debugPrint(response.body);

final data = jsonDecode(response.body);

    return ApiSyncResponse(
      ok: data["ok"],

      serverId: data["server_id"].toString(),

      message: data["message"],
    );
  }
}
