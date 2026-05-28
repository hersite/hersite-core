import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'aprende_screen.dart';
import 'perfil_screen.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // LISTA DE DATOS MOCKADOS (Copiados exactamente de tu Figma para el viernes)
    final List<Map<String, dynamic>> evaluacionesPasadas = [
      {
        'riesgo': 'Alto',
        'titulo': 'Riesgo alto',
        'detalles': 'Visión borrosa, PA alta',
        'fecha': '10 mayo 2026',
        'colorBorde': const Color(0xFFD33232),
        'colorFondo': const Color(0xFFFCE4E4),
        'colorTexto': const Color(0xFF970A0A),
      },
      {
        'riesgo': 'Bajo',
        'titulo': 'Estable',
        'detalles': 'Sin síntomas',
        'fecha': '8 mayo 2026',
        'colorBorde': const Color(0xFF4C924F),
        'colorFondo': const Color(0xFFEEFFEF),
        'colorTexto': const Color(0xFF316533),
      },
      {
        'riesgo': 'Medio',
        'titulo': 'Precaución',
        'detalles': 'Dolor de cabeza',
        'fecha': '5 mayo 2026',
        'colorBorde': const Color(0xFFB69500),
        'colorFondo': const Color(0xFFFFF7D8),
        'colorTexto': const Color(0xFF8A7100),
      },
      {
        'riesgo': 'Bajo',
        'titulo': 'Estable',
        'detalles': 'Sin síntomas',
        'fecha': '2 mayo 2026',
        'colorBorde': const Color(0xFF4C924F),
        'colorFondo': const Color(0xFFEEFFEF),
        'colorTexto': const Color(0xFF316533),
      },
      {
        'riesgo': 'Medio',
        'titulo': 'Precaución',
        'detalles': 'Leve hinchazón',
        'fecha': '28 abril 2026',
        'colorBorde': const Color(0xFFB69500),
        'colorFondo': const Color(0xFFFFF7D8),
        'colorTexto': const Color(0xFF8A7100),
      },
    ];

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
                  Text('Sincronizada', style: TextStyle(color: Colors.white, fontSize: 13)),
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
      body: Column(
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

          // RESUMEN DE CÍRCULOS (Los contadores numéricos de tu diseño)
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
                _buildContadorCirculo('4', const Color(0xFF4C924F)), // Estable (Verde)
                _buildContadorCirculo('2', const Color(0xFFF9E37F)), // Precaución (Amarillo)
                _buildContadorCirculo('1', const Color(0xFFD33232)), // Urgente (Rojo)
              ],
            ),
          ),
          const SizedBox(height: 10),

          // LISTA SCROLLEABLE DE TARJETAS PASADAS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: evaluacionesPasadas.length,
              itemBuilder: (context, index) {
                final item = evaluacionesPasadas[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: item['colorFondo'],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: item['colorBorde'], width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['titulo'],
                            style: TextStyle(color: item['colorTexto'], fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['detalles'],
                            style: const TextStyle(color: Color(0xFF434C43), fontSize: 14, fontFamily: 'Poltawski Nowy'),
                          ),
                        ],
                      ),
                      Text(
                        item['fecha'],
                        style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ==========================================
      // BARRA INFERIOR (HISTORIAL SELECCIONADO - ÍNDICE 1)
      // ==========================================
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // <--- Enciende el segundo ícono (Historial)
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Home()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AprendeScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PerfilScreen()));
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