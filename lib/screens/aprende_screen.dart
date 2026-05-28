import 'package:flutter/material.dart';
import 'home_screen.dart'; // Importamos la pantalla de Inicio para poder regresar

class AprendeScreen extends StatefulWidget {
  const AprendeScreen({super.key});

  @override
  State<AprendeScreen> createState() => _AprendeScreenState();
}

class _AprendeScreenState extends State<AprendeScreen> {
  // Lista dinámica de materiales educativos con diferentes tipos
  final List<Map<String, dynamic>> _materiales = [
    {
      'tipo': 'Audio',
      'titulo': 'Señales de alarma',
      'duracion': '3 minutos',
      'visto': false,
      'completado': false
    },
    {
      'tipo': 'Audio',
      'titulo': 'Control prenatal',
      'duracion': '4 minutos',
      'visto': false,
      'completado': true
    },
    {
      'tipo': 'Artículo',
      'titulo': 'Alimentación clave en el embarazo',
      'duracion': '5 minutos de lectura',
      'visto': false,
      'completado': false
    },
    {
      'tipo': 'Infografía',
      'titulo': 'Posturas para dormir mejor',
      'duracion': 'Visual',
      'visto': false,
      'completado': false
    },
    {
      'tipo': 'Audio',
      'titulo': 'Movimiento del bebé',
      'duracion': '2 minutos',
      'visto': false,
      'completado': false
    },
    {
      'tipo': 'Artículo',
      'titulo': 'Cómo prevenir la preeclampsia',
      'duracion': '7 minutos de lectura',
      'visto': false,
      'completado': false
    },
  ];

  void _toggleCompletado(int index) {
    setState(() {
      _materiales[index]['completado'] = !_materiales[index]['completado'];
    });
  }

  void _toggleVisto(int index) {
    setState(() {
      _materiales[index]['visto'] = !_materiales[index]['visto'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      // Al tener barra inferior, ya no necesitamos la flecha de retroceso (leading) en el AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        automaticallyImplyLeading: false, // Oculta la flecha de volver atrás
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
          // CABECERA VERDE
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF306339),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aprende',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                ),
                SizedBox(height: 5),
                Text(
                  'Información para tu embarazo',
                  style: TextStyle(color: Color(0xFFEEFFEF), fontSize: 15, fontFamily: 'Poltawski Nowy'),
                ),
              ],
            ),
          ),
          
          // LISTA DE MATERIALES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _materiales.length,
              itemBuilder: (context, index) {
                return _buildMaterialCard(index);
              },
            ),
          ),
        ],
      ),
      // ==========================================
      // BARRA INFERIOR CON "APRENDE" SELECCIONADO
      // ==========================================
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white, // El ícono seleccionado será blanco
        unselectedItemColor: Colors.white70, // Los demás un poco opacos
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // <--- ESTO ENCIENDE EL TERCER ÍCONO (Aprende)
        onTap: (index) {
          if (index == 0) {
            // Si tocan "Inicio", regresamos al Home
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Home()),
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

  // WIDGET REUTILIZABLE PARA CADA TARJETA DE MATERIAL
  Widget _buildMaterialCard(int index) {
    final material = _materiales[index];
    final bool completado = material['completado'];
    final bool visto = material['visto'];
    
    // Configuramos texto e ícono dependiendo del tipo
    String textoBotonAccion = '';
    IconData iconoBotonAccion;
    IconData iconoPrincipal;

    if (material['tipo'] == 'Audio') {
      textoBotonAccion = 'Escuchar';
      iconoBotonAccion = Icons.play_arrow;
      iconoPrincipal = Icons.headphones;
    } else if (material['tipo'] == 'Artículo') {
      textoBotonAccion = 'Leer';
      iconoBotonAccion = Icons.menu_book;
      iconoPrincipal = Icons.article;
    } else {
      // Para Infografía u otros
      textoBotonAccion = 'Mirar';
      iconoBotonAccion = Icons.visibility;
      iconoPrincipal = Icons.image;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO E ICONO
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEFFEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconoPrincipal, color: const Color(0xFF306339)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['titulo'],
                      style: const TextStyle(color: Color(0xFF434C43), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${material['tipo']} - ${material['duracion']}',
                      style: const TextStyle(color: Color(0xFF434C43), fontSize: 14, fontFamily: 'Poltawski Nowy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // BOTONES INFERIORES
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleVisto(index),
                  icon: Icon(iconoBotonAccion, color: visto ? Colors.white : const Color(0xFF306339)),
                  label: Text(textoBotonAccion, style: TextStyle(color: visto ? Colors.white : const Color(0xFF306339), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: visto ? const Color(0xFF4C924F) : const Color(0xFFEEFFEF),
                    side: const BorderSide(color: Color(0xFF2CE42C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toggleCompletado(index),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: completado ? const Color(0xFFD9D9D9) : Colors.white,
                    side: const BorderSide(color: Color(0xFFB9BAB9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    completado ? 'Completado' : 'Marcar completado',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF434C43), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}