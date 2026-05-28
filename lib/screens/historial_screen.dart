import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha bonito. Agrega 'intl: ^0.19.0' a tu pubspec.yaml si no lo tienes
import '../database/local_database.dart';
import '../models/evaluacion_riesgo.dart';
import 'home_screen.dart';
import 'aprende_screen.dart';
import 'perfil_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<EvaluacionRiesgo>> _futureEvaluaciones;

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  void _cargarEvaluaciones() {
    _futureEvaluaciones = LocalDatabase.instance.listarEvaluaciones();
  }

  // --- LÓGICA DE COLORES SEGÚN TU DISEÑO ---
  Map<String, dynamic> _obtenerEstiloPorRiesgo(String nivelRiesgo) {
    if (nivelRiesgo == 'Riesgo_Alto') {
      return {
        'titulo': 'Riesgo alto',
        'colorBorde': const Color(0xFFD33232),
        'colorFondo': const Color(0xFFFCE4E4),
        'colorTexto': const Color(0xFF970A0A),
      };
    } else if (nivelRiesgo == 'Riesgo_Medio') {
      return {
        'titulo': 'Precaución',
        'colorBorde': const Color(0xFFB69500),
        'colorFondo': const Color(0xFFFFF7D8),
        'colorTexto': const Color(0xFF8A7100),
      };
    } else {
      // Riesgo_Bajo
      return {
        'titulo': 'Estable',
        'colorBorde': const Color(0xFF4C924F),
        'colorFondo': const Color(0xFFEEFFEF),
        'colorTexto': const Color(0xFF316533),
      };
    }
  }

  String _resumenSintomas(List<String> sintomas) {
    if (sintomas.isEmpty) return 'Sin síntomas';
    if (sintomas.length <= 2) return sintomas.join(', ');
    return '${sintomas[0]}, ${sintomas[1]}...';
  }

  String _formatearFecha(String fechaIso) {
    try {
      final fecha = DateTime.parse(fechaIso);
      // Ej: 28 mayo 2026
      return "${fecha.day} ${_obtenerMes(fecha.month)} ${fecha.year}";
    } catch (e) {
      return "Fecha reciente";
    }
  }

  String _obtenerMes(int mes) {
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        automaticallyImplyLeading: false, // Pantalla jefa, sin flecha de atrás
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
                  Text('Modo offline', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(14)),
                    ),
                    child: const Text('ES', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: const Text('QU', style: TextStyle(color: Color(0xFF6EA377), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<EvaluacionRiesgo>>(
        future: _futureEvaluaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4C924F)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error cargando historial: ${snapshot.error}'));
          }

          final evaluaciones = snapshot.data ?? [];

          // Contamos cuántas hay de cada tipo para los círculos de arriba
          int countBajo = evaluaciones.where((e) => e.nivelRiesgo == 'Riesgo_Bajo').length;
          int countMedio = evaluaciones.where((e) => e.nivelRiesgo == 'Riesgo_Medio').length;
          int countAlto = evaluaciones.where((e) => e.nivelRiesgo == 'Riesgo_Alto').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITULOS DE CABECERA
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HISTORIAL',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tus últimas evaluaciones',
                      style: TextStyle(color: Color(0xFF306339), fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                    ),
                  ],
                ),
              ),

              // RESUMEN DE CÍRCULOS DINÁMICOS
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildContadorCirculo(countBajo.toString(), const Color(0xFF4C924F)), // Estable (Verde)
                    _buildContadorCirculo(countMedio.toString(), const Color(0xFFF9E37F)), // Precaución (Amarillo)
                    _buildContadorCirculo(countAlto.toString(), const Color(0xFFD33232)), // Urgente (Rojo)
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // LISTA SCROLLEABLE DE TARJETAS DESDE SQLITE
              Expanded(
                child: evaluaciones.isEmpty
                    ? const Center(child: Text('Aún no tienes evaluaciones guardadas.', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: () async => _cargarEvaluaciones(),
                        color: const Color(0xFF4C924F),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: evaluaciones.length,
                          itemBuilder: (context, index) {
                            final evaluacion = evaluaciones[index];
                            final estilo = _obtenerEstiloPorRiesgo(evaluacion.nivelRiesgo);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: estilo['colorFondo'],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: estilo['colorBorde'], width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded( // Expanded evita desbordamientos si el texto es largo
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          estilo['titulo'],
                                          style: TextStyle(color: estilo['colorTexto'], fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _resumenSintomas(evaluacion.sintomasDetectados),
                                          style: const TextStyle(color: Color(0xFF434C43), fontSize: 14, fontFamily: 'Poltawski Nowy'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatearFecha(evaluacion.fechaHora),
                                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      // Pequeño indicador de sync
                                      const SizedBox(height: 4),
                                      Icon(
                                        evaluacion.syncStatus == 'sincronizado' ? Icons.cloud_done : Icons.cloud_off,
                                        size: 14,
                                        color: evaluacion.syncStatus == 'sincronizado' ? const Color(0xFF4C924F) : Colors.grey,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),

      // BARRA INFERIOR INTACTA
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AprendeScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Aprende'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  // Auxiliar para dibujar los circulitos contadores de arriba
  Widget _buildContadorCirculo(String numero, Color color) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              numero,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}