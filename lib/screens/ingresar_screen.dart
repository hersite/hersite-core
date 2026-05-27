import 'package:flutter/material.dart';

class InicioLogin extends StatelessWidget {
  const InicioLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: SafeArea(
        child: Column(
          children: [
            // Botón de Idioma
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
            ),

            // Logo de la Tesis
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF316533), width: 1),
              ),
              child: ClipOval(
                child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            
            // Textos
            const Text(
              'Tu información esta protegida',
              style: TextStyle(color: Color(0xFF434C43), fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ingresa tu PIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // Los 4 circulitos/cuadritos del PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0ECE0),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              )),
            ),
            
            const Spacer(),

            // Teclado Numérico (Reconstruido)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_btnNum('1'), _btnNum('2'), _btnNum('3')]),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_btnNum('4'), _btnNum('5'), _btnNum('6')]),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_btnNum('7'), _btnNum('8'), _btnNum('9')]),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80), // Espacio vacío
                      _btnNum('0'),
                      // Botón OK
                      Container(
                        width: 80,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C924F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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

  // Pequeño widget reutilizable para dibujar los botones de números
  Widget _btnNum(String numero) {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xBC98C89A),
        border: Border.all(color: const Color(0xFF316533)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Text(numero, style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }
}