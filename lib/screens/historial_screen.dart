import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Para formatear la fecha bonito. Agrega 'intl: ^0.19.0' a tu pubspec.yaml si no lo tienes
import '../database/local_database.dart';
import '../models/evaluacion_riesgo.dart';
import '../services/sync_service.dart';
import '../services/connectivity_sync_service.dart';
import 'home_screen.dart';
import 'aprende_screen.dart';
import 'perfil_screen.dart';
import 'detalle_evaluacion_screen.dart'; 
import 'indicador_conexion.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<EvaluacionRiesgo>> _futureEvaluaciones;
  bool _sincronizando = false;
  String _filtroActual = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  void _cargarEvaluaciones() {
    _futureEvaluaciones = LocalDatabase.instance.listarEvaluaciones();
  }

  Future<void> _refrescarEvaluaciones() async {
    setState(() {
      _cargarEvaluaciones();
    });

    await _futureEvaluaciones;
  }

  Future<void> _sincronizarPendientes() async {
    if (_sincronizando) return;

    setState(() {
      _sincronizando = true;
    });

    try {
      final totalSincronizadas =
          await SyncService.instance.sincronizarEvaluacionesPendientesDelPerfilActivo();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            totalSincronizadas == 0
                ? 'No hay evaluaciones pendientes por sincronizar.'
                : 'Se sincronizaron $totalSincronizadas evaluación(es).',
          ),
          backgroundColor: const Color(0xFF4C924F),
        ),
      );

      setState(() {
        _cargarEvaluaciones();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al sincronizar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });
      }
    }
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
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,

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
          
          final evaluacionesFiltradas = evaluaciones.where((e) {
            if (_filtroActual == 'Bajo') return e.nivelRiesgo == 'Riesgo_Bajo';
            if (_filtroActual == 'Medio') return e.nivelRiesgo == 'Riesgo_Medio';
            if (_filtroActual == 'Alto') return e.nivelRiesgo == 'Riesgo_Alto';
            return true; // Si es 'Todos'
          }).toList();

          // Contamos cuántas hay de cada tipo para los círculos de arriba
          int countBajo = evaluaciones.where((e) => e.nivelRiesgo == 'Riesgo_Bajo').length;
          int countMedio = evaluaciones.where((e) => e.nivelRiesgo == 'Riesgo_Medio').length;
          int countAlto = evaluaciones.where((e) => e.nivelRiesgo == 'Riesgo_Alto').length;

          final countPendientes = evaluaciones.where((e) => e.syncStatus == 'pendiente').length;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITULOS DE CABECERA
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF306339), 
                  borderRadius: BorderRadius.circular(15)
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial',
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        fontFamily: 'Poltawski Nowy'
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Tus últimas evaluaciones',
                      style: TextStyle(
                        color: Color(0xFFEEFFEF), 
                        fontSize: 15, 
                        fontFamily: 'Poltawski Nowy'
                      ),
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
                    _buildContadorCirculo(countMedio.toString(), const Color.fromARGB(255, 240, 208, 66)), // Precaución (Amarillo)
                    _buildContadorCirculo(countAlto.toString(), const Color(0xFFD33232)), // Urgente (Rojo)
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: countPendientes > 0
                        ? const Color(0xFFFFF7D8)
                        : const Color(0xFFEEFFEF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: countPendientes > 0
                          ? const Color(0xFFB69500)
                          : const Color(0xFF4C924F),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        countPendientes > 0 ? Icons.cloud_upload : Icons.cloud_done,
                        color: countPendientes > 0
                            ? const Color(0xFFB69500)
                            : const Color(0xFF4C924F),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          countPendientes > 0
                              ? '$countPendientes evaluación(es) pendiente(s) de sincronizar.'
                              : 'Todas tus evaluaciones están sincronizadas.',
                          style: TextStyle(
                            color: countPendientes > 0
                                ? const Color(0xFF8A7100)
                                : const Color(0xFF306339),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (countPendientes > 0)
                        TextButton(
                          onPressed: _sincronizando ? null : _sincronizarPendientes,
                          child: Text(
                            _sincronizando ? 'Enviando...' : 'Sincronizar',
                            style: const TextStyle(
                              color: Color(0xFF306339),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // BARRA DE FILTROS
              _buildFiltros(),

              // LISTA SCROLLEABLE DE TARJETAS DESDE SQLITE
              Expanded(
                child: evaluacionesFiltradas.isEmpty
                    ? const Center(child: Text('No hay evaluaciones para este filtro.', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh:() async {
                          await ConnectivitySyncService.instance.trySyncNow(
                            reason: 'refresco manual de historial',
                          );
                          
                          await _refrescarEvaluaciones();
                        },
                        color: const Color(0xFF4C924F),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: evaluacionesFiltradas.length,
                          itemBuilder: (context, index) {
                            final evaluacion = evaluacionesFiltradas[index];
                            final estilo = _obtenerEstiloPorRiesgo(evaluacion.nivelRiesgo);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleEvaluacionScreen(
                                      evaluacion: evaluacion,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            estilo['titulo'],
                                            style: TextStyle(
                                              color: estilo['colorTexto'],
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Poltawski Nowy',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _resumenSintomas(evaluacion.sintomasDetectados),
                                            style: const TextStyle(
                                              color: Color(0xFF434C43),
                                              fontSize: 14,
                                              fontFamily: 'Poltawski Nowy',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Toca para ver detalle',
                                            style: TextStyle(
                                              color: estilo['colorTexto'],
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatearFecha(evaluacion.fechaHora),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Icon(
                                          evaluacion.syncStatus == 'sincronizado'
                                              ? Icons.cloud_done
                                              : Icons.cloud_off,
                                          size: 14,
                                          color: evaluacion.syncStatus == 'sincronizado'
                                              ? const Color(0xFF4C924F)
                                              : Colors.grey,
                                        ),
                                        const SizedBox(height: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  // EL WIDGET CON LOS BOTONES DE FILTRO
  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, 
        child: Row(
          children: ['Todos', 'Bajo', 'Medio', 'Alto'].map((filtro) {
            bool activo = _filtroActual == filtro;
            return GestureDetector(
              onTap: () => setState(() => _filtroActual = filtro),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: activo ? const Color(0xFF4C924F) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filtro,
                  style: TextStyle(
                    color: activo ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}