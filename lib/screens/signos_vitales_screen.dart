import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/evaluacion_riesgo.dart';
import '../services/connectivity_sync_service.dart';
import '../services/riesgo_materno_model.dart';
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
  bool? _presionActualDisponible;

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

  void _seleccionarPresionActualDisponible(bool disponible) {
    setState(() {
      _presionActualDisponible = disponible;

      if (!disponible) {
        _sistolicaCtrl.clear();
        _diastolicaCtrl.clear();
      }
    });
  }

  Future<Map<String, dynamic>> _buildFormData() async {
    if (_presionActualDisponible == null) {
      throw Exception('Indica si tienes una medición de presión actual.');
    }

    int presionSistolica = -1;
    int presionDiastolica = -1;

    if (_presionActualDisponible == true) {
      if (_sistolicaCtrl.text.trim().isEmpty ||
          _diastolicaCtrl.text.trim().isEmpty) {
        throw Exception(
          'Completa la presión sistólica y diastólica, o marca que no tienes la medición actual.',
        );
      }

      final sistolica = int.tryParse(_sistolicaCtrl.text.trim());
      final diastolica = int.tryParse(_diastolicaCtrl.text.trim());

      if (sistolica == null || diastolica == null) {
        throw Exception('Verifica que la presión actual tenga valores numéricos.');
      }

      if (sistolica < 70 || sistolica > 250) {
        throw Exception('La presión sistólica actual debe estar entre 70 y 250.');
      }

      if (diastolica < 40 || diastolica > 160) {
        throw Exception('La presión diastólica actual debe estar entre 40 y 160.');
      }

      if (diastolica >= sistolica) {
        throw Exception(
          'La presión diastólica no puede ser mayor o igual que la sistólica.',
        );
      }

      presionSistolica = sistolica;
      presionDiastolica = diastolica;
    }

    final sintomas = widget.sintomasSeleccionados;
    final perfil = await _obtenerPerfilParaModelo();

    return {
      ...perfil,

      'Presion_Actual_Disponible': _presionActualDisponible == true ? 1 : 0,
      'Presion_Sistolica': presionSistolica,
      'Presion_Diastolica': presionDiastolica,

      'Taquicardia_Sostenida': sintomas.contains(0) ? 1 : 0,
      'Cefalea_Intensa': sintomas.contains(1) ? 1 : 0,
      'Alteracion_Visual': sintomas.contains(2) ? 1 : 0,
      'Zumbido_Oidos': sintomas.contains(3) ? 1 : 0,
      'Dolor_Hipocondrio_Derecho': sintomas.contains(4) ? 1 : 0,
      'Dolor_Boca_Estomago': sintomas.contains(5) ? 1 : 0,
      'Hinchazon_Cara_Manos': sintomas.contains(6) ? 1 : 0,

      // Por ahora: cualquier sangrado marcado en la app se envía como 1.
      // Más adelante se puede separar entre sangrado leve = 1 y abundante = 2.
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
    if (_analizando) return;

    setState(() {
      _analizando = true;
    });

    try {
      final formData = await _buildFormData();

      if (kDebugMode) {
        debugPrint('FORM DATA ENVIADO AL MODELO: $formData');
      }

      final perfilActivo = await LocalDatabase.instance.obtenerPerfil();

      if (perfilActivo == null || perfilActivo.id == null) {
        throw Exception('No hay una cuenta activa para asociar la evaluación.');
      }

      await _model.load();

      final resultado = await _model.predictFromMap(formData);
      final sintomasDetectados = _obtenerSintomasDetectados();

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
                'Ingresa tu presión actual solo si cuentas con una medición.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF306339),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildPresionActualCard(),

            const SizedBox(height: 20),

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
                      'Si no tienes una medición actual de presión, puedes continuar. El modelo usará tus antecedentes y síntomas.',
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

  Widget _buildPresionActualCard() {
    final bool respondido = _presionActualDisponible != null;
    final bool esSi = respondido && _presionActualDisponible == true;
    final bool esNo = respondido && _presionActualDisponible == false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Tienes una medición de presión arterial actual?',
            style: TextStyle(
              color: Color(0xFF434C43),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poltawski Nowy',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Marca “Sí” solo si tienes una medición reciente. Si no la tienes, marca “No”.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontFamily: 'Poltawski Nowy',
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildBotonSiNo(
                  texto: 'Sí',
                  seleccionado: esSi,
                  onTap: () => _seleccionarPresionActualDisponible(true),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildBotonSiNo(
                  texto: 'No',
                  seleccionado: esNo,
                  onTap: () => _seleccionarPresionActualDisponible(false),
                  fondoNoSeleccionado: const Color(0xFFF5F5F5),
                ),
              ),
            ],
          ),
          if (_presionActualDisponible == true) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sistólica',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
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
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diastólica',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
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
              ],
            ),
          ],
          if (_presionActualDisponible == false) ...[
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEFFEF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Se registrará como dato no disponible. La evaluación continuará con tus síntomas y antecedentes.',
                style: TextStyle(
                  color: Color(0xFF306339),
                  fontSize: 13,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBotonSiNo({
    required String texto,
    required bool seleccionado,
    required VoidCallback onTap,
    Color fondoNoSeleccionado = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF4C924F) : fondoNoSeleccionado,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF4C924F)
                : const Color(0xFFB9BAB9),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              color: seleccionado ? Colors.white : const Color(0xFF434C43),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poltawski Nowy',
            ),
          ),
        ),
      ),
    );
  }
}