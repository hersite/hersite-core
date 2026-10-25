import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hersite_core/models/recordatorio.dart';
import 'package:hersite_core/services/api_client.dart';
import 'package:hersite_core/services/recuperar_cuenta_service.dart';
import 'package:hersite_core/services/recordatorios_service.dart';
import 'package:hersite_core/services/recordatorio_notificaciones.dart';
import 'package:hersite_core/services/session_state_service.dart';
import 'package:hersite_core/services/pin_security_service.dart';
import 'package:hersite_core/screens/recuperar_cuenta_screen.dart';
import 'package:hersite_core/widgets/guia_app_dialog.dart';

class AvisosPrueba extends RecordatorioNotificaciones {
  final programados = <int>{};
  @override
  Future<EstadoAviso> disponibilidad({bool solicitarPermisos = false}) async =>
      EstadoAviso.exacto;
  @override
  Future<EstadoAviso> programar(
    Recordatorio r, {
    required EstadoAviso disponibilidad,
  }) async {
    programados.add(r.id);
    return EstadoAviso.exacto;
  }

  @override
  Future<void> cancelar(int id) async {
    programados.remove(id);
  }

  @override
  Future<void> cancelarTodos() async {
    programados.clear();
  }

  @override
  Future<Set<int>> pendientes() async => programados.toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('Guía pendiente únicamente para cada perfil nuevo', () async {
    expect(await GuiaApp.pendiente(1), false);
    await GuiaApp.preparar(1);
    await GuiaApp.preparar(2);
    expect(await GuiaApp.pendiente(1), true);
    await GuiaApp.completar(1);
    expect(await GuiaApp.pendiente(1), false);
    expect(await GuiaApp.pendiente(2), true);
  });

  test('El PIN usa la misma derivación que el servicio Python', () async {
    final hash = await PinSecurityService.instance.hashPin(
      pin: '123456',
      salt: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    );
    expect(
      hash,
      'pbkdf2_sha256\$600000\$mgNB3A6xMDfSn65Se6zF1hemWxGeU8895CgqWxclv8c=',
    );
  });

