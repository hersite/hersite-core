import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class RiesgoMaternoModel {
  OrtSession? _session;
  Map<String, dynamic>? _metadata;
  bool _loaded = false;

  // Getter para verificar si ya cargó
  bool get isLoaded => _loaded;

  // Getter inteligente para obtener el orden exacto de las 27 variables del JSON
  List<String> get featureNamesOrden {
    if (_metadata == null) return [];
    return List<String>.from(_metadata!['feature_names_orden'] ?? []);
  }

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

    _validarMetadata(_metadata!);


    _loaded = true;
  }

  void _validarMetadata(Map<String, dynamic> metadata) {
    final requiredKeys = [
      'n_features',
      'feature_names_orden',
      'id_to_class',
      'input_tensor',
      'output_names',
    ];

    for (final key in requiredKeys) {
      if (!metadata.containsKey(key) || metadata[key] == null) {
        throw Exception('El archivo de metadata no contiene la clave requerida: $key');
      }
    }

    final featureOrder = List<String>.from(metadata['feature_names_orden']);
    final nFeatures = metadata['n_features'] as int;

    if (featureOrder.length != nFeatures) {
      throw Exception(
        'Inconsistencia en metadata: feature_names_orden tiene ${featureOrder.length} variables, '
        'pero n_features indica $nFeatures.',
      );
    }
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

  // NUEVA FUNCIÓN: Traduce un mapa del formulario al vector ordenado del modelo
  Future<Map<String, dynamic>> predictFromMap(Map<String, dynamic> formData) async {
    if (!_loaded) await load();

    final metadata = _metadata;
    if (metadata == null) {
      throw Exception('Metadata no cargada.');
    }

    final featureOrder = List<String>.from(metadata['feature_names_orden']);

    final inputVector = featureOrder.map((featureName) {
      final value = formData[featureName];

      if (value == null) {
        throw Exception('Falta el campo requerido por el modelo: $featureName');
      }

      if (value is num) {
        return value.toDouble();
      }

      throw Exception('El campo $featureName debe ser numérico. Valor recibido: $value');
    }).toList();

    return predictFromVector(inputVector);
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

    if (outputNames.length < 2) {
      throw Exception(
        'El modelo ONNX debe tener al menos 2 salidas: etiqueta predicha y probabilidades. '
        'Salidas encontradas: $outputNames',
      );
    }

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
    
    final mensaje = _mensajePorRiesgo(predictedClass);

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

  String _mensajePorRiesgo(String riesgo) {
    switch (riesgo) {
      case 'Riesgo_Bajo':
        return 'Riesgo bajo: no se identifican signos de alarma en este registro. Continúa con tus controles y vuelve a registrar síntomas si aparece alguna molestia.';
      case 'Riesgo_Medio':
        return 'Riesgo medio: acude al centro de salud lo más pronto posible para evaluación.';
      case 'Riesgo_Alto':
        return 'Riesgo alto: acude de inmediato al establecimiento de salud más cercano o solicita ayuda urgente.';
      default:
        return 'No se pudo determinar el mensaje asociado al nivel de riesgo.';
    }
  }

  Future<void> close() async {
    await _session?.close();
    _session = null;
    _loaded = false;
  }
}