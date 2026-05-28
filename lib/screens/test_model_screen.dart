import 'package:flutter/material.dart';
import '../services/riesgo_materno_model.dart';

class TestModelScreen extends StatefulWidget {
  const TestModelScreen({super.key});

  @override
  State<TestModelScreen> createState() => _TestModelScreenState();
}

class _TestModelScreenState extends State<TestModelScreen> {
  final RiesgoMaternoModel _model = RiesgoMaternoModel();

  String _estado = 'Modelo no probado todavía';
  bool _cargando = false;

  // Función original para probar el JSON
  Future<void> _probarModelo() async {
    setState(() {
      _cargando = true;
      _estado = 'Cargando modelo...';
    });

    try {
      await _model.load();
      final resultado = await _model.predictFromTestFile();

      setState(() {
        _estado = 'PRUEBA DE ARCHIVO ESTÁTICO:\n'
            'Predicción Flutter: ${resultado['nivel_riesgo']}\n'
            'Esperado Python: ${resultado['esperado_python']}\n'
            '¿Coincide?: ${resultado['coincide']}\n\n'
            'Mensaje:\n${resultado['mensaje']}\n\n'
            'Probabilidades:\n${resultado['probabilidades']}';
      });
    } catch (e) {
      setState(() {
        _estado = 'ERROR:\n$e';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  // --- LOS 3 CASOS MANUALES ---

  // 1. El mapa base
  Map<String, dynamic> _casoBaseBajo() {
    return {
      'Edad_Materna': 25,
      'Semanas_Gestacion': 34,
      'Numero_Embarazos': 1,
      'Cesarea_Previa': 0,
      'Diabetes': 0,
      'Hipertension_Previa': 0,
      'Preeclampsia_Previa': 0,
      'Anemia_Gestacional': 0,
      'Presion_Basal_Sistolica': 110,
      'Presion_Basal_Diastolica': 70,
      'Presion_Sistolica': 115,
      'Presion_Diastolica': 75,
      'Taquicardia_Sostenida': 0,
      'Cefalea_Intensa': 0,
      'Alteracion_Visual': 0,
      'Zumbido_Oidos': 0,
      'Dolor_Hipocondrio_Derecho': 0,
      'Dolor_Boca_Estomago': 0,
      'Hinchazon_Cara_Manos': 0,
      'Sangrado_Vaginal': 0,
      'Mareo_Desmayo': 0,
      'Sudoracion_Fria': 0,
      'Fiebre_Escalofrios': 0,
      'Hipotermia_Subjetiva': 0,
      'Flujo_Vaginal_Fetido': 0,
      'Dolor_Abdominal_Bajo': 0,
      'Perdida_Liquido_Amniotico': 0,
      'Confusion_Somnolencia': 0,
      'Movimientos_Fetales_Disminuidos': 0,
      'Dificultad_Respirar': 0,
    };
  }

  // 2. La función general para probar un caso
  Future<void> _probarCasoManual(String nombreCaso, Map<String, dynamic> caso) async {
    setState(() {
      _cargando = true;
      _estado = 'Probando $nombreCaso...';
    });

    try {
      await _model.load();

      final resultado = await _model.predictFromMap(caso);

      setState(() {
        _estado = '$nombreCaso\n\n'
            'Predicción Flutter: ${resultado['nivel_riesgo']}\n\n'
            'Mensaje:\n${resultado['mensaje']}\n\n'
            'Probabilidades:\n${resultado['probabilidades']}';
      });
    } catch (e) {
      setState(() {
        _estado = 'ERROR en $nombreCaso:\n$e';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Integración ML'),
        backgroundColor: const Color(0xFF306339),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando ? null : _probarModelo,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade100),
                child: Text(_cargando ? 'Procesando...' : '1. Verificar Coincidencia Python/Flutter'),
              ),
            ),
            const Divider(height: 30, thickness: 2),
            
            const Text(
              '2. Simulación de Casos Manuales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 15),

            // BOTÓN CASO BAJO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando
                    ? null
                    : () {
                        final caso = _casoBaseBajo();
                        _probarCasoManual('Caso bajo', caso);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEEFFEF), foregroundColor: const Color(0xFF306339)),
                child: const Text('Probar caso bajo'),
              ),
            ),
            const SizedBox(height: 8),

            // BOTÓN CASO MEDIO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando
                    ? null
                    : () {
                        final caso = _casoBaseBajo();
                        caso['Cefalea_Intensa'] = 1; // Alteración para Riesgo Medio
                        caso['Zumbido_Oidos'] = 1;
                        caso['Hinchazon_Cara_Manos'] = 1;

                        // Presión todavía menor a 140/90.
                        caso['Presion_Sistolica'] = 128;
                        caso['Presion_Diastolica'] = 82;
                         
                        _probarCasoManual('Caso medio', caso);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF7D8), foregroundColor: const Color(0xFFB69500)),
                child: const Text('Probar caso medio'),
              ),
            ),
            const SizedBox(height: 8),

            // BOTÓN CASO ALTO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cargando
                    ? null
                    : () {
                        final caso = _casoBaseBajo();
                        caso['Presion_Sistolica'] = 145; // Alteración para Riesgo Alto
                        caso['Presion_Diastolica'] = 92;
                        _probarCasoManual('Caso alto', caso);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCE4E4), foregroundColor: const Color(0xFF970A0A)),
                child: const Text('Probar caso alto'),
              ),
            ),
            const SizedBox(height: 20),

            // ÁREA DE CONSOLA / RESULTADOS
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _estado,
                    style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
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