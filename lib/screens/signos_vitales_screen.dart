import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/evaluacion_riesgo.dart';
import '../services/riesgo_materno_model.dart';
import '../services/connectivity_sync_service.dart';
import 'resultado_screen.dart';

class SignosVitalesScreen extends StatefulWidget {
  final Set<int> sintomasSeleccionados;

  const SignosVitalesScreen({super.key, required this.sintomasSeleccionados});

  @override
  State<SignosVitalesScreen> createState() => _SignosVitalesScreenState();
}

class _SignosVitalesScreenState extends State<SignosVitalesScreen> {
  final TextEditingController _sistolicaCtrl = TextEditingController();
  final TextEditingController _diastolicaCtrl = TextEditingController();
  final RiesgoMaternoModel _model = RiesgoMaternoModel();
  bool _analizando = false;

  final List<String> _sintomasList = [
    'Taquicardia sostenida',
    'Cefalea intensa',
    'Alteración visual',
    'Zumbido oídos',
    'Dolor hipocondrio derecho',
    'Dolor boca estómago',
    'Hinchazón cara manos',
    'Sangrado vaginal',
    'Mareo desmayo',
    'Sudoración fría',
    'Fiebre escalofríos',
    'Hipotermia subjetiva',
    'Flujo vaginal fétido',
    'Dolor abdominal bajo',
    'Pérdida líquido amniótico',
    'Confusión somnolencia',
    'Movimientos fetales disminuidos',
    'Dificultad respirar',
  ];

  List<String> _obtenerSintomasDetectados() {
    return widget.sintomasSeleccionados
        .map((index) => _sintomasList[index])
        .toList();
  }

  Future<Map<String, dynamic>> _obtenerPerfilParaModelo() async {
    try {
      final perfilDb = await LocalDatabase.instance.obtenerPerfil();
      if (perfilDb != null) {
        return perfilDb.toModelInput();
      }
    } catch (e) {
      debugPrint('Error leyendo perfil de SQLite: $e');
    }

    return PerfilGestanteTemp.obtenerParaModelo();
  }

  Future<Map<String, dynamic>> _buildFormData() async {
    final sintomas = widget.sintomasSeleccionados;

    final presionSistolica = int.tryParse(_sistolicaCtrl.text.trim());
    final presionDiastolica = int.tryParse(_diastolicaCtrl.text.trim());

    final perfil = await _obtenerPerfilParaModelo();
    
    // ==========================================
    // PASO 18: IMPRESIONES DE DEBUG COMENTADAS
    // ==========================================
    /*
    final evaluaciones = await LocalDatabase.instance.listarEvaluaciones();

    print('TOTAL EVALUACIONES GUARDADAS: ${evaluaciones.length}');

    for (final e in evaluaciones) {
      print('ID: ${e.idLocal}');
      print('Fecha: ${e.fechaHora}');
      print('Riesgo: ${e.nivelRiesgo}');
      print('Sync: ${e.syncStatus}');
      print('---');
    }
    */
    // ==========================================

    return {
      ...perfil,
      'Presion_Sistolica': presionSistolica ?? 115,
      'Presion_Diastolica': presionDiastolica ?? 75,
      'Taquicardia_Sostenida': sintomas.contains(0) ? 1 : 0,
      'Cefalea_Intensa': sintomas.contains(1) ? 1 : 0,
      'Alteracion_Visual': sintomas.contains(2) ? 1 : 0,
      'Zumbido_Oidos': sintomas.contains(3) ? 1 : 0,
      'Dolor_Hipocondrio_Derecho': sintomas.contains(4) ? 1 : 0,
      'Dolor_Boca_Estomago': sintomas.contains(5) ? 1 : 0,
      'Hinchazon_Cara_Manos': sintomas.contains(6) ? 1 : 0,
      'Sangrado_Vaginal': sintomas.contains(7) ? 1 : 0,
      'Mareo_Desmayo': sintomas.contains(8) ? 1 : 0,
      'Sudoracion_Fria': sintomas.contains(9) ? 1 : 0,
      'Fiebre_Escalofrios': sintomas.contains(10) ? 1 : 0,
      'Hipotermia_Subjetiva': sintomas.contains(11) ? 1 : 0,
      'Flujo_Vaginal_Fetido': sintomas.contains(12) ? 1 : 0,
      'Dolor_Abdominal_Bajo': sintomas.contains(13) ? 1 : 0,
      'Perdida_Liquido_Amniotico': sintomas.contains(14) ? 1 : 0,
      'Confusion_Somnolencia': sintomas.contains(15) ? 1 : 0,
      'Movimientos_Fetales_Disminuidos': sintomas.contains(16) ? 1 : 0,
      'Dificultad_Respirar': sintomas.contains(17) ? 1 : 0,
    };
  }

