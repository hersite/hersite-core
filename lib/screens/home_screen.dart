import 'package:flutter/material.dart';
import 'sintomas_screen.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // ==========================================
                // 1. CABECERA VERDE
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6EA377),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Color(0xFF2CE42C),
                                  size: 12,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Sincronizada',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
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
                        style: TextStyle(
                          color: Color(0xFF72CA76),
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'Rosa Huamán',
                        style: TextStyle(
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
                              '33',
                              'Semana de\ngestación',
                              Colors.white,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white54,
                            ),
                            _datoEmbarazo(
                              '49',
                              'Días para el\nparto',
                              const Color(0xFFF9E37F),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white54,
                            ),
                            _datoEmbarazo(
                              '28 de Junio',
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
                // 2. CONTENIDO CENTRAL (LOS 5 RECUADROS)
                // ==========================================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // FILA 1: Emergencia y Última evaluación
                        Row(
                          children: [
                            Expanded(flex: 4, child: _tarjetaEmergencia()),
                            const SizedBox(width: 10),
                            Expanded(flex: 5, child: _tarjetaEvaluacion()),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // FILA 2: Historial (Ancho completo, imagen a la izquierda)
                        _tarjetaHistorial(),
                        const SizedBox(height: 15),

                        // FILA 3: Recordatorios y Aprende (Imágenes arriba)
                        Row(
                          children: [
                            Expanded(child: _tarjetaCuadrada('Recordatorios')),
                            const SizedBox(width: 10),
                            Expanded(child: _tarjetaCuadrada('Aprende')),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // BOTÓN FINAL
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // AQUÍ ENTRA LA MAGIA DE LA NAVEGACIÓN
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SintomasScreen(),
                                ),
                              );
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

      // ==========================================
      // 3. BARRA INFERIOR
      // ==========================================
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Aprende',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _datoEmbarazo(
    String valor,
    String titulo,
    Color color, {
    bool isText = false,
  }) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: isText ? 16 : 24,
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

  Widget _tarjetaEvaluacion() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEFFEF),
        border: Border.all(color: const Color(0xFF72CA76)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_box, color: Color(0xFF72CA76), size: 20),
          SizedBox(width: 5),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última evaluación: Estable',
                  style: TextStyle(
                    color: Color(0xFF316533),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Ayer: 3:15 pm',
                  style: TextStyle(color: Color(0xFF56A156), fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta Historial (Espacio de imagen a la izquierda)
  Widget _tarjetaHistorial() {
    return Container(
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
          // -----------------------------------------
          // AQUÍ VA TU IMAGEN DE HISTORIAL
          // -----------------------------------------
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color:
                    Colors.grey.shade200, // Quita esto cuando pongas la imagen
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'Espacio\nImagen',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              // TODO: Cuando tengas la imagen, borra el 'child: Center(...)' y descomenta lo de abajo:
              // child: ClipRRect(
              //   borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              //   child: Image.asset('assets/img/historial_img.png', fit: BoxFit.cover),
              // ),
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
    );
  }

  // Tarjetas Recordatorios y Aprende (Espacio de imagen arriba)
  Widget _tarjetaCuadrada(String titulo) {
    return Container(
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
          // -----------------------------------------
          // AQUÍ VA TU IMAGEN CUADRADA
          // -----------------------------------------
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    Colors.grey.shade200, // Quita esto cuando pongas la imagen
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'Espacio Imagen',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              // TODO: Cuando tengas la imagen, borra el 'child: Center(...)' y descomenta lo de abajo:
              // child: ClipRRect(
              //   borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              //   child: Image.asset('assets/img/tu_imagen_aqui.png', fit: BoxFit.cover),
              // ),
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
    );
  }
}
