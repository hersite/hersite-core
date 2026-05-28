import 'package:flutter/material.dart';
import '../data/perfil_gestante_temp.dart';
import 'home_screen.dart';

class AntecedentesScreen extends StatefulWidget {
  const AntecedentesScreen({super.key});

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> {
  // 1. Controladores para las variables numéricas
  final TextEditingController _edadCtrl = TextEditingController();
  final TextEditingController _semanasGestacionCtrl = TextEditingController();
  final TextEditingController _embarazosCtrl = TextEditingController();
  final TextEditingController _sistolicaBasalCtrl = TextEditingController();
  final TextEditingController _diastolicaBasalCtrl = TextEditingController();

  // 2. Las 5 variables booleanas exactas de tu modelo
  final List<String> _preguntasBooleanas = [
    'Cesárea previa',
    'Diabetes',
    'Hipertensión previa',
    'Pre-eclampsia previa',
    'Anemia gestacional',
  ];

  // Mapa para guardar las respuestas de Sí/No
  final Map<int, bool> _respuestas = {};

  void _seleccionarRespuesta(int index, bool respuesta) {
    setState(() {
      _respuestas[index] = respuesta;
    });
  }

  void _guardarYContinuar() {
    // Validación de que los campos numéricos no estén vacíos
    if (_edadCtrl.text.isEmpty ||
        _semanasGestacionCtrl.text.isEmpty ||
        _embarazosCtrl.text.isEmpty ||
        _sistolicaBasalCtrl.text.isEmpty ||
        _diastolicaBasalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa edad, semanas de gestación, embarazos y presión basal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validación de que respondió todos los Sí/No
    if (_respuestas.length < _preguntasBooleanas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor responde Sí o No a todas las condiciones.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Aquí ya tienes todo listo para tu modelo ML:
    final edad = int.tryParse(_edadCtrl.text.trim());
    final semanasGestacion = int.tryParse(_semanasGestacionCtrl.text.trim());
    final numeroEmbarazos = int.tryParse(_embarazosCtrl.text.trim());
    final presionBasalSistolica = int.tryParse(_sistolicaBasalCtrl.text.trim());
    final presionBasalDiastolica = int.tryParse(_diastolicaBasalCtrl.text.trim());

    if (edad == null ||
        semanasGestacion == null ||
        numeroEmbarazos == null ||
        presionBasalSistolica == null ||
        presionBasalDiastolica == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifica que los valores numéricos sean correctos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (edad < 12 || edad > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una edad materna válida.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (semanasGestacion < 28 || semanasGestacion > 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este prototipo está enfocado en gestantes del tercer trimestre. Ingresa semanas entre 28 y 42.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    PerfilGestanteTemp.guardar({
      'Edad_Materna': edad,
      'Semanas_Gestacion': semanasGestacion,
      'Numero_Embarazos': numeroEmbarazos,
      'Cesarea_Previa': _respuestas[0] == true ? 1 : 0,
      'Diabetes': _respuestas[1] == true ? 1 : 0,
      'Hipertension_Previa': _respuestas[2] == true ? 1 : 0,
      'Preeclampsia_Previa': _respuestas[3] == true ? 1 : 0,
      'Anemia_Gestacional': _respuestas[4] == true ? 1 : 0,
      'Presion_Basal_Sistolica': presionBasalSistolica,
      'Presion_Basal_Diastolica': presionBasalDiastolica,
    });

    print('Perfil guardado temporalmente: ${PerfilGestanteTemp.obtener()}');
    // Regresamos al Perfil de forma segura
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Home(),
      ), // Esto limpia la pila y pone al Home como pantalla principal
    );
  }

  @override
  void dispose() {
    _edadCtrl.dispose();
    _semanasGestacionCtrl.dispose();
    _embarazosCtrl.dispose();
    _sistolicaBasalCtrl.dispose();
    _diastolicaBasalCtrl.dispose();
    super.dispose();
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
      body: Column(
        children: [
          // CONTENIDO SCROLLEABLE (Para que el teclado no tape nada)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO Y BANNER
                  const Text(
                    'Antecedentes médicos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEFFEF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Estos datos base ayudarán al modelo a darte una evaluación mucho más precisa.',
                      style: TextStyle(
                        color: Color(0xFF306339),
                        fontSize: 13,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ==========================================
                  // SECCIÓN 1: VARIABLES NUMÉRICAS
                  // ==========================================
                  const Text(
                    '1. Valores Base',
                    style: TextStyle(
                      color: Color(0xFF306339),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB9BAB9),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edad materna',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF434C43),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _edadCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Ej. 25',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB9BAB9),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Semanas de gestación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF434C43),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _semanasGestacionCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Ej. 34',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Campo: Número de Embarazos
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB9BAB9),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Número total de embarazos (incluyendo este)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF434C43),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _embarazosCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Ej. 2',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Campos: Presión Basal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB9BAB9),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Presión Arterial Basal (Normal antes del embarazo)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF434C43),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sistólica',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: _sistolicaBasalCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Ej. 110',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Diastólica',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: _diastolicaBasalCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Ej. 70',
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
                  const SizedBox(height: 30),

                  // ==========================================
                  // SECCIÓN 2: VARIABLES BOOLEANAS
                  // ==========================================
                  const Text(
                    '2. Condiciones Previas',
                    style: TextStyle(
                      color: Color(0xFF306339),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poltawski Nowy',
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Generamos la lista de tarjetas Sí/No
                  ...List.generate(_preguntasBooleanas.length, (index) {
                    return _buildPreguntaCard(index);
                  }),
                ],
              ),
            ),
          ),

          // BOTÓN GUARDAR Y CONTINUAR (Fijo abajo)
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(
              0xFFFBFFFB,
            ), // Fondo sólido para que no se superponga feo
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _guardarYContinuar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C924F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET REUTILIZABLE PARA LAS PREGUNTAS SÍ/NO
  Widget _buildPreguntaCard(int index) {
    final bool respondido = _respuestas.containsKey(index);
    final bool esSi = respondido && _respuestas[index] == true;
    final bool esNo = respondido && _respuestas[index] == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9BAB9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _preguntasBooleanas[index],
            style: const TextStyle(
              color: Color(0xFF434C43),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poltawski Nowy',
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _seleccionarRespuesta(index, true),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: esSi ? const Color(0xFF4C924F) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: esSi
                            ? const Color(0xFF4C924F)
                            : const Color(0xFFB9BAB9),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Sí',
                        style: TextStyle(
                          color: esSi ? Colors.white : const Color(0xFF434C43),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poltawski Nowy',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () => _seleccionarRespuesta(index, false),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: esNo
                          ? const Color(0xFF4C924F)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: esNo
                            ? const Color(0xFF4C924F)
                            : const Color(0xFFB9BAB9),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: esNo ? Colors.white : const Color(0xFF434C43),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Poltawski Nowy',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
