import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/local_database.dart';
import '../models/recordatorio.dart';
import 'recordatorio_notificaciones.dart';
import 'session_state_service.dart';

class RecordatorioAnterior {
  const RecordatorioAnterior({
    required this.clave,
    required this.tipo,
    required this.datos,
  });

  final String clave;
  final TipoRecordatorio tipo;
  final Map<String, dynamic> datos;
  String get titulo =>
      datos['titulo'] is String ? datos['titulo'] as String : 'Sin nombre';
  DateTime get fechaHora {
    final fecha = datos['fecha'];
    final hora = datos['hora'];
    if (fecha is! String || hora is! String) {
      throw const FormatException(
        'Este registro no contiene una fecha y hora reconocidas.',
      );
    }
    return Recordatorio.leerFechaAnterior(fecha, hora);
  }
}

class RecordatoriosService {
  RecordatoriosService({
    required this.obtenerPerfilActivo,
    required this.obtenerPerfilesLocales,
    required this.notificaciones,
    DateTime Function()? reloj,
  }) : reloj = reloj ?? RecordatorioNotificaciones.ahora;

  static final instance = RecordatoriosService(
    obtenerPerfilActivo: () async {
      if (await SessionStateService.instance.isSessionClosed()) return null;
      return SessionStateService.instance.getActiveProfileId();
    },
    obtenerPerfilesLocales: () async {
      final db = await LocalDatabase.instance.database;
      return (await db.query(
        'perfil_gestante',
        columns: ['id'],
      )).map((fila) => fila['id'] as int).toList();
    },
    notificaciones: RecordatorioNotificaciones.instance,
  );

  static const _storage = FlutterSecureStorage();
  static const _prefijo = 'recordatorios_perfil_';
  static const _contador = 'recordatorios_siguiente_id';
  final Future<int?> Function() obtenerPerfilActivo;
  final Future<List<int>> Function() obtenerPerfilesLocales;
  final RecordatorioNotificaciones notificaciones;
  final DateTime Function() reloj;
  Future<void>? _cola;

  // Evita que guardar, restaurar e importar sobrescriban cambios concurrentes.
  Future<T> _serial<T>(Future<T> Function() accion) {
    final resultado = _cola == null ? accion() : _cola!.then((_) => accion());
    _cola = resultado.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return resultado;
  }

  Future<int> _perfil() async {
    final perfil = await obtenerPerfilActivo();
    if (perfil == null) {
      throw StateError('Ingresa a tu cuenta para ver tus recordatorios.');
    }
    return perfil;
  }

  Future<void> _verificarPerfil(int perfil) async {
    if (await obtenerPerfilActivo() != perfil) {
      throw StateError('La cuenta cambió. Vuelve a abrir tus recordatorios.');
    }
  }

  Future<List<Recordatorio>> _leer(SharedPreferences prefs, int perfil) async {
    final key = '$_prefijo$perfil';
    final contenido = await _storage.read(key: key) ?? prefs.getString(key);
    if (contenido == null) return [];
    final registros = (jsonDecode(contenido) as List)
        .map(
          (fila) =>
              Recordatorio.fromJson(Map<String, dynamic>.from(fila as Map)),
        )
        .toList();
    if (registros.any((registro) => registro.perfilId != perfil)) {
      throw StateError(
        'No se pudieron verificar los recordatorios de esta cuenta.',
      );
    }
    // Migración verificada: se elimina el texto plano solo después de escribirlo cifrado.
    await _storage.write(key: key, value: contenido);
    if (await _storage.read(key: key) != contenido) {
      throw StateError(
        'No se pudo proteger el recordatorio. El original se conserva.',
      );
    }
    await prefs.remove(key);
    registros.sort(
      (a, b) => a.proximaFecha(reloj()).compareTo(b.proximaFecha(reloj())),
    );
    return registros;
  }

  Future<void> _escribir(
    SharedPreferences prefs,
    int perfil,
    List<Recordatorio> registros,
  ) async {
    await _verificarPerfil(perfil);
    final key = '$_prefijo$perfil';
    final value = jsonEncode(registros.map((r) => r.toJson()).toList());
    await _storage.write(key: key, value: value);
    if (await _storage.read(key: key) != value) {
      throw StateError('No se pudieron guardar los recordatorios.');
    }
    await prefs.remove(key);
  }

  Future<int> _nuevoId(SharedPreferences prefs) async {
    // Los IDs anteriores usaban 0..99999; el 0 se reserva para la bienvenida.
    final id = prefs.getInt(_contador) ?? 1000000;
    if (id >= 2147483647) {
      throw StateError('No se pueden crear más recordatorios.');
    }
    if (!await prefs.setInt(_contador, id + 1)) {
      throw StateError('No se pudo crear el recordatorio.');
    }
    return id;
  }

