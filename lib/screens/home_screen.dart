import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tamaño de la pantalla actual para escalar las posiciones
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      body: Stack(
        children: [
          // Fondo con borde (reemplaza el Container principal)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB9BAB9), width: 16),
            ),
          ),
          
          // Barra superior verde
          Positioned(
            top: size.height * 0.06,
            left: size.width * 0.02,
            right: size.width * 0.02,
            child: Container(
              height: size.height * 0.25,
              color: const Color(0xFF306339),
            ),
          ),

          // Texto "Buenos días, Rosa Huamán"
          Positioned(
            top: size.height * 0.12,
            left: size.width * 0.1,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buenos días,', style: TextStyle(color: Color(0xFF72CA76), fontSize: 18)),
                Text('Rosa Huamán', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Tarjetas de Evaluación (Reemplaza los Positioned fijos)
          Positioned(
            top: size.height * 0.35,
            left: 20,
            right: 20,
            child: Column(
              children: [
                _tarjetaContenedor(height: 40, color: const Color(0xFFFCE4E4), texto: "Emergencia", textColor: Colors.red),
                const SizedBox(height: 15),
                _tarjetaContenedor(height: 40, color: const Color(0xFF4C924F), texto: "Evaluar mis síntomas hoy", textColor: Colors.white),
              ],
            ),
          ),

          // Navegación Inferior (Fija al fondo)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              color: const Color(0xFF306339),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Icon(Icons.home, color: Colors.white),
                  Icon(Icons.history, color: Colors.white),
                  Icon(Icons.school, color: Colors.white),
                  Icon(Icons.person, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaContenedor({required double height, required Color color, required String texto, required Color textColor}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(texto, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
    );
  }
}