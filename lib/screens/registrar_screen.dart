import 'package:flutter/material.dart';
import 'screens/test_model_screen.dart';

class InicioRegistrarse extends StatelessWidget {
  const InicioRegistrarse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      // AppBar agrega automáticamente la flecha para regresar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crea tu cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('Tus datos están protegidos\ny son privados', style: TextStyle(color: Color(0xFF434C43), fontSize: 12)),
                    ],
                  ),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF316533), width: 1)),
                    child: ClipOval(child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover)),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // Formulario
              _crearCajaTexto('Nombre Completo', 'Ej. Rosa María Huamán'),
              const SizedBox(height: 20),
              _crearCajaTexto('DNI', 'Ej. 12345678', esNumero: true),
              const SizedBox(height: 20),
              _crearCajaTexto('Celular', 'Ej. 999000111', esNumero: true),
              const SizedBox(height: 20),
              _crearCajaTexto('Crea tu PIN (4 dígitos)', '****', esNumero: true, ocultar: true),
              const SizedBox(height: 40),

              // Botón Final (Regresa al inicio)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Esto saca al usuario de esta pantalla y lo lleva al Inicio
                    Navigator.of(context).pop(); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C924F),
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                
                ElevatedButton()
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TestModelScreen(),
                      ),
                    );
                  },
                  child: const Text('Probar modelo ML'),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearCajaTexto(String titulo, String ejemplo, {bool esNumero = false, bool ocultar = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          obscureText: ocultar,
          keyboardType: esNumero ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: ejemplo,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF316533), width: 2)),
          ),
        ),
      ],
    );
  }
}