  Future<List<Recordatorio>> listar() => _serial(() async {
    final perfil = await _perfil();
    return await _leer(await SharedPreferences.getInstance(), perfil);
  });

  Future<Recordatorio> _activar(Recordatorio registro, EstadoAviso modo) async {
    try {
      if (registro.completado || registro.estaVencido(reloj())) {
        await notificaciones.cancelar(registro.id);
        return registro.copyWith(estadoAviso: EstadoAviso.pendiente);
      }
      final estado = await notificaciones.programar(
        registro,
        disponibilidad: modo,
      );
      if (await obtenerPerfilActivo() != registro.perfilId) {
        await notificaciones.cancelar(registro.id);
        throw StateError('La cuenta cambió al programar el aviso.');
      }
      return registro.copyWith(estadoAviso: estado);
    } catch (error) {
      // Sin datos clínicos: el detalle técnico queda disponible en Logcat.
      debugPrint(
        'Recordatorios: no se pudo activar el aviso ${registro.id}: $error',
      );
      return registro.copyWith(estadoAviso: EstadoAviso.error);
    }
  }

  Future<Recordatorio> crear({
    required TipoRecordatorio tipo,
    required String titulo,
    required DateTime fechaHora,
    RepeticionRecordatorio repeticion = RepeticionRecordatorio.unaVez,
  }) => _serial(() async {
    final perfil = await _perfil();
    final nombre = titulo.trim();
    if (nombre.isEmpty) {
      throw ArgumentError('Escribe el nombre del recordatorio.');
    }
    if (tipo == TipoRecordatorio.cita &&
        repeticion != RepeticionRecordatorio.unaVez) {
      throw ArgumentError('Las citas se programan para una fecha concreta.');
    }
    final ahora = reloj();
    final fecha = repeticion == RepeticionRecordatorio.diaria
        ? Recordatorio.siguienteHoraDiaria(fechaHora, ahora)
        : fechaHora;
    if (!fecha.isAfter(ahora)) {
      throw ArgumentError('Elige una fecha y hora futuras.');
    }
    final prefs = await SharedPreferences.getInstance();
    final registros = await _leer(prefs, perfil);
    var nuevo = Recordatorio(
      id: await _nuevoId(prefs),
      perfilId: perfil,
      tipo: tipo,
      titulo: nombre,
      fechaHora: fecha,
      repeticion: repeticion,
    );
    // El dato se conserva aunque se rechacen permisos o falle la alarma.
    registros.add(nuevo);
    await _escribir(prefs, perfil, registros);
    final modo = await notificaciones.disponibilidad(solicitarPermisos: true);
    nuevo = await _activar(nuevo, modo);
    registros[registros.length - 1] = nuevo;
    await _escribir(prefs, perfil, registros);
    return nuevo;
  });

  Future<Recordatorio> cambiarEstado(
    int id, {
    required bool completado,
    DateTime? nuevaFecha,
  }) => _serial(() async {
    final perfil = await _perfil();
    final prefs = await SharedPreferences.getInstance();
    final registros = await _leer(prefs, perfil);
    final indice = registros.indexWhere((r) => r.id == id);
    if (indice < 0) {
      throw StateError('No se encontró este recordatorio en tu cuenta.');
    }
    var registro = registros[indice].copyWith(
      completado: completado,
      fechaHora: nuevaFecha,
    );
    if (!completado && registro.estaVencido(reloj())) {
      throw ArgumentError(
        'Elige una nueva fecha y hora para reactivar el aviso.',
      );
    }
    // Cancela primero, para no anunciar éxito si el sistema rechazó el cambio.
    await notificaciones.cancelar(id);
    registros[indice] = registro.copyWith(estadoAviso: EstadoAviso.pendiente);
    await _escribir(prefs, perfil, registros);
    if (!completado) {
      registro = await _activar(
        registro,
        await notificaciones.disponibilidad(solicitarPermisos: true),
      );
      registros[indice] = registro;
      await _escribir(prefs, perfil, registros);
    }
    return registros[indice];
  });