  Future<void> _analizar() async {
    setState(() {
      _analizando = true;
    });

    try {
      final formData = await _buildFormData();
      print('FORM DATA ENVIADO AL MODELO: $formData');

      final perfilActivo = await LocalDatabase.instance.obtenerPerfil();

      if (perfilActivo == null || perfilActivo.id == null) {
        throw Exception('No hay una cuenta activa para asociar la evaluación.');
      }
      
      await _model.load();

      final resultado = await _model.predictFromMap(formData);
      final sintomasDetectados = _obtenerSintomasDetectados();

      // ==========================================
      // GUARDAR EN LA BASE DE DATOS LOCAL
      // ==========================================
      final now = DateTime.now().toIso8601String();
      final idLocal = const Uuid().v4();

      final evaluacion = EvaluacionRiesgo(
        idLocal: idLocal,
        perfilId: perfilActivo.id!,
        fechaHora: now,
        formData: formData,
        sintomasDetectados: sintomasDetectados,
        nivelRiesgo: resultado['nivel_riesgo'] as String,
        mensaje: resultado['mensaje'] as String,
        probabilidades: resultado['probabilidades'],
        syncStatus: 'pendiente',
      );

      await LocalDatabase.instance.guardarEvaluacion(evaluacion);

      unawaited(
        ConnectivitySyncService.instance.trySyncNow(
          reason: 'nueva evaluación guardada',
        ),
      );
      // ==========================================

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultadoScreen(
            nivelRiesgo: resultado['nivel_riesgo'] as String,
            mensajeModelo: resultado['mensaje'] as String,
            sintomasDetectados: sintomasDetectados,
            probabilidades: resultado['probabilidades'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al analizar el riesgo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _analizando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _sistolicaCtrl.dispose();
    _diastolicaCtrl.dispose();
    _model.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6EA377),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF2CE42C), size: 12),
                  SizedBox(width: 8),
                  Text(
                    'Modo offline',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF6EA377)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6EA377),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ES',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Text(
                      'QU',
                      style: TextStyle(color: Color(0xFF6EA377), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Signos Vitales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Ingresa si tienes estos datos (opcional)',
                style: TextStyle(
                  color: Color(0xFF306339),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
            const SizedBox(height: 30),

            // SECCIÓN: PRESIÓN SISTÓLICA (Arriba)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'PRESIÓN SISTÓLICA - OPCIONAL',
                      style: TextStyle(
                        color: Color(0xFF434C43),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _sistolicaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. 120',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECCIÓN: PRESIÓN DIASTÓLICA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'PRESIÓN DIASTÓLICA - OPCIONAL',
                      style: TextStyle(
                        color: Color(0xFF434C43),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _diastolicaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. 80',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BANNER AMARILLO DE ADVERTENCIA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D8),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFF9E37F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB69500), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Si no tienes los datos, puedes omitirlos. El modelo usará solo tus síntomas.',
                      style: TextStyle(
                        color: Color(0xFFB69500),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // BOTÓN ANALIZAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _analizando ? null : _analizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C924F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _analizando ? 'Analizando...' : 'Analizar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}