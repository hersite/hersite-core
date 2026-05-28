import 'package:flutter/material.dart';

class ResultadoScreen extends StatelessWidget {
  final List<String> sintomasDetectados;
  //agregué esto: 
  final String nivelRiesgo;
  final String mensajeModelo;
  final dynamic probabilidades;

  const ResultadoScreen({
    super.key,
    required this.sintomasDetectados,
    required this.nivelRiesgo,
    required this.mensajeModelo,
    this.probabilidades,
  });

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // 🔴🟡🟢 AQUÍ CAMBIAS LA PALABRA PARA PROBAR 
    // Escribe 'Alto', 'Medio' o 'Bajo'
    // ==========================================
    //String nivelRiesgo = 'Bajo'; // <-- CAMBIA AQUÍ PARA PROBAR LOS COLORES Y MENSAJES

    // --- VARIABLES DINÁMICAS SEGÚN EL RIESGO ---
    Color colorFondo = Colors.white;
    Color colorBorde = Colors.grey;
    Color colorTexto = Colors.black;
    String titulo = '';
    String descripcion = '';
    List<String> pasos = [];

    // LÓGICA DEL SEMÁFORO Y COLORES
    if (nivelRiesgo == 'Riesgo_Alto') {
      colorFondo = const Color(0xFFFCE4E4); // Rojo clarito
      colorBorde = const Color(0xFFD33232); // Rojo fuerte
      colorTexto = const Color(0xFFAE4B4B); // Rojo texto
      titulo = '¡Atención urgente!';
      descripcion = 'Tus síntomas indican un riesgo alto para ti y tu bebé.\nPor favor acude a la posta de salud hoy.';
      pasos = ['1. No estés sola', '2. Avisa a tu familia', '3. Acude a la posta hoy'];
    } else if (nivelRiesgo == 'Riesgo_Medio') {
      colorFondo = const Color(0xFFFFF7D8); // Amarillo clarito
      colorBorde = const Color(0xFFB69500); // Amarillo fuerte
      colorTexto = const Color(0xFF8A7100); // Amarillo texto
      titulo = 'Precaución: Mantente alerta';
      descripcion = 'Algunos de tus síntomas requieren atención.\nEs recomendable que un profesional te evalúe pronto.';
      pasos = ['1. Reposa sin esfuerzos', '2. Saca una cita médica', '3. Si empeoras, ve a la posta'];
    } else if (nivelRiesgo == 'Riesgo_Bajo') {
      colorFondo = const Color(0xFFEEFFEF); // Verde clarito
      colorBorde = const Color(0xFF4C924F); // Verde fuerte
      colorTexto = const Color(0xFF306339); // Verde texto
      titulo = '¡Todo parece estar bien!';
      descripcion = 'Tus síntomas son comunes durante el embarazo.\nSin embargo, si algo cambia, no dudes en consultar.';
      pasos = ['1. Sigue tu rutina', '2. Hidrátate y descansa', '3. Ve a tus controles'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'RESULTADOS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // 1. CUADRO PRINCIPAL (EL SEMÁFORO)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colorBorde, width: 2),
              ),
              child: Column(
                children: [
                  // LOS 3 CÍRCULOS (LUCES)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 40,
                          color: nivelRiesgo == 'Riesgo_Bajo'
                              ? const Color(0xFF4C924F)
                              : Colors.green.shade100,
                        ),
                        const SizedBox(width: 15),
                        Icon(
                          Icons.circle,
                          size: 40,
                          color: nivelRiesgo == 'Riesgo_Medio'
                              ? const Color(0xFFF9E37F)
                              : Colors.yellow.shade100,
                        ),
                        const SizedBox(width: 15),
                        Icon(
                          Icons.circle,
                          size: 40,
                          color: nivelRiesgo == 'Riesgo_Alto'
                              ? const Color(0xFFD33232)
                              : Colors.red.shade100,
                        ),
                        /*Icon(Icons.circle, size: 40, color: nivelRiesgo == 'Bajo' ? const Color(0xFF4C924F) : Colors.green.shade100),
                        const SizedBox(width: 15),
                        Icon(Icons.circle, size: 40, color: nivelRiesgo == 'Medio' ? const Color(0xFFF9E37F) : Colors.yellow.shade100),
                        const SizedBox(width: 15),
                        Icon(Icons.circle, size: 40, color: nivelRiesgo == 'Alto' ? const Color(0xFFD33232) : Colors.red.shade100),*/
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    titulo,
                    style: TextStyle(color: colorBorde, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    descripcion,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorTexto, fontSize: 15, fontFamily: 'Poltawski Nowy'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // 2. SÍNTOMAS DETECTADOS (PÍLDORAS)
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Síntomas detectados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy', color: Color(0xFF434C43)),
                  ),
                  const SizedBox(height: 10),
                  sintomasDetectados.isEmpty
                      ? const Text('Ninguno o "Me siento bien"', style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: sintomasDetectados.map((sintoma) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorFondo, // Se pinta del color del riesgo
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                sintoma,
                                style: TextStyle(color: colorTexto, fontSize: 13, fontFamily: 'Poly'),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // 3. INSTRUCCIONES Y BOTONES FIJOS
            // ==========================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CAJA DE INSTRUCCIONES
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('¿Qué hago ahora?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                        const SizedBox(height: 8),
                        Text(pasos[0], style: const TextStyle(fontSize: 14, fontFamily: 'Poltawski Nowy')),
                        const SizedBox(height: 4),
                        Text(pasos[1], style: const TextStyle(fontSize: 14, fontFamily: 'Poltawski Nowy')),
                        const SizedBox(height: 4),
                        Text(pasos[2], style: const TextStyle(fontSize: 14, fontFamily: 'Poltawski Nowy')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // BOTONES FIJOS
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C924F),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Ver Historial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCE4E4),
                            side: const BorderSide(color: Color(0xFFD33232)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_in_talk, color: Color(0xFFD33232), size: 18),
                              SizedBox(width: 4),
                              Text('Emergencia', style: TextStyle(color: Color(0xFFD33232), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}