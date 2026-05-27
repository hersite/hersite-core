import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class RiesgoMaternoModel {
  OrtSession? _session;
  Map<String, dynamic>? _metadata;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final ort = OnnxRuntime();

    _session = await ort.createSessionFromAsset(
      'assets/ml/modelo_riesgo_materno.onnx',
    );

    final metadataString = await rootBundle.loadString(
      'assets/ml/modelo_riesgo_materno_features.json',
    );

    _metadata = jsonDecode(metadataString) as Map<String, dynamic>;

    _loaded = true;
  }

  Future<Map<String, dynamic>> predictFromTestFile() async {
    if (!_loaded) {
      throw Exception('Primero debes cargar el modelo con load().');
    }

    final testString = await rootBundle.loadString(
      'assets/ml/caso_prueba_flutter.json',
    );

    final testData = jsonDecode(testString) as Map<String, dynamic>;

    final inputVector = (testData['input_vector'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    final resultado = await predictFromVector(inputVector);

    final esperadoPython = testData['prediccion_clase'] as String;

    return {
      ...resultado,
      'esperado_python': esperadoPython,
      'coincide': resultado['nivel_riesgo'] == esperadoPython,
    };
  }

  Future<Map<String, dynamic>> predictFromVector(List<double> inputVector) async {
    final session = _session;
    final metadata = _metadata;

    if (session == null || metadata == null) {
      throw Exception('Modelo o metadata no cargados.');
    }

    final inputName = metadata['input_tensor'] as String;
    final outputNames = List<String>.from(metadata['output_names']);
    final idToClass = Map<String, dynamic>.from(metadata['id_to_class']);
    final mensajes = Map<String, dynamic>.from(metadata['mensajes']);

    final nFeatures = metadata['n_features'] as int;

    if (inputVector.length != nFeatures) {
      throw Exception(
        'El vector tiene ${inputVector.length} features, pero el modelo espera $nFeatures.',
      );
    }

    final inputTensor = await OrtValue.fromList(
      inputVector,
      [1, inputVector.length],
    );

    final inputs = {
      inputName: inputTensor,
    };

    final outputs = await session.run(inputs);

    final labelOutputName = outputNames[0];
    final probaOutputName = outputNames[1];

    final labelRaw = await outputs[labelOutputName]!.asList();
    final probaRaw = await outputs[probaOutputName]!.asList();

    final predictedId = (labelRaw.first as num).toInt();
    final predictedClass = idToClass[predictedId.toString()] as String;
    final mensaje = mensajes[predictedClass] as String;

    inputTensor.dispose();

    for (final output in outputs.values) {
      output.dispose();
    }

    return {
      'predicted_id': predictedId,
      'nivel_riesgo': predictedClass,
      'mensaje': mensaje,
      'probabilidades': probaRaw,
    };
  }

  Future<void> close() async {
    await _session?.close();
    _session = null;
    _loaded = false;
  }
}