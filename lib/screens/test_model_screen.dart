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

  Future<void> _probarModelo() async {
    setState(() {
      _cargando = true;
      _estado = 'Cargando modelo...';
    });

    try {
      await _model.load();

      final resultado = await _model.predictFromTestFile();

      setState(() {
        _estado =
            'Predicción Flutter: ${resultado['nivel_riesgo']}\n'
            'Esperado Python: ${resultado['esperado_python']}\n'
            '¿Coincide?: ${resultado['coincide']}\n\n'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba Modelo ML'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _cargando ? null : _probarModelo,
              child: Text(_cargando ? 'Probando...' : 'Probar modelo ONNX'),
            ),
            const SizedBox(height: 24),
            Text(
              _estado,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}