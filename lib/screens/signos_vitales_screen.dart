import 'package:flutter/material.dart';
import 'resultado_screen.dart';

class SignosVitalesScreen extends StatefulWidget {
  final Set<int> sintomasSeleccionados;

  const SignosVitalesScreen({super.key, required this.sintomasSeleccionados});

  @override
  State<SignosVitalesScreen> createState() => _SignosVitalesScreenState();
}

class _SignosVitalesScreenState extends State<SignosVitalesScreen> {
  final TextEditingController _sistolicaCtrl = TextEditingController();
  final TextEditingController _diastolicaCtrl = TextEditingController();

  /* void _analizar() {
    // Aquí luego uniremos los síntomas con estos números para la IA
    print("Síntomas previos: ${widget.sintomasSeleccionados}");
    print("Sistólica: ${_sistolicaCtrl.text}");
    print("Diastólica: ${_diastolicaCtrl.text}");
    
    // Aquí pondremos la navegación a la pantalla de resultados finales
  } */

  void _analizar() {
    // ESTO ES SOLO PARA PROBAR EL DISEÑO DE LA PANTALLA DE RESULTADOS
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResultadoScreen(
          // Le pasamos unos síntomas falsos para ver cómo se pintan las píldoras
          sintomasDetectados: ['Visión Borrosa', 'Dolor de cabeza', 'PA Alto'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'Sincronizada',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6EA377),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'ES',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: const Text(
                      'QU',
                      style: TextStyle(color: Color(0xFF6EA377), fontSize: 12),
                    ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Signos Vitales',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Ingresa si tienes estos datos (opcional)',
                style: TextStyle(
                  color: Color(0xFF306339),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poltawski Nowy',
                ),
              ),
            ),
            const SizedBox(height: 30),

            // SECCIÓN: PRESIÓN SISTÓLICA (Arriba)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'PRESIÓN SISTÓLICA - OPCIONAL',
                      style: TextStyle(
                        color: Color(0xFF434C43),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _sistolicaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. 120',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECCIÓN: PRESIÓN DIASTÓLICA (Abajo, donde iba la temperatura)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'PRESIÓN DIASTÓLICA - OPCIONAL',
                      style: TextStyle(
                        color: Color(0xFF434C43),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _diastolicaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Ej. 80',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BANNER AMARILLO DE ADVERTENCIA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D8),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFF9E37F)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB69500), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Si no tienes los datos, puedes omitirlos. El modelo usará solo tus síntomas.',
                      style: TextStyle(
                        color: Color(0xFFB69500),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // BOTÓN ANALIZAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _analizar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C924F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Analizar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
