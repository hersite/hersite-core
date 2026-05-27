import 'package:flutter/material.dart';
import 'screens/inicio_screen.dart'; // Aquí importamos tu carpeta

void main() {
  runApp(const MiAppTesis());
}

class MiAppTesis extends StatelessWidget {
  const MiAppTesis({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Esto quita la cinta roja fea de "DEBUG"
      title: 'App Gestantes',
      home: InicioPrimer(), // ¡Aquí llamamos a tu pantalla de Figma!
    );
  }
}