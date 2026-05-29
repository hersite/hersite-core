import 'package:flutter/material.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../models/evaluacion_riesgo.dart';
import 'sintomas_screen.dart';
import 'aprende_screen.dart';
import 'perfil_screen.dart';
import 'historial_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  PerfilGestante? _perfil;
  EvaluacionRiesgo? _ultimaEvaluacion;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosInicio();
  }

  // Carga el perfil y las evaluaciones guardadas en el disco del celular
  Future<void> _cargarDatosInicio() async {
    try {
      final perfil = await LocalDatabase.instance.obtenerPerfil();
      final evaluaciones = await LocalDatabase.instance.listarEvaluaciones();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _ultimaEvaluacion = evaluaciones.isNotEmpty ? evaluaciones.first : null;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  // --- GETTERS Y FUNCIONES AUXILIARES PARA DATOS REALES ---
  String get _nombreVisible {
    final nombre = _perfil?.nombre.trim();
    if (nombre == null || nombre.isEmpty) {
      return 'Gestante';
    }
    return nombre;
  }

  String get _semanasTexto {
    final semanas = _perfil?.semanasGestacion;
    if (semanas == null) return '--';
    return semanas.toString();
  }

  String get _diasParaPartoTexto {
    final semanas = _perfil?.semanasGestacion;
    if (semanas == null) return '--';
    final dias = (40 - semanas) * 7;
    return dias <= 0 ? '0' : dias.toString();
  }

  String get _fechaProbablePartoTexto {
    final semanas = _perfil?.semanasGestacion;
    if (semanas == null) return '--';
    final dias = (40 - semanas) * 7;
    final fecha = DateTime.now().add(Duration(days: dias < 0 ? 0 : dias));
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String _tituloUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) {
      return 'Última evaluación: Sin registros';
    }
    switch (evaluacion.nivelRiesgo) {
      case 'Riesgo_Alto':
        return 'Última evaluación: Urgente';
      case 'Riesgo_Medio':
        return 'Última evaluación: Precaución';
      case 'Riesgo_Bajo':
        return 'Última evaluación: Estable';
      default:
        return 'Última evaluación: Registrada';
    }
  }

  String _subtituloUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) {
      return 'Evalúa tus síntomas hoy';
    }
    try {
      final fecha = DateTime.parse(evaluacion.fechaHora);
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} - $hora:$minuto';
    } catch (_) {
      return 'Fecha reciente';
    }
  }

  Color _colorUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) return const Color(0xFF72CA76);
    switch (evaluacion.nivelRiesgo) {
      case 'Riesgo_Alto':
        return const Color(0xFFD33232);
      case 'Riesgo_Medio':
        return const Color(0xFFB69500);
      case 'Riesgo_Bajo':
        return const Color(0xFF4C924F);
      default:
        return const Color(0xFF72CA76);
    }
  }

  Color _fondoUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) return const Color(0xFFEEFFEF);
    switch (evaluacion.nivelRiesgo) {
      case 'Riesgo_Alto':
        return const Color(0xFFFCE4E4);
      case 'Riesgo_Medio':
        return const Color(0xFFFFF7D8);
      case 'Riesgo_Bajo':
        return const Color(0xFFEEFFEF);
      default:
        return const Color(0xFFEEFFEF);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Control de estado de carga inicial
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBFFFB),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4C924F),
          ),
        ),
      );
    }

    // Control de errores de base de datos
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFFFB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error cargando inicio:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // ==========================================
                // 1. CABECERA VERDE (DINÁMICA DESDE SQLITE)
                // ==========================================
                Container(
                  width: double.infinity,
                  color: const Color(0xFF306339),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6EA377),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: Color(0xFF2CE42C), size: 12),
                                SizedBox(width: 5),
                                Text(
                                  'Modo offline',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6EA377),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'ES | QU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Buenos días,',
                        style: TextStyle(color: Color(0xFF72CA76), fontSize: 18),
                      ),
                      Text(
                        _nombreVisible, // Nombre dinámico desde la Base de Datos
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5A845C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _datoEmbarazo(
                              _semanasTexto, // Semana de gestación calculada
                              'Semana de\ngestación',
                              Colors.white,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white54,
                            ),
                            _datoEmbarazo(
                              _diasParaPartoTexto, // Días matemáticos restantes
                              'Días para el\nparto',
                              const Color(0xFFF9E37F),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white54,
                            ),
                            _datoEmbarazo(
                              _fechaProbablePartoTexto, // Fecha estimada real
                              'Fecha probable\nde parto',
                              const Color(0xFFF9E37F),
                              isText: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // 2. CONTENIDO CENTRAL (TARJETAS REALES)
                // ==========================================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // FILA 1: Emergencia y Última evaluación (Pasa el objeto de SQLite)
                        Row(
                          children: [
                            Expanded(flex: 4, child: _tarjetaEmergencia()),
                            const SizedBox(width: 10),
                            Expanded(flex: 5, child: _tarjetaEvaluacion(_ultimaEvaluacion)),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // FILA 2: Historial (Ancho completo, imagen a la izquierda)
                        _tarjetaHistorial(),
                        const SizedBox(height: 15),

                        // FILA 3: Recordatorios y Aprende (Imágenes arriba)
                        Row(
                          children: [
                            Expanded(
                              child: _tarjetaCuadrada(context, 'Recordatorios'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _tarjetaCuadrada(context, 'Aprende'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // BOTÓN EVALUAR SÍNTOMAS (CON RECARGA AUTOMÁTICA)
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(                            
                            /*onPressed: () async {
                              // Espera a que termine la evaluación en las siguientes pantallas
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SintomasScreen(),
                                ),
                              );
                              // Cuando la usuaria vuelve de ResultadoScreen, el Home se refresca solo
                              _cargarDatosInicio();
                            },*/

                            onPressed: () async {
                              final perfil = await LocalDatabase.instance.obtenerPerfil();

                              if (perfil == null) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Primero registra tus datos y antecedentes médicos.'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              if (!context.mounted) return;

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SintomasScreen(),
                                ),
                              );
                              _cargarDatosInicio();
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4C924F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Evaluar mis síntomas hoy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // BARRA INFERIOR (CONECTADA COMPLETA)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Icono Home encendido por defecto
        onTap: (index) {
          if (index == 0) {
            _cargarDatosInicio(); // Refresca si presiona Home otra vez
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistorialScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AprendeScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PerfilScreen()),
            );
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

  // --- MÉTODOS AUXILIARES DE RENDERIZADO VISUAL ---

  Widget _datoEmbarazo(String valor, String titulo, Color color, {bool isText = false}) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: isText ? 14 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _tarjetaEmergencia() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E4),
        border: Border.all(color: const Color(0xFFD33232)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_in_talk, color: Color(0xFFD33232), size: 16),
          SizedBox(width: 5),
          Text(
            'Emergencia',
            style: TextStyle(
              color: Color(0xFFD33232),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA DE ÚLTIMA EVALUACIÓN ACTUALIZADA CON SEMÁFORO DINÁMICO
  Widget _tarjetaEvaluacion(EvaluacionRiesgo? evaluacion) {
    final color = _colorUltimaEvaluacion(evaluacion);
    final fondo = _fondoUltimaEvaluacion(evaluacion);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fondo,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            evaluacion == null ? Icons.info_outline : Icons.check_box,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tituloUltimaEvaluacion(evaluacion),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtituloUltimaEvaluacion(evaluacion),
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaHistorial() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistorialScreen()),
        );
      },
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: const Center(
                  child: Text(
                    'Espacio\nImagen',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ),
            const Expanded(
              flex: 6,
              child: Center(
                child: Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaCuadrada(BuildContext context, String titulo) {
    return GestureDetector(
      onTap: () {
        if (titulo == 'Aprende') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AprendeScreen()),
          );
        }
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Center(
                  child: Text(
                    'Espacio Imagen',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
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