  testWidgets('Recuperación resalta DNI y PIN incompletos', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RecuperarCuentaScreen()));
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Recuperar mi cuenta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Recuperar mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe los 8 números de tu DNI.'), findsOneWidget);
    expect(find.text('Escribe los 6 números de tu PIN.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'Solicitud usa DNI y PIN; confirmar requiere autorización separada',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'ok': true,
              'token': 'token',
              'perfil': {'dni': '12345678'},
              'evaluaciones': [],
              'recordatorios': {},
            }),
            200,
          );
        }),
      );
      final result = await RecuperarCuentaService(
        api: api,
      ).consultar('12345678', '123456');
      expect(result['token'], 'token');
      expect(requests.single.url.path, '/api/mobile/recuperar');
      expect(jsonDecode(requests.single.body), {
        'dni': '12345678',
        'pin': '123456',
      });
      await api.confirmarRecuperacion('token', 'clave-nueva');
      expect(requests.last.url.path, '/api/mobile/confirmar-recuperacion');
      expect(jsonDecode(requests.last.body), {
        'token': 'token',
        'sync_key': 'clave-nueva',
      });
    },
  );

  test('Sin conexión muestra una instrucción sencilla', () async {
    final api = ApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(
      () => RecuperarCuentaService(api: api).consultar('12345678', '123456'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'mensaje',
          contains('conéctate a internet'),
        ),
      ),
    );
  });

  test(
    'Rechaza respuesta de otro DNI y cambio de cuenta durante solicitud',
    () async {
      var changeAccount = false;
      final api = ApiClient(
        client: MockClient((_) async {
          if (changeAccount) SessionStateService.instance.generation++;
          return http.Response(
            jsonEncode({
              'ok': true,
              'perfil': {'dni': '87654321'},
            }),
            200,
          );
        }),
      );
      expect(
        () => RecuperarCuentaService(api: api).consultar('12345678', '123456'),
        throwsStateError,
      );
      changeAccount = true;
      expect(
        () => RecuperarCuentaService(api: api).consultar('12345678', '123456'),
        throwsStateError,
      );
    },
  );

  test('El bloqueo remoto tiene un mensaje comprensible', () async {
    final api = ApiClient(
      client: MockClient((_) async => http.Response('{}', 429)),
    );
    final result = await api.solicitarRecuperacion('12345678', '123456');
    expect(result.ok, false);
    expect(result.message, contains('15 minutos'));
  });

  group('Respaldo de recordatorios', () {
    late RecordatoriosService service;
    late AvisosPrueba avisos;
    var active = 1;
    final now = DateTime(2026, 10, 25, 9);
    setUp(() {
      active = 1;
      avisos = AvisosPrueba();
      service = RecordatoriosService(
        obtenerPerfilActivo: () async => active,
        obtenerPerfilesLocales: () async => [1, 2],
        notificaciones: avisos,
        reloj: () => now,
      );
    });

    test(
      'Identificador estable, cambios pendientes y copia confirmada',
      () async {
        final r = await service.crear(
          tipo: TipoRecordatorio.pastilla,
          titulo: 'Pastilla',
          fechaHora: now.add(const Duration(hours: 1)),
        );
        final copia = (await service.prepararRespaldo(1))!;
        final records = copia['registros'] as List;
        expect(records.single['respaldo_id'], r.respaldoId);
        expect(records.single.containsKey('perfil_id'), false);
        expect(records.single.containsKey('estado_aviso'), false);
        await service.confirmarRespaldo(1, 1, records);
        expect(await service.prepararRespaldo(1), isNull);
        await service.cambiarEstado(r.id, completado: true);
        final actualizado = (await service.prepararRespaldo(1))!;
        expect(actualizado['base_version'], 1);
        expect((actualizado['registros'] as List).single['completado'], true);
        expect((await service.listar()).single.respaldoId, r.respaldoId);
      },
    );

    test(
      'Recuperación conserva nuevos, no resucita eliminados y es repetible',
      () async {
        await service.crear(
          tipo: TipoRecordatorio.cita,
          titulo: 'Cita anterior',
          fechaHora: now.add(const Duration(days: 1)),
        );
        final copia = (await service.prepararRespaldo(1))!;
        await service.confirmarRespaldo(1, 1, copia['registros'] as List);
        await service.crear(
          tipo: TipoRecordatorio.pastilla,
          titulo: 'Nueva del teléfono',
          fechaHora: now.add(const Duration(hours: 1)),
        );
        final remote = {'version': 2, 'registros': <dynamic>[]};
        await service.restaurarRespaldo(1, remote);
        await service.restaurarRespaldo(1, remote);
        expect((await service.listar()).map((r) => r.titulo), [
          'Nueva del teléfono',
        ]);
      },
    );

    test(
      'Cada perfil recupera sus recordatorios con IDs de alarma nuevos',
      () async {
        final original = await service.crear(
          tipo: TipoRecordatorio.cita,
          titulo: 'Cita guardada',
          fechaHora: now.add(const Duration(days: 1)),
        );
        final copia = (await service.prepararRespaldo(1))!;
        active = 2;
        await service.restaurarRespaldo(2, {
          'version': 1,
          'registros': copia['registros'],
        });
        final restored = (await service.listar()).single;
        expect(restored.perfilId, 2);
        expect(restored.id, isNot(original.id));
        expect(restored.respaldoId, original.respaldoId);
        await expectLater(
          () => service.restaurarRespaldo(1, {'version': 1, 'registros': []}),
          throwsStateError,
        );
        active = 1;
        expect((await service.listar()).single.id, original.id);
      },
    );

    test(
      'No programa avisos de citas vencidas ni completadas al recuperar',
      () async {
        final records = [
          {
            'respaldo_id': 'e7991e00-5fa0-4ae1-ad63-06477e2d85ba',
            'tipo': 'cita',
            'titulo': 'Cita pasada',
            'fecha_hora': now
                .subtract(const Duration(days: 1))
                .toIso8601String(),
            'repeticion': 'unaVez',
            'completado': false,
          },
          {
            'respaldo_id': 'e7991e00-5fa0-4ae1-ad63-06477e2d85bb',
            'tipo': 'pastilla',
            'titulo': 'Ya tomada',
            'fecha_hora': now.add(const Duration(days: 1)).toIso8601String(),
            'repeticion': 'diaria',
            'completado': true,
          },
        ];
        await service.restaurarRespaldo(1, {
          'version': 1,
          'registros': records,
        });
        expect((await service.restaurar()).length, 2);
        expect(avisos.programados, isEmpty);
      },
    );
  });
}
