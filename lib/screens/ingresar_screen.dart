import 'package:flutter/material.dart';
import 'home_screen.dart';

class InicioLogin extends StatelessWidget {
  const InicioLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SafeArea(
        child: Center( // Center asegura que todo esté al medio horizontalmente
          child: SingleChildScrollView( // SingleChildScrollView ayuda si el teclado tapa algo
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF316533))),
                  child: ClipOval(child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover)),
                ),
                const SizedBox(height: 20),
                const Text('Tu información está protegida', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                const Text('Ingresa tu PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                
                // Caja de PIN
                SizedBox(
                  width: 200,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    style: const TextStyle(fontSize: 30, letterSpacing: 10),
                    decoration: InputDecoration(
                      hintText: "****",
                      filled: true,
                      fillColor: const Color(0xFFE0ECE0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // Botón OK
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Home()),
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C924F),
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}