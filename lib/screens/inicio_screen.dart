import 'package:flutter/material.dart';
import 'ingresar_screen.dart';
import 'registrar_screen.dart';
import '../widgets/app_logo.dart';

class InicioPrimer extends StatelessWidget {
  const InicioPrimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Logo (el círculo)
            const AppLogo(size: 280),

            const Spacer(),

            // Botones (usando Expanded para que tengan el mismo tamaño)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const InicioLogin(modoCuentaActiva: false),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF316533),
                      ),
                      child: const Text(
                        'INGRESAR',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InicioRegistrarse(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black),
                      ),
                      child: const Text(
                        'REGISTRARSE',
                        style: TextStyle(color: Colors.black, fontSize: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
