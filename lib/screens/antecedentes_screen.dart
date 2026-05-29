import 'package:flutter/material.dart';
import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../services/session_state_service.dart';
import 'home_screen.dart'; 

class AntecedentesScreen extends StatefulWidget {
  // NUEVO: Bandera para saber si estamos editando o creando por primera vez
  final bool esEdicion;
  
  const AntecedentesScreen({super.key, this.esEdicion = false});

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> {
  // 1. Controladores para las 3 variables numéricas
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

  final Map<int, bool> _respuestas = {};

  @override
  void initState() {
    super.initState();
    // NUEVO: Si estamos en modo edición, cargamos los datos previos
    if (widget.esEdicion) {
      _cargarDatosExistentes();
    }
  }

  // Función que va a la base de datos y llena los campos visuales
  Future<void> _cargarDatosExistentes() async {
    final perfilDb = await LocalDatabase.instance.obtenerPerfil();
    if (perfilDb != null && mounted) {
      setState(() {
        _embarazosCtrl.text = perfilDb.numeroEmbarazos.toString();
        _sistolicaBasalCtrl.text = perfilDb.presionBasalSistolica.toString();
        _diastolicaBasalCtrl.text = perfilDb.presionBasalDiastolica.toString();
        
        // Convertimos los 1 y 0 a true/false para pintar los botones
        _respuestas[0] = perfilDb.cesareaPrevia == 1;
        _respuestas[1] = perfilDb.diabetes == 1;
        _respuestas[2] = perfilDb.hipertensionPrevia == 1;
        _respuestas[3] = perfilDb.preeclampsiaPrevia == 1;
        _respuestas[4] = perfilDb.anemiaGestacional == 1;
      });
    }
  }

  void _seleccionarRespuesta(int index, bool respuesta) {
    setState(() {
      _respuestas[index] = respuesta;
    });
  }

  // AHORA ES ASYNC PARA GUARDAR EN LA BASE DE DATOS
  Future<void> _guardarYContinuar() async {
    // Validación de campos numéricos
    if (_embarazosCtrl.text.isEmpty ||
        _sistolicaBasalCtrl.text.isEmpty ||
        _diastolicaBasalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa el número de embarazos y la presión basal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validación de booleanos
    if (_respuestas.length < _preguntasBooleanas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor responde Sí o No a todas las condiciones.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Conversión segura
    final numeroEmbarazos = int.tryParse(_embarazosCtrl.text.trim());
    final presionBasalSistolica = int.tryParse(_sistolicaBasalCtrl.text.trim());
    final presionBasalDiastolica = int.tryParse(_diastolicaBasalCtrl.text.trim());

    if (numeroEmbarazos == null || presionBasalSistolica == null || presionBasalDiastolica == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifica que los valores numéricos sean correctos.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // 1. ACTUALIZAMOS LA MEMORIA TEMPORAL
    PerfilGestanteTemp.actualizar({
      'Numero_Embarazos': numeroEmbarazos,
      'Cesarea_Previa': _respuestas[0] == true ? 1 : 0,
      'Diabetes': _respuestas[1] == true ? 1 : 0,
      'Hipertension_Previa': _respuestas[2] == true ? 1 : 0,
      'Preeclampsia_Previa': _respuestas[3] == true ? 1 : 0,
      'Anemia_Gestacional': _respuestas[4] == true ? 1 : 0,
      'Presion_Basal_Sistolica': presionBasalSistolica,
      'Presion_Basal_Diastolica': presionBasalDiastolica,
    });

    // 2. OBTENEMOS EL MAPA COMPLETO Y LO CONVERTIMOS A MODELO
    Map<String, dynamic>? perfilMap = PerfilGestanteTemp.obtener();

    if (perfilMap == null || perfilMap['Edad_Materna'] == null || perfilMap['Semanas_Gestacion'] == null) {
      final perfilDb = await LocalDatabase.instance.obtenerPerfil();

      if (perfilDb != null) {
        PerfilGestanteTemp.actualizar({
          'IdPerfil': perfilDb.id,
          'Nombre': perfilDb.nombre,
          'DNI': perfilDb.dni,
          'Celular': perfilDb.celular,
          'PinHash': perfilDb.pinHash,
          'PinSalt': perfilDb.pinSalt,
          ...perfilDb.toModelInput(),
        });

        perfilMap = PerfilGestanteTemp.obtener();
      }
    }

    if (perfilMap == null || perfilMap['Edad_Materna'] == null || perfilMap['Semanas_Gestacion'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el perfil temporal de la gestante.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if ((perfilMap['PinHash'] as String? ?? '').isEmpty ||
        (perfilMap['PinSalt'] as String? ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el PIN de registro. Vuelve a iniciar el registro.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final perfil = PerfilGestante.fromTempMap(perfilMap);

    // 3. GUARDAMOS EN SQLITE
    try {
      final perfilId = await LocalDatabase.instance.guardarOActualizarPerfil(perfil);
      await SessionStateService.instance.setActiveProfileId(perfilId);
      await SessionStateService.instance.markSessionActive();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar en BD: $e'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    // 4. NAVEGACIÓN DINÁMICA
    if (!mounted) return;
    
    if (widget.esEdicion) {
      // Si estaba editando, solo cierra la pantalla y vuelve al Perfil
      Navigator.pop(context);
    } else {
      // Si era registro nuevo, la manda al Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()), 
      );
    }
  }

  @override
  void dispose() {
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
              decoration: BoxDecoration(color: const Color(0xFF6EA377), borderRadius: BorderRadius.circular(15)),
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
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF6EA377))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(color: Color(0xFF6EA377), borderRadius: BorderRadius.horizontal(left: Radius.circular(14))),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO DINÁMICO
                  Text(
                    widget.esEdicion ? 'Editar antecedentes' : 'Antecedentes médicos', 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')
                  ),
                  const SizedBox(height: 5),
                  
                  // MENSAJITO DE PROGRESO (SOLO SE MUESTRA SI ES REGISTRO NUEVO)
                  if (!widget.esEdicion) ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF4C924F), size: 18),
                        SizedBox(width: 5),
                        Text('Paso 2 de 2: ¡Ya casi terminas!', style: TextStyle(color: Color(0xFF4C924F), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFEEFFEF), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Estos datos base ayudarán al modelo a darte una evaluación mucho más precisa.', style: TextStyle(color: Color(0xFF306339), fontSize: 13, fontFamily: 'Poltawski Nowy')),
                  ),
                  const SizedBox(height: 25),

                  const Text('1. Valores Base', style: TextStyle(color: Color(0xFF306339), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                  const SizedBox(height: 15),

                  // EMBARAZOS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFB9BAB9), width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Número total de embarazos (incluyendo este)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF434C43))),
                        const SizedBox(height: 10),
                        TextField(controller: _embarazosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. 2')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // PRESIÓN BASAL
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFB9BAB9), width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Presión Arterial Basal (Antes del embarazo)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF434C43))),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sistólica', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  TextField(controller: _sistolicaBasalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. 110')),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Diastólica', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  TextField(controller: _diastolicaBasalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. 70')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text('2. Condiciones Previas', style: TextStyle(color: Color(0xFF306339), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                  const SizedBox(height: 15),

                  ...List.generate(_preguntasBooleanas.length, (index) {
                    return _buildPreguntaCard(index);
                  }),
                ],
              ),
            ),
          ),
          
          // BOTÓN GUARDAR Y CONTINUAR DINÁMICO
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFBFFFB),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _guardarYContinuar,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(
                  widget.esEdicion ? 'Guardar cambios' : 'Comenzar a usar la app', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntaCard(int index) {
    final bool respondido = _respuestas.containsKey(index);
    final bool esSi = respondido && _respuestas[index] == true;
    final bool esNo = respondido && _respuestas[index] == false;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFB9BAB9), width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_preguntasBooleanas[index], style: const TextStyle(color: Color(0xFF434C43), fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _seleccionarRespuesta(index, true),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(color: esSi ? const Color(0xFF4C924F) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: esSi ? const Color(0xFF4C924F) : const Color(0xFFB9BAB9), width: 2)),
                    child: Center(child: Text('Sí', style: TextStyle(color: esSi ? Colors.white : const Color(0xFF434C43), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poltawski Nowy'))),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () => _seleccionarRespuesta(index, false),
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(color: esNo ? const Color(0xFF4C924F) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: esNo ? const Color(0xFF4C924F) : const Color(0xFFB9BAB9), width: 2)),
                    child: Center(child: Text('No', style: TextStyle(color: esNo ? Colors.white : const Color(0xFF434C43), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poltawski Nowy'))),
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