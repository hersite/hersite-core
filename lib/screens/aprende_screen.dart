import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import 'historial_screen.dart'; 
import 'perfil_screen.dart';

class AprendeScreen extends StatefulWidget {
  const AprendeScreen({super.key});

  @override
  State<AprendeScreen> createState() => _AprendeScreenState();
}

class _AprendeScreenState extends State<AprendeScreen> {
  // Variable para controlar el filtro actual
  String _filtroActual = 'Todos';

  final List<Map<String, dynamic>> _materiales = [
    {'tipo': 'Audio', 'titulo': 'Señales de alarma', 'duracion': '3 minutos', 'visto': false, 'completado': false},
    {'tipo': 'Audio', 'titulo': 'Control prenatal', 'duracion': '4 minutos', 'visto': false, 'completado': true},
    {'tipo': 'Artículo', 'titulo': 'Alimentación clave en el embarazo', 'duracion': '5 minutos de lectura', 'visto': false, 'completado': false},
    {'tipo': 'Infografía', 'titulo': 'Posturas para dormir mejor', 'duracion': 'Visual', 'visto': false, 'completado': false},
    {'tipo': 'Audio', 'titulo': 'Movimiento del bebé', 'duracion': '2 minutos', 'visto': false, 'completado': false},
    {'tipo': 'Artículo', 'titulo': 'Cómo prevenir la preeclampsia', 'duracion': '7 minutos de lectura', 'visto': false, 'completado': false},
  ];

  void _toggleCompletado(int index, Map<String, dynamic> materialReal) {
    setState(() {
      // Buscamos el índice real en la lista original para no cruzar datos al filtrar
      int realIndex = _materiales.indexOf(materialReal);
      _materiales[realIndex]['completado'] = !_materiales[realIndex]['completado'];
    });
  }

  void _toggleVisto(int index, Map<String, dynamic> materialReal) {
    setState(() {
      int realIndex = _materiales.indexOf(materialReal);
      _materiales[realIndex]['visto'] = !_materiales[realIndex]['visto'];
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 LÓGICA DE FILTRADO
    List<Map<String, dynamic>> materialesFiltrados = _materiales.where((m) {
      if (_filtroActual == 'Pendientes') return !m['completado'];
      if (_filtroActual == 'Completados') return m['completado'];
      return true; // Para 'Todos'
    }).toList();

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
              decoration: BoxDecoration(color: const Color(0xFF6EA377), borderRadius: BorderRadius.circular(15)),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Color(0xFF2CE42C), size: 12),
                  SizedBox(width: 8),
                  Text('Modo offline', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF306339), borderRadius: BorderRadius.circular(15)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aprende', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                SizedBox(height: 5),
                Text('Información para tu embarazo', style: TextStyle(color: Color(0xFFEEFFEF), fontSize: 15, fontFamily: 'Poltawski Nowy')),
              ],
            ),
          ),
          
          // 🟢 BOTONES DE FILTRO AGREGADOS
          _buildFiltros(),

          // LISTA DE MATERIALES
          Expanded(
            child: materialesFiltrados.isEmpty 
              ? Center(child: Text('No hay materiales en esta sección.', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: materialesFiltrados.length,
                  itemBuilder: (context, index) {
                    return _buildMaterialCard(index, materialesFiltrados[index]);
                  },
                ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF306339),
        selectedItemColor: Colors.white, 
        unselectedItemColor: Colors.white70, 
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, 
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HistorialScreen()));
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

  // 🟢 WIDGET DE FILTROS
  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['Pendientes', 'Completados', 'Todos'].map((filtro) {
          bool activo = _filtroActual == filtro;
          return GestureDetector(
            onTap: () => setState(() => _filtroActual = filtro),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: activo ? const Color(0xFF4C924F) : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: Text(filtro, style: TextStyle(color: activo ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
           );
        }).toList(),
      ),
    );
  }

  Widget _buildMaterialCard(int index, Map<String, dynamic> material) {
    final bool completado = material['completado'];
    final bool visto = material['visto'];

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
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFFEEFFEF), borderRadius: BorderRadius.circular(8)),
                child: Icon(iconoPrincipal, color: const Color(0xFF306339)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material['titulo'], style: const TextStyle(color: Color(0xFF434C43), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                    const SizedBox(height: 5),
                    Text('${material['tipo']} - ${material['duracion']}', style: const TextStyle(color: Color(0xFF434C43), fontSize: 14, fontFamily: 'Poltawski Nowy')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _toggleVisto(index, material);
                    // AQUÍ LUEGO AGREGAREMOS LA NAVEGACIÓN PARA ABRIR EL AUDIO/IMAGEN
                  },
                  icon: Icon(iconoBotonAccion, color: visto ? Colors.white : const Color(0xFF306339)),
                  label: Text(textoBotonAccion, style: TextStyle(color: visto ? Colors.white : const Color(0xFF306339), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: visto ? const Color(0xFF4C924F) : const Color(0xFFEEFFEF), side: const BorderSide(color: Color(0xFF2CE42C)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toggleCompletado(index, material),
                  style: OutlinedButton.styleFrom(backgroundColor: completado ? const Color(0xFFD9D9D9) : Colors.white, side: const BorderSide(color: Color(0xFFB9BAB9)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: Text(completado ? 'Completado' : 'Marcar', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF434C43), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}