import 'package:flutter/material.dart';

class InicioRegistrarse extends StatelessWidget {
  const InicioRegistrarse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      // SingleChildScrollView evita que la pantalla se rompa cuando se abre el teclado
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Botón de Idioma
              Align(
                alignment: Alignment.topRight,
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
                        child: const Text('ES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text('QU', style: TextStyle(color: Color(0xFF6EA377), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Título y Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crea tu cuenta',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Tus datos están protegidos\ny son privados',
                        style: TextStyle(color: Color(0xFF434C43), fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF316533), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // Cajas de texto (Formulario real)
              _crearCajaTexto('Nombre Completo', 'Ej. Rosa María Huamán'),
              const SizedBox(height: 20),
              
              _crearCajaTexto('DNI', 'Ej. 12345678', esNumero: true),
              const SizedBox(height: 20),
              
              _crearCajaTexto('Celular', 'Ej. 999000111', esNumero: true),
              const SizedBox(height: 20),
              
              _crearCajaTexto('Crea tu PIN (4 dígitos)', '****', esNumero: true, ocultar: true),
              const SizedBox(height: 40),

              // Botón Final
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Acción para guardar en la base de datos
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C924F),
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Crear cuenta',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pequeño widget para generar las cajas de texto sin repetir código
  Widget _crearCajaTexto(String titulo, String ejemplo, {bool esNumero = false, bool ocultar = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          obscureText: ocultar, // Oculta el texto si es una contraseña/PIN
          keyboardType: esNumero ? TextInputType.number : TextInputType.text, // Muestra teclado numérico si se requiere
          decoration: InputDecoration(
            hintText: ejemplo,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF316533), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}