import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../models/evaluacion_riesgo.dart';
import '../models/perfil_gestante.dart';
import '../services/database_key_service.dart';
import '../services/session_state_service.dart';

class LocalDatabase {
  LocalDatabase._internal();

  static final LocalDatabase instance = LocalDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'riesgo_materno_local.db');

    final password =
        await DatabaseKeyService.instance.getOrCreateDatabasePassword();

    return openDatabase(
      path,
      password: password,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        try {
          final rows = await db.rawQuery('PRAGMA cipher_version');

          if (rows.isNotEmpty) {
            final version = rows.first.values.first;
            debugPrint('SQLCipher activo. Versión: $version');
          } else {
            debugPrint('No se pudo confirmar cipher_version.');
          }
        } catch (e) {
          debugPrint('No se pudo leer PRAGMA cipher_version: $e');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE perfil_gestante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        dni TEXT NOT NULL,
        celular TEXT NOT NULL DEFAULT '',
        pin_hash TEXT NOT NULL DEFAULT '',
        pin_salt TEXT NOT NULL DEFAULT '',
        edad_materna INTEGER NOT NULL,
        semanas_gestacion INTEGER NOT NULL,
        numero_embarazos INTEGER NOT NULL,
        cesarea_previa INTEGER NOT NULL,
        diabetes INTEGER NOT NULL,
        hipertension_previa INTEGER NOT NULL,
        preeclampsia_previa INTEGER NOT NULL,
        anemia_gestacional INTEGER NOT NULL,
        presion_basal_sistolica INTEGER NOT NULL,
        presion_basal_diastolica INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(dni)
      )
    ''');

    await db.execute('''
      CREATE TABLE evaluaciones (
        id_local TEXT PRIMARY KEY,
        perfil_id INTEGER NOT NULL,
        fecha_hora TEXT NOT NULL,
        form_data_json TEXT NOT NULL,
        sintomas_detectados_json TEXT NOT NULL,
        nivel_riesgo TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        probabilidades_json TEXT,
        sync_status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(perfil_id) REFERENCES perfil_gestante(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_evaluaciones_perfil_fecha
      ON evaluaciones(perfil_id, fecha_hora DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfNotExists(
        db,
        tableName: 'perfil_gestante',
        columnName: 'dni',
        definition: "TEXT NOT NULL DEFAULT ''",
      );

      await _addColumnIfNotExists(
        db,
        tableName: 'perfil_gestante',
        columnName: 'celular',
        definition: "TEXT NOT NULL DEFAULT ''",
      );

      await _addColumnIfNotExists(
        db,
        tableName: 'perfil_gestante',
        columnName: 'pin_hash',
        definition: "TEXT NOT NULL DEFAULT ''",
      );

      await _addColumnIfNotExists(
        db,
        tableName: 'perfil_gestante',
        columnName: 'pin_salt',
        definition: "TEXT NOT NULL DEFAULT ''",
      );
    }

    if (oldVersion < 3) {
      await _addColumnIfNotExists(
        db,
        tableName: 'evaluaciones',
        columnName: 'perfil_id',
        definition: 'INTEGER',
      );

      final perfiles = await db.query(
        'perfil_gestante',
        orderBy: 'id ASC',
        limit: 1,
      );

      if (perfiles.isNotEmpty) {
        final primerPerfilId = perfiles.first['id'] as int;

        await db.update(
          'evaluaciones',
          {
            'perfil_id': primerPerfilId,
          },
          where: 'perfil_id IS NULL OR perfil_id = 0',
        );
      }

      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_perfil_gestante_dni
        ON perfil_gestante(dni)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_evaluaciones_perfil_fecha
        ON evaluaciones(perfil_id, fecha_hora DESC)
      ''');
    }
  }

  Future<void> _addColumnIfNotExists(
    Database db, {
    required String tableName,
    required String columnName,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');

    final exists = columns.any((column) => column['name'] == columnName);

    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $definition',
      );
    }
  }

  Future<String> obtenerVersionSqlCipher() async {
    final db = await database;

    final rows = await db.rawQuery('PRAGMA cipher_version');

    if (rows.isEmpty) {
      return 'No disponible';
    }

    return rows.first.values.first.toString();
  }

  // ============================================================
  // PERFIL / CUENTAS
  // ============================================================

  Future<bool> existeAlgunaCuentaLocal() async {
    final db = await database;

    final rows = await db.query(
      'perfil_gestante',
      columns: ['id'],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<PerfilGestante?> obtenerPerfilPorDni(String dni) async {
    final db = await database;

    final rows = await db.query(
      'perfil_gestante',
      where: 'dni = ?',
      whereArgs: [dni.trim()],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return PerfilGestante.fromMapDb(rows.first);
  }

  Future<PerfilGestante?> obtenerPerfilPorId(int id) async {
    final db = await database;

    final rows = await db.query(
      'perfil_gestante',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return PerfilGestante.fromMapDb(rows.first);
  }

  Future<PerfilGestante?> obtenerPerfilActivo() async {
    final activeProfileId =
        await SessionStateService.instance.getActiveProfileId();

    if (activeProfileId == null) {
      return null;
    }

    return obtenerPerfilPorId(activeProfileId);
  }

  Future<PerfilGestante?> obtenerPerfil() async {
    return obtenerPerfilActivo();
  }

  Future<int> guardarOActualizarPerfil(PerfilGestante perfil) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      ...perfil.toMapDb(),
      'updated_at': now,
    };

    if (perfil.id != null) {
      await db.update(
        'perfil_gestante',
        data,
        where: 'id = ?',
        whereArgs: [perfil.id],
      );

      return perfil.id!;
    }

    final existente = await obtenerPerfilPorDni(perfil.dni);

    if (existente != null) {
      throw Exception('Ya existe una cuenta local registrada con este DNI.');
    }

    final nuevoId = await db.insert(
      'perfil_gestante',
      {
        ...data,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return nuevoId;
  }

  // ============================================================
  // EVALUACIONES
  // ============================================================

  Future<void> guardarEvaluacion(EvaluacionRiesgo evaluacion) async {
    final db = await database;

    if (evaluacion.perfilId <= 0) {
      throw Exception('La evaluación no tiene un perfil válido asociado.');
    }

    await db.insert(
      'evaluaciones',
      evaluacion.toMapDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EvaluacionRiesgo>> listarEvaluaciones() async {
    final perfil = await obtenerPerfilActivo();

    if (perfil == null || perfil.id == null) {
      return [];
    }

    return listarEvaluacionesPorPerfil(perfil.id!);
  }

  Future<List<EvaluacionRiesgo>> listarEvaluacionesPorPerfil(int perfilId) async {
    final db = await database;

    final rows = await db.query(
      'evaluaciones',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
      orderBy: 'fecha_hora DESC',
    );

    return rows.map((row) => EvaluacionRiesgo.fromMapDb(row)).toList();
  }

  Future<List<EvaluacionRiesgo>> listarEvaluacionesPendientes() async {
    final db = await database;

    final rows = await db.query(
      'evaluaciones',
      where: 'sync_status = ?',
      whereArgs: ['pendiente'],
      orderBy: 'fecha_hora ASC',
    );

    return rows.map((row) => EvaluacionRiesgo.fromMapDb(row)).toList();
  }

  Future<List<EvaluacionRiesgo>> listarEvaluacionesPendientesDelPerfilActivo() async {
    final perfil = await obtenerPerfilActivo();

    if (perfil == null || perfil.id == null) {
      return [];
    }

    final db = await database;

    final rows = await db.query(
      'evaluaciones',
      where: 'perfil_id = ? AND sync_status = ?',
      whereArgs: [perfil.id!, 'pendiente'],
      orderBy: 'fecha_hora ASC',
    );

    return rows.map((row) => EvaluacionRiesgo.fromMapDb(row)).toList();
  }

  Future<int> contarEvaluacionesPendientesDelPerfilActivo() async {
    final perfil = await obtenerPerfilActivo();

    if (perfil == null || perfil.id == null) {
      return 0;
    }

    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM evaluaciones
      WHERE perfil_id = ?
        AND sync_status = ?
      ''',
      [perfil.id!, 'pendiente'],
    );

    final total = rows.first['total'];

    if (total is int) {
      return total;
    }

    return int.tryParse(total.toString()) ?? 0;
  }

  Future<void> marcarComoSincronizada(String idLocal) async {
    final db = await database;

    await db.update(
      'evaluaciones',
      {
        'sync_status': 'sincronizado',
      },
      where: 'id_local = ?',
      whereArgs: [idLocal],
    );
  }

  Future<void> eliminarTodo() async {
    final db = await database;

    await db.delete('evaluaciones');
    await db.delete('perfil_gestante');
  }
}