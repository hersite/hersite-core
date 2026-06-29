import 'package:flutter/material.dart';
import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../services/session_state_service.dart';
import 'home_screen.dart'; 
import '../services/api_client.dart';

class AntecedentesScreen extends StatefulWidget {
  final bool esEdicion;
  
  const AntecedentesScreen({super.key, this.esEdicion = false});

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> {
  final TextEditingController _embarazosCtrl = TextEditingController();
  final TextEditingController _sistolicaBasalCtrl = TextEditingController();
  final TextEditingController _diastolicaBasalCtrl = TextEditingController();

  final List<String> _preguntasBooleanas = [
    'Cesárea previa',
    'Diabetes',
    'Hipertensión previa',
    'Pre-eclampsia previa',
    'Anemia gestacional',
  ];

  final Map<int, bool> _respuestas = {};
  bool _isSaving = false; // 🟢 Control de carga

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) {
      _cargarDatosExistentes();
    }
  }

  Future<void> _cargarDatosExistentes() async {
    final perfilDb = await LocalDatabase.instance.obtenerPerfil();
    if (perfilDb != null && mounted) {
      setState(() {
        _embarazosCtrl.text = perfilDb.numeroEmbarazos.toString();
        _sistolicaBasalCtrl.text = perfilDb.presionBasalSistolica.toString();
        _diastolicaBasalCtrl.text = perfilDb.presionBasalDiastolica.toString();
        
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

  Future<void> _guardarYContinuar() async {
    if (_isSaving) return; 
    setState(() => _isSaving = true);

    if (_embarazosCtrl.text.isEmpty || _sistolicaBasalCtrl.text.isEmpty || _diastolicaBasalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completa el número de embarazos y la presión basal.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    if (_respuestas.length < _preguntasBooleanas.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor responde Sí o No a todas las condiciones.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    final numeroEmbarazos = int.tryParse(_embarazosCtrl.text.trim());
    final presionBasalSistolica = int.tryParse(_sistolicaBasalCtrl.text.trim());
    final presionBasalDiastolica = int.tryParse(_diastolicaBasalCtrl.text.trim());

    if (numeroEmbarazos == null || presionBasalSistolica == null || presionBasalDiastolica == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifica que los valores numéricos sean correctos.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    // 🟢 1. PRIMERO CARGAMOS LO VIEJO A LA MEMORIA TEMPORAL
    final perfilDb = await LocalDatabase.instance.obtenerPerfil();
    if (perfilDb != null) {
      PerfilGestanteTemp.actualizar({
        ...perfilDb.toModelInput(),
        'IdPerfil': perfilDb.id, 'Nombre': perfilDb.nombre, 'DNI': perfilDb.dni, 'Celular': perfilDb.celular, 'PinHash': perfilDb.pinHash, 'PinSalt': perfilDb.pinSalt,
      });
    }

    // 🟢 2. DESPUÉS CARGAMOS LO NUEVO PARA QUE SOBREESCRIBA LO ANTERIOR
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

    Map<String, dynamic>? perfilMap = PerfilGestanteTemp.obtener();

    if (perfilMap == null || perfilMap['Edad_Materna'] == null || perfilMap['Semanas_Gestacion'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró el perfil de la gestante.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    final perfil = PerfilGestante.fromTempMap(perfilMap);

  try {
      // 1. Guardado local en SQLite (Celular)
      final perfilId = await LocalDatabase.instance.guardarOActualizarPerfil(perfil);
      await SessionStateService.instance.setActiveProfileId(perfilId);
      await SessionStateService.instance.markSessionActive();

      // 🟢 2. INTENTO DE SINCRONIZACIÓN CON EL SERVIDOR (FastAPI -> pgAdmin)
      try {
        await ApiClient.instance.enviarPerfil(perfil);
        debugPrint('Antecedentes sincronizados con el servidor.');
      } catch (e) {
        debugPrint('Antecedentes guardados localmente. Se sincronizarán luego: $e');
      }

      // 3. Fetch local y Refresh UI
      await LocalDatabase.instance.obtenerPerfil();

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos guardados y actualizados', style: TextStyle(color: Colors.white)), 
          backgroundColor: Color(0xFF4C924F)
        )
      );

      // 4. Navegación
      if (widget.esEdicion) {
        Navigator.pop(context, true); 
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent)
        );
      }
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6EA377), borderRadius: BorderRadius.circular(15)),
              child: const Row(children: [Icon(Icons.circle, color: Color(0xFF2CE42C), size: 12), SizedBox(width: 8), Text('Modo offline', style: TextStyle(color: Colors.white, fontSize: 13))]),
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
                  Text(widget.esEdicion ? 'Editar antecedentes' : 'Antecedentes médicos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                  const SizedBox(height: 5),
                  
                  if (!widget.esEdicion) ...[
                    const Row(children: [Icon(Icons.check_circle, color: Color(0xFF4C924F), size: 18), SizedBox(width: 5), Text('Paso 2 de 2: ¡Ya casi terminas!', style: TextStyle(color: Color(0xFF4C924F), fontWeight: FontWeight.bold, fontSize: 14))]),
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
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Sistólica', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 5), TextField(controller: _sistolicaBasalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. 110'))])),
                            const SizedBox(width: 15),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Diastólica', style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 5), TextField(controller: _diastolicaBasalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ej. 70'))])),
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
          
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFBFFFB),
            child: SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                onPressed: _guardarYContinuar,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isSaving 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(widget.esEdicion ? 'Guardar cambios' : 'Comenzar a usar la app', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
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
              Expanded(child: GestureDetector(onTap: () => _seleccionarRespuesta(index, true), child: Container(height: 45, decoration: BoxDecoration(color: esSi ? const Color(0xFF4C924F) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: esSi ? const Color(0xFF4C924F) : const Color(0xFFB9BAB9), width: 2)), child: Center(child: Text('Sí', style: TextStyle(color: esSi ? Colors.white : const Color(0xFF434C43), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poltawski Nowy')))))),
              const SizedBox(width: 15),
              Expanded(child: GestureDetector(onTap: () => _seleccionarRespuesta(index, false), child: Container(height: 45, decoration: BoxDecoration(color: esNo ? const Color(0xFF4C924F) : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10), border: Border.all(color: esNo ? const Color(0xFF4C924F) : const Color(0xFFB9BAB9), width: 2)), child: Center(child: Text('No', style: TextStyle(color: esNo ? Colors.white : const Color(0xFF434C43), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Poltawski Nowy')))))),
            ],
          ),
        ],
      ),
    );
  }
}