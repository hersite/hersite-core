import 'package:flutter/material.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../models/evaluacion_riesgo.dart';
import 'sintomas_screen.dart';
import 'aprende_screen.dart';
import 'perfil_screen.dart';
import 'historial_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recordatorios_screen.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart'; // 🟢 IMPORT CORRECTO
import 'dart:async';

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
  DateTime? _fechaAncla;
  int _notificacionesPendientes = 0;
  List<String> _mensajesNotificacion = [];

  // 🟢 VARIABLES CORREGIDAS PARA LA CONEXIÓN
  bool _hayConexion = false;
  late StreamSubscription<List<ConnectivityResult>> _conexionSubscription;

  @override
  void initState() {
    super.initState();
    _cargarDatosInicio();
    _enviarNotificacionBienvenida(); 
    
    // 1. Revisar estado inicial de red
    _verificarConexionInicial();

    // 2. Escuchar cambios de red usando Connectivity Plus directamente
    _conexionSubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _hayConexion = results.any((result) => result != ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _verificarConexionInicial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hayConexion = results.any((result) => result != ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _conexionSubscription.cancel(); // 🟢 Limpiamos la escucha al salir
    super.dispose();
  }

  Future<void> _enviarNotificacionBienvenida() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'welcome_channel_max', 
      'Mensajes del Sistema',
      channelDescription: 'Mensajes al abrir la app',
      importance: Importance.max, 
      priority: Priority.high,    
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await flutterLocalNotificationsPlugin.show(
      0, 
      '¡Hola de nuevo! 👋',
      'No olvides registrar tus síntomas de hoy.',
      platformDetails,
    );
  }

  Future<void> _cargarDatosInicio() async {
    try {
      final perfil = await LocalDatabase.instance.obtenerPerfil();
      final evaluaciones = await LocalDatabase.instance.listarEvaluaciones();

      final prefs = await SharedPreferences.getInstance();
      String? fechaGuardada = prefs.getString('fecha_ancla_usuario');
      
      if (fechaGuardada == null) {
        _fechaAncla = DateTime.now(); 
        await prefs.setString('fecha_ancla_usuario', _fechaAncla!.toIso8601String());
      } else {
        _fechaAncla = DateTime.parse(fechaGuardada);
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _ultimaEvaluacion = evaluaciones.isNotEmpty ? evaluaciones.first : null;
        _cargando = false;
      });
      
      await _cargarNotificaciones();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  String get _nombreVisible => _perfil?.nombre.trim().isNotEmpty == true ? _perfil!.nombre.trim() : 'Gestante';

  String get _semanasTexto {
    final semanasIngresadas = _perfil?.semanasGestacion;
    if (semanasIngresadas == null || _fechaAncla == null) return '--';
    final diasTranscurridos = DateTime.now().difference(_fechaAncla!).inDays;
    return (semanasIngresadas + (diasTranscurridos / 7).floor()).toString();
  }

  String get _diasParaPartoTexto {
    final semanasIniciales = _perfil?.semanasGestacion;
    if (semanasIniciales == null || _fechaAncla == null) return '--';
    final diasTranscurridos = DateTime.now().difference(_fechaAncla!).inDays;
    final semanasActuales = semanasIniciales + (diasTranscurridos / 7).floor();
    final diasRestantes = ((40 - semanasActuales) * 7) - (diasTranscurridos % 7);
    return diasRestantes <= 0 ? '0' : diasRestantes.toString();
  }

  String get _fechaProbablePartoTexto {
    final semanas = _perfil?.semanasGestacion;
    if (semanas == null) return '--';
    final dias = (40 - semanas) * 7;
    final fecha = DateTime.now().add(Duration(days: dias < 0 ? 0 : dias));
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  String _tituloUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) return 'Última evaluación: Sin registros';
    switch (evaluacion.nivelRiesgo) {
      case 'Riesgo_Alto': return 'Última evaluación: Urgente';
      case 'Riesgo_Medio': return 'Última evaluación: Precaución';
      case 'Riesgo_Bajo': return 'Última evaluación: Estable';
      default: return 'Última evaluación: Registrada';
    }
  }

  String _subtituloUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) return 'Evalúa tus síntomas hoy';
    try {
      final fecha = DateTime.parse(evaluacion.fechaHora);
      return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')} - ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (_) { return 'Fecha reciente'; }
  }

  Color _colorUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) return const Color(0xFF72CA76);
    switch (evaluacion.nivelRiesgo) {
      case 'Riesgo_Alto': return const Color(0xFFD33232);
      case 'Riesgo_Medio': return const Color(0xFFB69500);
      case 'Riesgo_Bajo': return const Color(0xFF4C924F);
      default: return const Color(0xFF72CA76);
    }
  }

  Color _fondoUltimaEvaluacion(EvaluacionRiesgo? evaluacion) {
    if (evaluacion == null) return const Color(0xFFEEFFEF);
    switch (evaluacion.nivelRiesgo) {
      case 'Riesgo_Alto': return const Color(0xFFFCE4E4);
      case 'Riesgo_Medio': return const Color(0xFFFFF7D8);
      case 'Riesgo_Bajo': return const Color(0xFFEEFFEF);
      default: return const Color(0xFFEEFFEF);
    }
  }

  String _imagenTarjeta(String titulo) {
    if (titulo == 'Recordatorios') {
      return 'img/recordatorios_img.png';
    }

    if (titulo == 'Aprende') {
      return 'img/aprender_img.png';
    }

    return 'img/historial_img.png';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(backgroundColor: Color(0xFFFBFFFB), body: Center(child: CircularProgressIndicator(color: Color(0xFF4C924F))));
    }

    if (_error != null) {
      return Scaffold(backgroundColor: const Color(0xFFFBFFFB), body: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error cargando inicio:\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
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
                          
                          // 🟢 BOTÓN DINÁMICO: Sincronizado vs Modo offline
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _hayConexion ? const Color(0xFF2E7D32) : const Color(0xFF6EA377),
                              borderRadius: BorderRadius.circular(15)
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hayConexion ? Icons.wifi : Icons.wifi_off,
                                  color: _hayConexion ? Colors.white : const Color(0xFF2CE42C),
                                  size: 14
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _hayConexion ? 'Sincronizado' : 'Modo offline',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),

                          Badge(
                            isLabelVisible: _notificacionesPendientes > 0,
                            label: Text(_notificacionesPendientes.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.redAccent,
                            child: IconButton(
                              icon: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                              onPressed: () => _verCentroNotificaciones(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text('Buenos días,', style: TextStyle(color: Color(0xFF72CA76), fontSize: 18)),
                      Text(_nombreVisible, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF5A845C), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _datoEmbarazo(_semanasTexto, 'Semana de\ngestación', Colors.white),
                            Container(width: 1, height: 40, color: Colors.white54),
                            _datoEmbarazo(_diasParaPartoTexto, 'Días para el\nparto', const Color(0xFFF9E37F)),
                            Container(width: 1, height: 40, color: Colors.white54),
                            _datoEmbarazo(_fechaProbablePartoTexto, 'Fecha probable\nde parto', const Color(0xFFF9E37F), isText: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(flex: 4, child: _tarjetaEmergencia()),
                            const SizedBox(width: 10),
                            Expanded(flex: 5, child: _tarjetaEvaluacion(_ultimaEvaluacion)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _tarjetaHistorial(),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(child: _tarjetaCuadrada(context, 'Recordatorios')),
                            const SizedBox(width: 10),
                            Expanded(child: _tarjetaCuadrada(context, 'Aprende')),
                          ],
                        ),
                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(                            
                            onPressed: () async {
                              final perfil = await LocalDatabase.instance.obtenerPerfil();
                              if (perfil == null) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero registra tus datos médicos.'), backgroundColor: Colors.redAccent));
                                return;
                              }
                              if (!context.mounted) return;
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => const SintomasScreen()));
                              _cargarDatosInicio();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('Evaluar mis síntomas hoy', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, 
        onTap: (index) async {
          if (index == 0) {
            _cargarDatosInicio(); 
          } else if (index == 1) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistorialScreen()));
            _cargarDatosInicio();
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AprendeScreen()));
          } else if (index == 3) {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
            _cargarDatosInicio(); 
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

  Widget _datoEmbarazo(String valor, String titulo, Color color, {bool isText = false}) {
    return Column(children: [Text(valor, style: TextStyle(color: color, fontSize: isText ? 14 : 24, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(titulo, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10))]);
  }

  Widget _tarjetaEmergencia() {
    return GestureDetector(
      onTap: () async {
        final Uri launchUri = Uri(scheme: 'tel', path: '106');
        if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: const Color(0xFFFCE4E4), border: Border.all(color: const Color(0xFFD33232)), borderRadius: BorderRadius.circular(8)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.phone_in_talk, color: Color(0xFFD33232), size: 16), SizedBox(width: 5), Text('Emergencia', style: TextStyle(color: Color(0xFFD33232), fontWeight: FontWeight.bold, fontSize: 13))]),
      ),
    );
  }

  Widget _tarjetaEvaluacion(EvaluacionRiesgo? evaluacion) {
    final color = _colorUltimaEvaluacion(evaluacion);
    final fondo = _fondoUltimaEvaluacion(evaluacion);
    return Container(
      height: 50, padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: fondo, border: Border.all(color: color), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(evaluacion == null ? Icons.info_outline : Icons.check_box, color: color, size: 20),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tituloUltimaEvaluacion(evaluacion), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text(_subtituloUltimaEvaluacion(evaluacion), style: TextStyle(color: color.withOpacity(0.8), fontSize: 9), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaHistorial() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistorialScreen()),
        );
        _cargarDatosInicio();
      },
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: Image.asset(
                  'img/historial_img.png',
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
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
    final imagen = _imagenTarjeta(titulo);

    return GestureDetector(
      onTap: () async {
        if (titulo == 'Recordatorios') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RecordatoriosScreen(),
            ),
          );
          _cargarNotificaciones();
        } else if (titulo == 'Aprende') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AprendeScreen(),
            ),
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
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  imagen,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
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

  void _verCentroNotificaciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20), height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tus Notificaciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("$_notificacionesPendientes nuevas", style: const TextStyle(color: Color(0xFF4C924F), fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            if (_notificacionesPendientes == 0)
              Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_off, size: 50, color: Colors.grey.shade300), const SizedBox(height: 10), Text("¡Todo al día! No tienes notificaciones.", style: TextStyle(color: Colors.grey.shade600))])),)
            else
             Expanded(
                child: ListView.builder(
                  itemCount: _mensajesNotificacion.length,
                  itemBuilder: (context, index) {
                    bool esCita = _mensajesNotificacion[index].startsWith('📅');
                    
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const RecordatoriosScreen()));
                        _cargarNotificaciones();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFEEFFEF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4C924F).withOpacity(0.3))),
                        child: Row(
                          children: [
                            Icon(esCita ? Icons.calendar_month : Icons.medication, color: const Color(0xFF4C924F)),
                            const SizedBox(width: 15),
                            Expanded(child: Text(_mensajesNotificacion[index], style: const TextStyle(color: Color(0xFF306339), fontWeight: FontWeight.w600))),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF4C924F)), 
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final String? pastillasString = prefs.getString('mis_pastillas');
    final String? citasString = prefs.getString('mis_citas');
    
    int pendientes = 0;
    List<String> mensajes = [];

    if (pastillasString != null && pastillasString.isNotEmpty) {
      final List<dynamic> jsonPastillas = List.from(json.decode(pastillasString));
      for (var item in jsonPastillas) {
        if (item['completado'] == false) {
          pendientes++;
          mensajes.add("💊 Pastilla: ${item['titulo']} a las ${item['hora']}");
        }
      }
    }

    if (citasString != null && citasString.isNotEmpty) {
      final List<dynamic> jsonCitas = List.from(json.decode(citasString));
      for (var item in jsonCitas) {
        if (item['completado'] == false) {
          pendientes++;
          mensajes.add("📅 Cita: ${item['titulo']} el ${item['fecha']} a las ${item['hora']}");
        }
      }
    }

    if (mounted) {
      setState(() {
        _notificacionesPendientes = pendientes;
        _mensajesNotificacion = mensajes;
      });
    }
  }
}