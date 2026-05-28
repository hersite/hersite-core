import 'package:flutter/material.dart';
import 'signos_vitales_screen.dart';

class SintomasScreen extends StatefulWidget {
  const SintomasScreen({super.key});

  @override
  State<SintomasScreen> createState() => _SintomasScreenState();
}

class _SintomasScreenState extends State<SintomasScreen> {
  final List<String> _sintomasList = [
    'Taquicardia sostenida',
    'Cefalea intensa',
    'Alteración visual',
    'Zumbido oídos',
    'Dolor hipocondrio derecho',
    'Dolor boca estómago',
    'Hinchazón cara manos',
    'Sangrado vaginal',
    'Mareo desmayo',
    'Sudoración fría',
    'Fiebre escalofríos',
    'Hipotermia subjetiva',
    'Flujo vaginal fétido',
    'Dolor abdominal bajo',
    'Pérdida líquido amniótico',
    'Confusión somnolencia',
    'Movimientos fetales disminuidos',
    'Dificultad respirar',
  ];

  final Set<int> _sintomasSeleccionados = {};
  
  // NUEVA VARIABLE: Para saber si marcó "Me siento bien"
  bool _meSientoBien = false;

  void _toggleSintoma(int index) {
    setState(() {
      // Si selecciona un síntoma, quitamos el "Me siento bien"
      _meSientoBien = false;
      
      if (_sintomasSeleccionados.contains(index)) {
        _sintomasSeleccionados.remove(index);
      } else {
        _sintomasSeleccionados.add(index);
      }
    });
  }

  void _toggleMeSientoBien() {
    setState(() {
      _meSientoBien = !_meSientoBien;
      if (_meSientoBien) {
        // Si marca "Me siento bien", limpiamos los síntomas malos
        _sintomasSeleccionados.clear();
      }
    });
  }

  void _continuar() {
    // AHORA LA VALIDACIÓN ACEPTA SI HAY SÍNTOMAS O SI MARCÓ "ME SIENTO BIEN"
    if (_sintomasSeleccionados.isEmpty && !_meSientoBien) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos un síntoma o marca "Me siento bien"'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    // Navegación hacia Signos Vitales
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignosVitalesScreen(
          sintomasSeleccionados: _sintomasSeleccionados, // Si marcó "Me siento bien", esto irá vacío, ¡y es correcto!
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
                  Text('Modo offline', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: Text(
              '¿Cómo te sientes hoy?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEFFEF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Toca los síntomas que tienes',
              style: TextStyle(color: Color(0xFF306339), fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: _sintomasList.length,
                itemBuilder: (context, index) {
                  final isSelected = _sintomasSeleccionados.contains(index);
                  return GestureDetector(
                    onTap: () => _toggleSintoma(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEFFEF) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4C924F) : const Color(0xFFB9BAB9),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: Text(
                          _sintomasList[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF306339) : Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poltawski Nowy',
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleMeSientoBien,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      // CAMBIO VISUAL: Si está presionado, se pinta verde
                      backgroundColor: _meSientoBien ? const Color(0xFFEEFFEF) : Colors.transparent,
                      side: BorderSide(
                        color: _meSientoBien ? const Color(0xFF4C924F) : const Color(0xFFB9BAB9), 
                        width: 2
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _meSientoBien ? Icons.check_box : Icons.check_box_outline_blank, 
                          color: _meSientoBien ? const Color(0xFF2CE42C) : Colors.grey
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Me siento bien',
                          style: TextStyle(
                            color: _meSientoBien ? const Color(0xFF306339) : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poltawski Nowy',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _continuar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C924F),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}