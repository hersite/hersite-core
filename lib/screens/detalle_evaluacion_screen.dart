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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  _buildFilaInfo('Estado local', _textoSync(evaluacion.syncStatus)),
                  _buildFilaInfo('Nivel registrado', evaluacion.nivelRiesgo),
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
                      'Ninguno o "Me siento bien"',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: evaluacion.sintomasDetectados.map((sintoma) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: estilo['colorFondo'],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: estilo['colorBorde']),
                          ),
                          child: Text(
                            sintoma,
                            style: TextStyle(
                              color: estilo['colorTexto'],
                              fontSize: 13,
                              fontFamily: 'Poly',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 20),

            // =========================
            // PRESIÓN ACTUAL Y ANÁLISIS
            // =========================
            _buildSeccion(
              titulo: 'Signos vitales registrados',
              child: Column(
                children: [
                  _buildFilaInfo(
                    'Presión sistólica',
                    '${evaluacion.formData['Presion_Sistolica'] ?? '--'}',
                  ),
                  _buildFilaInfo(
                    'Presión diastólica',
                    '${evaluacion.formData['Presion_Diastolica'] ?? '--'}',
                  ),
                  _buildFilaInfo(
                    'Presión basal',
                    '${evaluacion.formData['Presion_Basal_Sistolica'] ?? '--'}/${evaluacion.formData['Presion_Basal_Diastolica'] ?? '--'}',
                  ),
                  const Divider(color: Colors.grey, height: 20),
                  // AQUÍ INSERTAMOS TU NUEVA IDEA: EL MENSAJE DE ANÁLISIS DE PRESIÓN
                  _analizarPresion(evaluacion.formData),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =========================
            // PROBABILIDADES
            // =========================
            _buildSeccion(
              titulo: 'Salida del modelo',
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

  // --- NUEVA FUNCIÓN PARA ANALIZAR LA PRESIÓN ---
  Widget _analizarPresion(Map<String, dynamic> data) {
    final int? sistolicaActual = data['Presion_Sistolica'] is int ? data['Presion_Sistolica'] : null;
    final int? diastolicaActual = data['Presion_Diastolica'] is int ? data['Presion_Diastolica'] : null;
    final int? sistolicaBasal = data['Presion_Basal_Sistolica'] is int ? data['Presion_Basal_Sistolica'] : null;
    final int? diastolicaBasal = data['Presion_Basal_Diastolica'] is int ? data['Presion_Basal_Diastolica'] : null;

    // Si falta algún dato, no podemos comparar
    if (sistolicaActual == null || diastolicaActual == null || sistolicaBasal == null || diastolicaBasal == null) {
      return const Text(
        'Faltan datos de presión para realizar una comparación.',
        style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
      );
    }

    final difSistolica = sistolicaActual - sistolicaBasal;
    final difDiastolica = diastolicaActual - diastolicaBasal;

    // Criterio de riesgo: Aumento de 30mmHg en sistólica o 15mmHg en diastólica
    if (difSistolica >= 30 || difDiastolica >= 15) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE4E4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD33232)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD33232)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Alerta: Tu presión ha aumentado significativamente respecto a tu basal (+${difSistolica > 0 ? difSistolica : 0} sis / +${difDiastolica > 0 ? difDiastolica : 0} dia).',
                style: const TextStyle(color: Color(0xFF970A0A), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEFFEF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF4C924F)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF4C924F)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tu presión se mantiene dentro de los márgenes seguros respecto a tu estado antes del embarazo.',
                style: const TextStyle(color: Color(0xFF316533), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- MÉTODOS AUXILIARES ORIGINALES ---

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
      return 'Sincronizado';
    }

    if (syncStatus == 'pendiente') {
      return 'Pendiente de sincronización';
    }

    return syncStatus;
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

          return 'P(Bajo):  ${(bajo * 100).toStringAsFixed(2)}%\n'
              'P(Medio): ${(medio * 100).toStringAsFixed(2)}%\n'
              'P(Alto):  ${(alto * 100).toStringAsFixed(2)}%';
        }

        if (probabilidades.length >= 3) {
          final bajo = (probabilidades[0] as num).toDouble();
          final medio = (probabilidades[1] as num).toDouble();
          final alto = (probabilidades[2] as num).toDouble();

          return 'P(Bajo):  ${(bajo * 100).toStringAsFixed(2)}%\n'
              'P(Medio): ${(medio * 100).toStringAsFixed(2)}%\n'
              'P(Alto):  ${(alto * 100).toStringAsFixed(2)}%';
        }
      }

      return probabilidades.toString();
    } catch (_) {
      return probabilidades.toString();
    }
  }
}