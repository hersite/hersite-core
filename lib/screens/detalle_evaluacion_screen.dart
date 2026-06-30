import 'package:flutter/material.dart';
import '../models/evaluacion_riesgo.dart';

class DetalleEvaluacionScreen extends StatelessWidget {
  final EvaluacionRiesgo evaluacion;

  const DetalleEvaluacionScreen({
    super.key,
    required this.evaluacion,
  });

  @override
  Widget build(BuildContext context) {
    final estilo = _obtenerEstiloPorRiesgo(evaluacion.nivelRiesgo);
    final fechaTexto = _formatearFechaHora(evaluacion.fechaHora);

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'DETALLE DE EVALUACIÓN',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // =========================
            // TARJETA PRINCIPAL
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: estilo['colorFondo'],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: estilo['colorBorde'],
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 40,
                          color: evaluacion.nivelRiesgo == 'Riesgo_Bajo'
                              ? const Color(0xFF4C924F)
                              : Colors.green.shade100,
                        ),
                        const SizedBox(width: 15),
                        Icon(
                          Icons.circle,
                          size: 40,
                          color: evaluacion.nivelRiesgo == 'Riesgo_Medio'
                              ? const Color(0xFFF9E37F)
                              : Colors.yellow.shade100,
                        ),
                        const SizedBox(width: 15),
                        Icon(
                          Icons.circle,
                          size: 40,
                          color: evaluacion.nivelRiesgo == 'Riesgo_Alto'
                              ? const Color(0xFFD33232)
                              : Colors.red.shade100,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    estilo['titulo'],
                    style: TextStyle(
                      color: estilo['colorBorde'],
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evaluacion.mensaje,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: estilo['colorTexto'],
                      fontSize: 15,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // INFORMACIÓN GENERAL
            // =========================
            _buildSeccion(
              titulo: 'Información de la evaluación',
              child: Column(
                children: [
                  _buildFilaInfo('Fecha y hora', fechaTexto),
                  _buildFilaInfo(
                    'Estado local',
                    _textoSync(evaluacion.syncStatus),
                  ),
                  _buildFilaInfo(
                    'Nivel registrado',
                    _textoNivelRiesgo(evaluacion.nivelRiesgo),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // SÍNTOMAS
            // =========================
            _buildSeccion(
              titulo: 'Síntomas detectados',
              child: evaluacion.sintomasDetectados.isEmpty
                  ? const Text(
                      'Ninguno. La gestante registró que se sentía bien.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: evaluacion.sintomasDetectados.map((sintoma) {
                        final sintomaTexto = _normalizarSintoma(sintoma);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: estilo['colorFondo'],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: estilo['colorBorde']),
                          ),
                          child: Text(
                            sintomaTexto,
                            style: TextStyle(
                              color: estilo['colorTexto'],
                              fontSize: 13,
                              fontFamily: 'Poltawski Nowy',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 20),

            // =========================
            // SIGNOS VITALES
            // =========================
            _buildSeccion(
              titulo: 'Signos vitales registrados',
              child: Column(
                children: [
                  _buildFilaInfo(
                    'Presión actual',
                    _textoPresionActual(evaluacion.formData),
                  ),
                  _buildFilaInfo(
                    'Presión basal',
                    _textoPresionBasal(evaluacion.formData),
                  ),
                  const Divider(color: Colors.grey, height: 20),
                  _analizarPresion(evaluacion.formData),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // PROBABILIDADES
            // =========================
            _buildSeccion(
              titulo: 'Probabilidades del modelo',
              child: Text(
                _formatearProbabilidades(evaluacion.probabilidades),
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: Color(0xFF434C43),
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C924F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Volver al historial',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

  // ============================================================
  // PRESIÓN
  // ============================================================

  int? _leerEntero(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  bool _flagDisponible(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is double) {
      return value.toInt() == 1;
    }

    if (value is num) {
      return value.toInt() == 1;
    }

    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  bool _tienePresionActualValida(Map<String, dynamic> data) {
    final disponible = _flagDisponible(data, 'Presion_Actual_Disponible');
    final sistolica = _leerEntero(data, 'Presion_Sistolica');
    final diastolica = _leerEntero(data, 'Presion_Diastolica');

    return disponible &&
        sistolica != null &&
        diastolica != null &&
        sistolica > 0 &&
        diastolica > 0;
  }

  bool _tienePresionBasalValida(Map<String, dynamic> data) {
    final disponible = _flagDisponible(data, 'Presion_Basal_Disponible');
    final sistolica = _leerEntero(data, 'Presion_Basal_Sistolica');
    final diastolica = _leerEntero(data, 'Presion_Basal_Diastolica');

    return disponible &&
        sistolica != null &&
        diastolica != null &&
        sistolica > 0 &&
        diastolica > 0;
  }

  String _textoPresionActual(Map<String, dynamic> data) {
    if (!_tienePresionActualValida(data)) {
      return 'No registrada';
    }

    final sistolica = _leerEntero(data, 'Presion_Sistolica')!;
    final diastolica = _leerEntero(data, 'Presion_Diastolica')!;

    return '$sistolica/$diastolica mmHg';
  }

  String _textoPresionBasal(Map<String, dynamic> data) {
    if (!_tienePresionBasalValida(data)) {
      return 'No registrada';
    }

    final sistolica = _leerEntero(data, 'Presion_Basal_Sistolica')!;
    final diastolica = _leerEntero(data, 'Presion_Basal_Diastolica')!;

    return '$sistolica/$diastolica mmHg';
  }

  Widget _analizarPresion(Map<String, dynamic> data) {
    final tieneActual = _tienePresionActualValida(data);
    final tieneBasal = _tienePresionBasalValida(data);

    if (!tieneActual) {
      return _buildMensajeInfo(
        icono: Icons.info_outline,
        color: const Color(0xFF6A6A6A),
        fondo: const Color(0xFFF5F5F5),
        borde: Colors.grey.shade400,
        texto:
            'No se registró presión actual en esta evaluación. Por ello, no se realiza comparación de presión.',
      );
    }

    final sistolicaActual = _leerEntero(data, 'Presion_Sistolica')!;
    final diastolicaActual = _leerEntero(data, 'Presion_Diastolica')!;

    if (sistolicaActual >= 140 || diastolicaActual >= 90) {
      return _buildMensajeInfo(
        icono: Icons.warning_amber_rounded,
        color: const Color(0xFFD33232),
        fondo: const Color(0xFFFCE4E4),
        borde: const Color(0xFFD33232),
        texto:
            'Alerta: La presión actual registrada es elevada. Se recomienda acudir al establecimiento de salud o solicitar ayuda.',
      );
    }

    if (!tieneBasal) {
      return _buildMensajeInfo(
        icono: Icons.info_outline,
        color: const Color(0xFFB69500),
        fondo: const Color(0xFFFFF7D8),
        borde: const Color(0xFFF9E37F),
        texto:
            'Se registró presión actual, pero no presión basal. No es posible comparar con la presión habitual.',
      );
    }

    final sistolicaBasal = _leerEntero(data, 'Presion_Basal_Sistolica')!;
    final diastolicaBasal = _leerEntero(data, 'Presion_Basal_Diastolica')!;

    final difSistolica = sistolicaActual - sistolicaBasal;
    final difDiastolica = diastolicaActual - diastolicaBasal;

    if (difSistolica >= 30 || difDiastolica >= 15) {
      return _buildMensajeInfo(
        icono: Icons.warning_amber_rounded,
        color: const Color(0xFFD33232),
        fondo: const Color(0xFFFCE4E4),
        borde: const Color(0xFFD33232),
        texto:
            'Alerta: La presión aumentó significativamente respecto a la presión basal registrada.',
      );
    }

    return _buildMensajeInfo(
      icono: Icons.check_circle_outline,
      color: const Color(0xFF4C924F),
      fondo: const Color(0xFFEEFFEF),
      borde: const Color(0xFF4C924F),
      texto:
          'La presión actual registrada no supera los umbrales de alerta y no muestra un aumento importante respecto a la presión basal.',
    );
  }

  Widget _buildMensajeInfo({
    required IconData icono,
    required Color color,
    required Color fondo,
    required Color borde,
    required String texto,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borde),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poltawski Nowy',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AUXILIARES VISUALES
  // ============================================================

  Map<String, dynamic> _obtenerEstiloPorRiesgo(String nivelRiesgo) {
    if (nivelRiesgo == 'Riesgo_Alto') {
      return {
        'titulo': 'Riesgo alto',
        'colorBorde': const Color(0xFFD33232),
        'colorFondo': const Color(0xFFFCE4E4),
        'colorTexto': const Color(0xFF970A0A),
      };
    }

    if (nivelRiesgo == 'Riesgo_Medio') {
      return {
        'titulo': 'Precaución',
        'colorBorde': const Color(0xFFB69500),
        'colorFondo': const Color(0xFFFFF7D8),
        'colorTexto': const Color(0xFF8A7100),
      };
    }

    return {
      'titulo': 'Estable',
      'colorBorde': const Color(0xFF4C924F),
      'colorFondo': const Color(0xFFEEFFEF),
      'colorTexto': const Color(0xFF316533),
    };
  }

  Widget _buildSeccion({
    required String titulo,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poltawski Nowy',
              color: Color(0xFF434C43),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildFilaInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF434C43),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF306339),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _textoSync(String syncStatus) {
    if (syncStatus == 'sincronizado') {
      return 'Sincronizado con la obstetra';
    }

    if (syncStatus == 'pendiente') {
      return 'Pendiente de sincronización';
    }

    return syncStatus;
  }

  String _textoNivelRiesgo(String nivelRiesgo) {
    if (nivelRiesgo == 'Riesgo_Bajo') {
      return 'Riesgo bajo';
    }

    if (nivelRiesgo == 'Riesgo_Medio') {
      return 'Riesgo medio';
    }

    if (nivelRiesgo == 'Riesgo_Alto') {
      return 'Riesgo alto';
    }

    return nivelRiesgo;
  }

  String _formatearFechaHora(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);

      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = fecha.month.toString().padLeft(2, '0');
      final anio = fecha.year.toString();

      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');

      return '$dia/$mes/$anio $hora:$minuto';
    } catch (_) {
      return 'Fecha reciente';
    }
  }

  String _normalizarSintoma(String sintoma) {
    final limpio = sintoma.trim();

    const equivalencias = {
      'Taquicardia sostenida': 'Taquicardia sostenida',
      'Cefalea intensa': 'Cefalea intensa',
      'Alteración visual': 'Alteración visual',
      'Zumbido oídos': 'Zumbido de oídos',
      'Zumbido de oídos': 'Zumbido de oídos',
      'Dolor hipocondrio derecho': 'Dolor en hipocondrio derecho',
      'Dolor en hipocondrio derecho': 'Dolor en hipocondrio derecho',
      'Dolor boca estómago': 'Dolor en boca del estómago',
      'Dolor en boca del estómago': 'Dolor en boca del estómago',
      'Hinchazón cara manos': 'Hinchazón en cara y manos',
      'Hinchazón en cara y manos': 'Hinchazón en cara y manos',
      'Sangrado vaginal': 'Sangrado vaginal',
      'Mareo desmayo': 'Mareo o desmayo',
      'Mareo o desmayo': 'Mareo o desmayo',
      'Sudoración fría': 'Sudoración fría',
      'Fiebre escalofríos': 'Fiebre o escalofríos',
      'Fiebre o escalofríos': 'Fiebre o escalofríos',
      'Hipotermia subjetiva': 'Sensación de hipotermia',
      'Sensación de hipotermia': 'Sensación de hipotermia',
      'Flujo vaginal fétido': 'Flujo vaginal fétido',
      'Dolor abdominal bajo': 'Dolor abdominal bajo',
      'Pérdida líquido amniótico': 'Pérdida de líquido amniótico',
      'Pérdida de líquido amniótico': 'Pérdida de líquido amniótico',
      'Confusión somnolencia': 'Confusión o somnolencia',
      'Confusión o somnolencia': 'Confusión o somnolencia',
      'Movimientos fetales disminuidos': 'Movimientos fetales disminuidos',
      'Dificultad respirar': 'Dificultad para respirar',
      'Dificultad para respirar': 'Dificultad para respirar',
    };

    return equivalencias[limpio] ?? limpio;
  }

  String _formatearProbabilidades(dynamic probabilidades) {
    if (probabilidades == null) {
      return 'No se registraron probabilidades.';
    }

    try {
      if (probabilidades is List && probabilidades.isNotEmpty) {
        final primeraFila = probabilidades.first;

        if (primeraFila is List && primeraFila.length >= 3) {
          final bajo = (primeraFila[0] as num).toDouble();
          final medio = (primeraFila[1] as num).toDouble();
          final alto = (primeraFila[2] as num).toDouble();

          return 'Riesgo bajo:  ${(bajo * 100).toStringAsFixed(2)}%\n'
              'Riesgo medio: ${(medio * 100).toStringAsFixed(2)}%\n'
              'Riesgo alto:  ${(alto * 100).toStringAsFixed(2)}%';
        }

        if (probabilidades.length >= 3) {
          final bajo = (probabilidades[0] as num).toDouble();
          final medio = (probabilidades[1] as num).toDouble();
          final alto = (probabilidades[2] as num).toDouble();

          return 'Riesgo bajo:  ${(bajo * 100).toStringAsFixed(2)}%\n'
              'Riesgo medio: ${(medio * 100).toStringAsFixed(2)}%\n'
              'Riesgo alto:  ${(alto * 100).toStringAsFixed(2)}%';
        }
      }

      return probabilidades.toString();
    } catch (_) {
      return probabilidades.toString();
    }
  }
}