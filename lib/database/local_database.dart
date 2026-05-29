import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/evaluacion_riesgo.dart';
import '../models/perfil_gestante.dart';

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

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE perfil_gestante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
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
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE evaluaciones (
        id_local TEXT PRIMARY KEY,
        fecha_hora TEXT NOT NULL,
        form_data_json TEXT NOT NULL,
        sintomas_detectados_json TEXT NOT NULL,
        nivel_riesgo TEXT NOT NULL,
        mensaje TEXT NOT NULL,
        probabilidades_json TEXT,
        sync_status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ============================================================
  // PERFIL
  // ============================================================

  Future<void> guardarOActualizarPerfil(PerfilGestante perfil) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final data = {
      ...perfil.toMapDb(),
      'updated_at': now,
    };

    final existe = await db.query(
      'perfil_gestante',
      limit: 1,
    );

    if (existe.isEmpty) {
      await db.insert(
        'perfil_gestante',
        {
          ...data,
          'created_at': now,
        },
      );
    } else {
      await db.update(
        'perfil_gestante',
        data,
        where: 'id = ?',
        whereArgs: [existe.first['id']],
      );
    }
  }

  Future<PerfilGestante?> obtenerPerfil() async {
    final db = await database;

    final rows = await db.query(
      'perfil_gestante',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return PerfilGestante.fromMapDb(rows.first);
  }

  // ============================================================
  // EVALUACIONES
  // ============================================================

  Future<void> guardarEvaluacion(EvaluacionRiesgo evaluacion) async {
    final db = await database;

    await db.insert(
      'evaluaciones',
      evaluacion.toMapDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EvaluacionRiesgo>> listarEvaluaciones() async {
    final db = await database;

    final rows = await db.query(
      'evaluaciones',
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