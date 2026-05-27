import 'package:flutter/material.dart';
import 'ingresar_screen.dart';  // Conecta con la pantalla de ingreso
import 'registrar_screen.dart';  // Conecta con la pantalla de registro

class InicioPrimer extends StatelessWidget {
  const InicioPrimer({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold es el "lienzo" oficial de una pantalla en Flutter
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1), // Tu fondo verde claro
      // SafeArea evita que el contenido se meta debajo de la cámara o la batería
      body: SafeArea(
        child: Column(
          children: [
            // 1. Botón de Idioma (ES / QU)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0ECE0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF6EA377)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6EA377),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ES',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          'QU',
                          style: TextStyle(color: Color(0xFF6EA377), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(), // Esto empuja mágicamente el círculo al centro

            // 2. Círculo Central con el Logo de tu Tesis
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE0ECE0), // Fondo del círculo
                border: Border.all(color: const Color(0xFF316533), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'img/logo_tesis.png', // La ruta exacta de tu imagen
                  fit: BoxFit.cover, 
                ),
              ),
            ),

            const Spacer(), // Espacio entre el círculo y los botones

            // 3. Botón "INGRESAR" 
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InicioLogin()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF316533),
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
              ),
              child: const Text(
                'INGRESAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20), // Espacio entre botones

            // 4. Botón "REGISTRARSE"
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InicioRegistrarse()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                minimumSize: const Size(220, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.black12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'REGISTRARSE',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 50), // Espacio al fondo de la pantalla
          ],
        ),
      ),
    );
  }
}