  Future<List<RecordatorioAnterior>> _anteriores(
    SharedPreferences prefs,
  ) async {
    final importados = <String>{};
    for (final clave in {
      ...prefs.getKeys(),
      ...(await _storage.readAll()).keys,
    }.where((k) => k.startsWith(_prefijo))) {
      final perfil = int.tryParse(clave.substring(_prefijo.length));
      if (perfil != null) {
        importados.addAll(
          (await _leer(
            prefs,
            perfil,
          )).map((r) => r.claveAnterior).whereType<String>(),
        );
      }
    }
    final resultado = <RecordatorioAnterior>[];
    for (final tipo in TipoRecordatorio.values) {
      final legacyKey = tipo == TipoRecordatorio.pastilla
          ? 'mis_pastillas'
          : 'mis_citas';
      final contenido =
          await _storage.read(key: legacyKey) ?? prefs.getString(legacyKey);
      if (contenido != null) {
        await _storage.write(key: legacyKey, value: contenido);
        if (await _storage.read(key: legacyKey) != contenido) {
          throw StateError('No se pudo proteger el registro anterior.');
        }
        await prefs.remove(legacyKey);
      }
      if (contenido == null || contenido.isEmpty) continue;
      List<dynamic> filas;
      try {
        final decodificado = jsonDecode(contenido);
        filas = decodificado is List ? decodificado : [decodificado];
      } on FormatException {
        filas = [contenido];
      }
      for (var i = 0; i < filas.length; i++) {
        final datos = filas[i] is Map
            ? Map<String, dynamic>.from(filas[i] as Map)
            : <String, dynamic>{
                'titulo': 'Registro anterior no reconocido',
                'original': filas[i],
              };
        final clave = sha256
            .convert(utf8.encode('${tipo.name}:$i:${jsonEncode(datos)}'))
            .toString();
        if (!importados.contains(clave)) {
          resultado.add(
            RecordatorioAnterior(clave: clave, tipo: tipo, datos: datos),
          );
        }
      }
    }
    return resultado;
  }

  Future<List<RecordatorioAnterior>> anterioresSinCuenta() => _serial(() async {
    await _perfil();
    return await _anteriores(await SharedPreferences.getInstance());
  });

  Future<void> _importar(
    SharedPreferences prefs,
    int perfil,
    Set<String> claves,
  ) async {
    final registros = await _leer(prefs, perfil);
    for (final anterior in (await _anteriores(
      prefs,
    )).where((r) => claves.contains(r.clave))) {
      registros.add(
        Recordatorio(
          id: await _nuevoId(prefs),
          perfilId: perfil,
          tipo: anterior.tipo,
          titulo: anterior.titulo,
          fechaHora: anterior.fechaHora,
          completado: anterior.datos['completado'] == true,
          claveAnterior: anterior.clave,
        ),
      );
    }
    await _escribir(prefs, perfil, registros);
  }

  Future<void> importarAnteriores(Set<String> claves) => _serial(() async {
    final perfil = await _perfil();
    await _importar(await SharedPreferences.getInstance(), perfil, claves);
  });

  Future<List<Recordatorio>> restaurar({
    bool solicitarPermisos = false,
  }) => _serial(() async {
    final perfil = await _perfil();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('recordatorios_avisos_anteriores_cancelados') != true) {
      // Las alarmas antiguas no tienen propietario. Se recuperan con IDs nuevos.
      for (final anterior in await _anteriores(prefs)) {
        final id = anterior.datos['id'];
        if (id is int) await notificaciones.cancelar(id);
      }
      await prefs.setBool('recordatorios_avisos_anteriores_cancelados', true);
    }
    final perfiles = await obtenerPerfilesLocales();
    if (perfiles.length == 1 && perfiles.single == perfil) {
      final validos = <String>{};
      for (final anterior in await _anteriores(prefs)) {
        try {
          anterior.fechaHora;
          validos.add(anterior.clave);
        } on FormatException {
          // El original se conserva para revisión; no se descarta ni se adivina.
        }
      }
      if (validos.isNotEmpty) await _importar(prefs, perfil, validos);
    }
    if (prefs.getInt('recordatorios_perfil_avisos') != perfil) {
      await notificaciones.cancelarTodos();
      await prefs.setInt('recordatorios_perfil_avisos', perfil);
    }
    final registros = await _leer(prefs, perfil);
    if (registros.isEmpty) return registros;
    final clavePrivacidad = 'recordatorios_avisos_genericos_$perfil';
    final protegerAvisos = prefs.getBool(clavePrivacidad) != true;
    final modo = await notificaciones.disponibilidad(
      solicitarPermisos: solicitarPermisos,
    );
    final pendientes = await notificaciones.pendientes();
    final actualizados = <Recordatorio>[];
    for (final registro in registros) {
      if (protegerAvisos) await notificaciones.cancelar(registro.id);
      if (protegerAvisos ||
          registro.completado ||
          registro.estaVencido(reloj()) ||
          !pendientes.contains(registro.id) ||
          registro.estadoAviso != modo) {
        actualizados.add(await _activar(registro, modo));
      } else {
        actualizados.add(registro);
      }
    }
    await _escribir(prefs, perfil, actualizados);
    if (protegerAvisos) await prefs.setBool(clavePrivacidad, true);
    return actualizados;
  });
}
