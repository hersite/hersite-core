import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/recordatorio.dart';

class RecordatorioNotificaciones {
  RecordatorioNotificaciones({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final instance = RecordatorioNotificaciones();
  static const _registroIds = 'recordatorios_notificaciones_ids';
  static const _prefijoPayload = 'hersite_recordatorio:';
  static const canalRecordatorios = AndroidNotificationChannel(
    'recordatorios_salud_v2',
    'Recordatorios de salud',
    description: 'Avisos de pastillas y citas médicas',
    importance: Importance.high,
  );
  final FlutterLocalNotificationsPlugin plugin;

  static bool _zonaInicializada = false;

  static tz.Location get zona {
    if (!_zonaInicializada) {
      tz_data.initializeTimeZones();
      _zonaInicializada = true;
    }
    return tz.getLocation('America/Lima');
  }

  static DateTime ahora() {
    final fecha = tz.TZDateTime.now(zona);
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      fecha.hour,
      fecha.minute,
      fecha.second,
    );
  }

  Future<EstadoAviso> disponibilidad({bool solicitarPermisos = false}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return EstadoAviso.error;
    }
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return EstadoAviso.error;
    try {
      var habilitadas = await android.areNotificationsEnabled() == true;
      if (!habilitadas && solicitarPermisos) {
        habilitadas = await android.requestNotificationsPermission() == true;
      }
      if (!habilitadas) return EstadoAviso.sinPermiso;
      // El permiso general puede estar concedido y esta categoría bloqueada.
      await android.createNotificationChannel(canalRecordatorios);
      final canales = await android.getNotificationChannels() ?? [];
      if (canales.any(
        (canal) =>
            canal.id == canalRecordatorios.id &&
            canal.importance == Importance.none,
      )) {
        debugPrint(
          'Recordatorios: la categoría de notificaciones está desactivada.',
        );
        return EstadoAviso.sinPermiso;
      }
      var exactas = await android.canScheduleExactNotifications() == true;
      if (!exactas && solicitarPermisos) {
        await android.requestExactAlarmsPermission();
        exactas = await android.canScheduleExactNotifications() == true;
      }
      return exactas ? EstadoAviso.exacto : EstadoAviso.aproximado;
    } on PlatformException catch (error) {
      debugPrint(
        'Recordatorios: no se pudieron comprobar los permisos: ${error.code}',
      );
      return EstadoAviso.error;
    }
  }

  Future<void> _registrar(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_registroIds) ?? []).toSet();
    ids.add(id.toString());
    if (!await prefs.setStringList(_registroIds, ids.toList())) {
      throw StateError('No se pudo guardar el registro de avisos.');
    }
  }

  Future<EstadoAviso> programar(
    Recordatorio recordatorio, {
    required EstadoAviso disponibilidad,
  }) async {
    if (disponibilidad != EstadoAviso.exacto &&
        disponibilidad != EstadoAviso.aproximado) {
      await cancelar(recordatorio.id);
      return disponibilidad;
    }
    final siguiente = recordatorio.proximaFecha(ahora());
    if (recordatorio.completado || !siguiente.isAfter(ahora())) {
      await cancelar(recordatorio.id);
      return EstadoAviso.pendiente;
    }
    final fecha = tz.TZDateTime(
      zona,
      siguiente.year,
      siguiente.month,
      siguiente.day,
      siguiente.hour,
      siguiente.minute,
      siguiente.second,
    );
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'recordatorios_salud_v2',
        'Recordatorios de salud',
        channelDescription: 'Avisos de pastillas y citas médicas',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notificacion_salud',
        visibility: NotificationVisibility.private,
      ),
    );
    Future<void> enviar(EstadoAviso modo) async {
      await plugin.zonedSchedule(
        recordatorio.id,
        recordatorio.tipo == TipoRecordatorio.pastilla
            ? 'Recordatorio de pastilla'
            : 'Recordatorio de cita',
        'Tienes un recordatorio de salud. Abre la app para ver los detalles.',
        fecha,
        detalles,
        payload: '$_prefijoPayload${recordatorio.perfilId}:${recordatorio.id}',
        androidScheduleMode: modo == EstadoAviso.exacto
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: recordatorio.esDiario
            ? DateTimeComponents.time
            : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      // No confirmar éxito únicamente porque el canal nativo devolvió sin error.
      if (!(await pendientes()).contains(recordatorio.id)) {
        throw PlatformException(code: 'recordatorio_no_programado');
      }
      debugPrint(
        'Recordatorios: aviso ${recordatorio.id} registrado para '
        '${fecha.toIso8601String()} (${zona.name}), modo ${modo.name}.',
      );
    }

    await _registrar(recordatorio.id);
    try {
      await enviar(disponibilidad);
      return disponibilidad;
    } on PlatformException catch (error) {
      debugPrint(
        'Recordatorios: error al programar ${recordatorio.id}: ${error.code}',
      );
      if (error.code == 'exact_alarms_not_permitted') {
        try {
          await enviar(EstadoAviso.aproximado);
          return EstadoAviso.aproximado;
        } on PlatformException catch (alternativa) {
          debugPrint(
            'Recordatorios: también falló el aviso aproximado: ${alternativa.code}',
          );
        }
      }
      return EstadoAviso.error;
    }
  }

  Future<void> cancelar(int id) => plugin.cancel(id);

  Future<Set<int>> pendientes() async =>
      (await plugin.pendingNotificationRequests())
          .where((aviso) => aviso.payload?.startsWith(_prefijoPayload) ?? false)
          .map((aviso) => aviso.id)
          .toSet();

  Future<void> cancelarTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_registroIds) ?? [])
        .map(int.parse)
        .toSet();
    ids.addAll(await pendientes());
    for (final id in ids) {
      await cancelar(id);
    }
    await prefs.remove(_registroIds);
  }
}
