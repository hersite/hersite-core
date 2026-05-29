import 'package:flutter/material.dart';
import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../services/session_state_service.dart';
import 'home_screen.dart';
import 'aprende_screen.dart';
import 'antecedentes_screen.dart';
import 'historial_screen.dart';
import 'inicio_screen.dart';


class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  PerfilGestante? _perfil;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await LocalDatabase.instance.obtenerPerfil();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
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

  String _siNo(int valor) {
    return valor == 1 ? 'Sí' : 'No';
  }

  String get _nombreVisible {
    final nombre = _perfil?.nombre.trim();
    if (nombre == null || nombre.isEmpty) {
      return 'Gestante';
    }
    return nombre;
  }

  // --- WIDGET AUXILIAR PARA LOS ANTECEDENTES ---
  Widget _buildDatoMedico(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF434C43)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF306339),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesionSegura() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            'Se cerrará la sesión actual. Tus datos locales cifrados se conservarán y podrás ingresar nuevamente con tu PIN.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Color(0xFF970A0A)),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    // Limpia solo memoria temporal del flujo.
    PerfilGestanteTemp.limpiar();

    // Marca la sesión como cerrada.
    await SessionStateService.instance.markSessionClosed();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const InicioPrimer(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Control de carga inicial
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBFFFB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4C924F)),
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
              'Error cargando perfil:\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        automaticallyImplyLeading: false,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // CABECERA VERDE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF306339),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Revisa tus datos y antecedentes',
                    style: TextStyle(
                      color: Color(0xFFEEFFEF),
                      fontSize: 15,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // TARJETA 1: DATOS PERSONALES
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DATOS PERSONALES',
                        style: TextStyle(
                          color: Color(0xFF434C43),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poltawski Nowy',
                        ),
                      ),
                      // BOTÓN EDITAR
                      SizedBox(
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            // AQUÍ PONDREMOS EL NAVIGATOR HACIA EDITAR PERFIL
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6EA377),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEFFEF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4C924F)),
                        ),
                        child: const Icon(
                          Icons.pregnant_woman,
                          color: Color(0xFF306339),
                          size: 35,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // --- INFORMACIÓN DINÁMICA DESDE SQLITE ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nombreVisible,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poltawski Nowy',
                              ),
                            ),
                            Text(
                              'Edad materna: ${_perfil?.edadMaterna ?? '--'} años',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Semanas de gestación: ${_perfil?.semanasGestacion ?? '--'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // TARJETA 2: ANTECEDENTES MÉDICOS
            Container(
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
                  const Text(
                    'ANTECEDENTES MÉDICOS',
                    style: TextStyle(
                      color: Color(0xFF434C43),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // --- RESUMEN DE ANTECEDENTES DINÁMICO ---
                  if (_perfil != null) ...[
                    _buildDatoMedico(
                      'Número de embarazos',
                      _perfil!.numeroEmbarazos.toString(),
                    ),
                    _buildDatoMedico(
                      'Presión basal',
                      '${_perfil!.presionBasalSistolica}/${_perfil!.presionBasalDiastolica}',
                    ),
                    _buildDatoMedico(
                      'Cesárea previa',
                      _siNo(_perfil!.cesareaPrevia),
                    ),
                    _buildDatoMedico('Diabetes', _siNo(_perfil!.diabetes)),
                    _buildDatoMedico(
                      'Hipertensión previa',
                      _siNo(_perfil!.hipertensionPrevia),
                    ),
                    _buildDatoMedico(
                      'Pre-eclampsia previa',
                      _siNo(_perfil!.preeclampsiaPrevia),
                    ),
                    _buildDatoMedico(
                      'Anemia gestacional',
                      _siNo(_perfil!.anemiaGestacional),
                    ),
                    const SizedBox(height: 15),
                  ] else ...[
                    const Text(
                      'Aún no hay antecedentes registrados.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // ==========================================
                  // MEJORA APLICADA AQUÍ: Modo Edición Activado
                  // ==========================================
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            // SE ENVÍA esEdicion: true PARA QUE LA PANTALLA SE ADAPTE
                            builder: (context) => const AntecedentesScreen(esEdicion: true),
                          ),
                        );
                        // Al volver de antecedentes, refresca la vista
                        _cargarPerfil();
                      },
                      icon: const Icon(
                        Icons.medical_information,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Actualizar mis antecedentes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C924F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  // ==========================================
                ],
              ),
            ),
            const SizedBox(height: 15),

            // TARJETA 3: SEGURIDAD
            Container(
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
                  const Text(
                    'SEGURIDAD',
                    style: TextStyle(
                      color: Color(0xFF434C43),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.shield,
                            color: Color(0xFFF9E37F),
                            size: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'PIN de acceso: ****',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(
                            color: Color(0xFF4C924F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 45,
              child: TextButton(
                onPressed: () async {
                  await LocalDatabase.instance.eliminarTodo();
                  await SessionStateService.instance.clearSessionStateForDevOnly();
                  PerfilGestanteTemp.limpiar();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Datos locales eliminados para prueba.'),
                      backgroundColor: Colors.orange,
                    ),
                  );

                  _cargarPerfil();
                },
                child: const Text(
                  'Limpiar datos locales (Dev)',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            
            // BOTÓN CERRAR SESIÓN (CONECTADO AL INICIO)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _cerrarSesionSegura,
                  // Destruye todo el historial de pantallas y te manda al login/inicio
                  /*Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InicioPrimer(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },*/
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCE4E4),
                  side: const BorderSide(color: Color(0xFFD33232), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cerrar sesión segura',
                  style: TextStyle(
                    color: Color(0xFF970A0A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // BARRA INFERIOR CON NAVEGACIÓN COMPLETA
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // Icono de Perfil Encendido
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistorialScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AprendeScreen()),
            );
          } else if (index == 3) {
            // Ya estás en Perfil, podrías recargarlo
            _cargarPerfil();
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
}