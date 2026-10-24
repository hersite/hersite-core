import 'package:flutter/material.dart';

import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import 'dart:async';
import '../services/connectivity_sync_service.dart';
import '../services/session_state_service.dart';
import '../widgets/resumen_registro_dialog.dart';
import 'home_screen.dart';

class AntecedentesScreen extends StatefulWidget {
  final bool esEdicion;

  const AntecedentesScreen({super.key, this.esEdicion = false});

  @override
  State<AntecedentesScreen> createState() => _AntecedentesScreenState();
}

class _AntecedentesScreenState extends State<AntecedentesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _embarazosKey = GlobalKey<FormFieldState<String>>();
  final _sistolicaKey = GlobalKey<FormFieldState<String>>();
  final _diastolicaKey = GlobalKey<FormFieldState<String>>();
  final _presionKey = GlobalKey();
  final _preguntaKeys = List.generate(7, (_) => GlobalKey());
  bool _validacionActiva = false;
  final TextEditingController _embarazosCtrl = TextEditingController();
  final TextEditingController _sistolicaBasalCtrl = TextEditingController();
  final TextEditingController _diastolicaBasalCtrl = TextEditingController();

  bool? _presionBasalDisponible;

  final List<String> _preguntasBooleanas = [
    'Cesárea previa',
    'Diabetes',
    'Hipertensión previa',
    'Pre-eclampsia previa',
    'Anemia gestacional',
    'Embarazo múltiple (gemelos, mellizos o más)',
    'Antecedente de hemorragia importante',
  ];

  final Map<int, bool> _respuestas = {};
  bool _isSaving = false;
  bool _mostrandoResumen = false;

  @override
  void initState() {
    super.initState();

    if (widget.esEdicion) {
      _cargarDatosExistentes();
    } else {
      final datos = PerfilGestanteTemp.obtener();
      if (datos != null) {
        _embarazosCtrl.text = '${datos['Numero_Embarazos'] ?? ''}';
        _sistolicaBasalCtrl.text = '${datos['Presion_Basal_Sistolica'] ?? ''}';
        _diastolicaBasalCtrl.text =
            '${datos['Presion_Basal_Diastolica'] ?? ''}';
        final disponible = datos['Presion_Basal_Disponible'];
        _presionBasalDisponible = disponible == null ? null : disponible == 1;
        for (var i = 0; i < _clavesCondiciones.length; i++) {
          final respuesta = datos[_clavesCondiciones[i]];
          if (respuesta != null) _respuestas[i] = respuesta == 1;
        }
      }
    }
  }

  static const _clavesCondiciones = [
    'Cesarea_Previa',
    'Diabetes',
    'Hipertension_Previa',
    'Preeclampsia_Previa',
    'Anemia_Gestacional',
    'Embarazo_Multiple',
    'Antecedente_Hemorragia',
  ];

  Future<void> _cargarDatosExistentes() async {
    final perfilDb = await LocalDatabase.instance.obtenerPerfil();

    if (perfilDb != null && mounted) {
      setState(() {
        _embarazosCtrl.text = perfilDb.numeroEmbarazos.toString();

        _presionBasalDisponible = perfilDb.presionBasalDisponible == 1;

        if (_presionBasalDisponible == true) {
          _sistolicaBasalCtrl.text = perfilDb.presionBasalSistolica.toString();
          _diastolicaBasalCtrl.text = perfilDb.presionBasalDiastolica
              .toString();
        } else {
          _sistolicaBasalCtrl.clear();
          _diastolicaBasalCtrl.clear();
        }

        _respuestas[0] = perfilDb.cesareaPrevia == 1;
        _respuestas[1] = perfilDb.diabetes == 1;
        _respuestas[2] = perfilDb.hipertensionPrevia == 1;
        _respuestas[3] = perfilDb.preeclampsiaPrevia == 1;
        _respuestas[4] = perfilDb.anemiaGestacional == 1;
        _respuestas[5] = perfilDb.embarazoMultiple == 1;
        _respuestas[6] = perfilDb.antecedenteHemorragia == 1;
      });
    }
  }

  void _seleccionarRespuesta(int index, bool respuesta) {
    setState(() {
      _respuestas[index] = respuesta;
    });
  }

  void _seleccionarPresionBasalDisponible(bool disponible) {
    setState(() {
      _presionBasalDisponible = disponible;

      if (!disponible) {
        _sistolicaBasalCtrl.clear();
        _diastolicaBasalCtrl.clear();
      }
    });
  }

  String? _validarEmbarazos(String? valor) {
    if ((valor ?? '').trim().isEmpty) {
      return 'Indica cuántos embarazos has tenido, incluido este.';
    }
    final numero = int.tryParse(valor!.trim());
    if (numero == null || numero < 1) {
      return 'Escribe un número entero mayor o igual a 1.';
    }
    return null;
  }

  String? _validarSistolica(String? valor) {
    if (_presionBasalDisponible != true) return null;
    if ((valor ?? '').trim().isEmpty) return 'Ingresa la presión sistólica.';
    final numero = int.tryParse(valor!.trim());
    if (numero == null || numero < 80 || numero > 180) {
      return 'Usa un número entero entre 80 y 180 mmHg.';
    }
    return null;
  }

  String? _validarDiastolica(String? valor) {
    if (_presionBasalDisponible != true) return null;
    if ((valor ?? '').trim().isEmpty) return 'Ingresa la presión diastólica.';
    final numero = int.tryParse(valor!.trim());
    if (numero == null || numero < 40 || numero > 120) {
      return 'Usa un número entero entre 40 y 120 mmHg.';
    }
    final sistolica = int.tryParse(_sistolicaBasalCtrl.text.trim());
    if (sistolica != null && numero >= sistolica) {
      return 'La diastólica debe ser menor que la sistólica.';
    }
    return null;
  }

  bool _validarFormulario() {
    setState(() => _validacionActiva = true);
    _formKey.currentState!.validate();
    final errores = <GlobalKey>[
      if (_embarazosKey.currentState?.hasError == true) _embarazosKey,
      if (_presionBasalDisponible == null) _presionKey,
      if (_sistolicaKey.currentState?.hasError == true) _sistolicaKey,
      if (_diastolicaKey.currentState?.hasError == true) _diastolicaKey,
      for (var i = 0; i < _preguntasBooleanas.length; i++)
        if (!_respuestas.containsKey(i)) _preguntaKeys[i],
    ];
    if (errores.isEmpty) return true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final campo = errores.first.currentContext;
      if (campo != null) {
        Scrollable.ensureVisible(
          campo,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
    });
    return false;
  }

  void _guardarBorrador() {
    PerfilGestanteTemp.actualizar({
      'Numero_Embarazos':
          int.tryParse(_embarazosCtrl.text.trim()) ??
          _embarazosCtrl.text.trim(),
      'Presion_Basal_Disponible': _presionBasalDisponible == null
          ? null
          : (_presionBasalDisponible! ? 1 : 0),
      'Presion_Basal_Sistolica':
          int.tryParse(_sistolicaBasalCtrl.text.trim()) ??
          _sistolicaBasalCtrl.text.trim(),
      'Presion_Basal_Diastolica':
          int.tryParse(_diastolicaBasalCtrl.text.trim()) ??
          _diastolicaBasalCtrl.text.trim(),
      for (var i = 0; i < _clavesCondiciones.length; i++)
        _clavesCondiciones[i]: _respuestas[i] == null
            ? null
            : (_respuestas[i]! ? 1 : 0),
    });
  }

  Future<void> _guardarYContinuar() async {
    if (_isSaving || _mostrandoResumen || !_validarFormulario()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      // Solo al editar se toma el perfil activo. Un alta usa su propio borrador.
      if (widget.esEdicion) {
        final perfilDb = await LocalDatabase.instance.obtenerPerfil();
        if (perfilDb == null) throw StateError('No se encontró el perfil.');
        PerfilGestanteTemp.guardar({
          ...perfilDb.toDraftMap(),
          'Semanas_Gestacion': perfilDb.semanasGestacion,
          'IdPerfil': perfilDb.id,
          'Nombre': perfilDb.nombre,
          'DNI': perfilDb.dni,
          'Celular': perfilDb.celular,
          'PinHash': perfilDb.pinHash,
          'PinSalt': perfilDb.pinSalt,
        });
      }
      _guardarBorrador();
      PerfilGestanteTemp.actualizar({
        'Numero_Embarazos': int.parse(_embarazosCtrl.text.trim()),
        'Presion_Basal_Sistolica': _presionBasalDisponible == true
            ? int.parse(_sistolicaBasalCtrl.text.trim())
            : -1,
        'Presion_Basal_Diastolica': _presionBasalDisponible == true
            ? int.parse(_diastolicaBasalCtrl.text.trim())
            : -1,
      });
      final datos = PerfilGestanteTemp.obtener();
      if (datos == null ||
          datos['Edad_Materna'] == null ||
          datos['Semanas_Gestacion'] == null) {
        _mostrarError(
          'No se encontraron los datos personales. Vuelve al primer paso.',
        );
        return;
      }
      if (!mounted) return;
      if (!widget.esEdicion) {
        setState(() {
          _isSaving = false;
          _mostrandoResumen = true;
        });
        final confirmado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ResumenRegistroDialog(datos: datos),
        );
        if (!mounted) return;
        setState(() => _mostrandoResumen = false);
        if (confirmado != true) {
          if (confirmado == false) Navigator.pop(context);
          return;
        }
        setState(() => _isSaving = true);
      }
      final perfil = PerfilGestante.fromTempMap(datos);
      final perfilId = await LocalDatabase.instance.guardarOActualizarPerfil(
        perfil,
      );
      await SessionStateService.instance.setActiveProfileId(perfilId);
      await SessionStateService.instance.markSessionActive();
      unawaited(ConnectivitySyncService.instance.start());
      await LocalDatabase.instance.obtenerPerfil();
      if (!mounted) return;
      if (widget.esEdicion) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
          (_) => false,
        );
      }
    } catch (_) {
      _mostrarError('No se pudieron guardar los datos. Inténtalo nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _mostrandoResumen = false;
        });
      }
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !widget.esEdicion) _guardarBorrador();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFFFB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFBFFFB),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
          title: Row(mainAxisAlignment: MainAxisAlignment.end),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: _validacionActiva
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.esEdicion
                              ? 'Editar antecedentes'
                              : 'Antecedentes médicos',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poltawski Nowy',
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (!widget.esEdicion) ...[
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF4C924F),
                                size: 18,
                              ),
                              SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Paso 2 de 2: ¡Ya casi terminas!',
                                  style: TextStyle(
                                    color: Color(0xFF4C924F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
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
                        if (_validacionActiva) ...[
                          const Text(
                            'Revisa los campos resaltados y responde las preguntas pendientes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF434C43),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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
                                'Número total de embarazos (incluyendo este)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF434C43),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                key: _embarazosKey,
                                validator: _validarEmbarazos,
                                enabled: !_isSaving,
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
                        _buildPresionBasalCard(),
                        const SizedBox(height: 30),
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
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving || _mostrandoResumen
                          ? null
                          : _guardarYContinuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C924F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              widget.esEdicion
                                  ? 'Guardar cambios'
                                  : 'Comenzar a usar la app',
                              style: const TextStyle(
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
          ),
        ),
      ),
    );
  }

  Widget _buildPresionBasalCard() {
    final bool respondido = _presionBasalDisponible != null;
    final bool esSi = respondido && _presionBasalDisponible == true;
    final bool esNo = respondido && _presionBasalDisponible == false;
    final error = _validacionActiva && !respondido;

    return Container(
      key: _presionKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: error
              ? Theme.of(context).colorScheme.error
              : const Color(0xFFB9BAB9),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Conoces tu presión arterial basal o habitual?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF434C43),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Es la presión que normalmente tienes o la que te indicaron en un control anterior.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontFamily: 'Poltawski Nowy',
            ),
          ),
          const SizedBox(height: 15),
          if (error) ...[
            Text(
              'Selecciona Sí o No para indicar si conoces tu presión habitual.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _buildBotonSiNo(
                  texto: 'Sí',
                  seleccionado: esSi,
                  onTap: () => _seleccionarPresionBasalDisponible(true),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildBotonSiNo(
                  texto: 'No',
                  seleccionado: esNo,
                  onTap: () => _seleccionarPresionBasalDisponible(false),
                  fondoNoSeleccionado: const Color(0xFFF5F5F5),
                ),
              ),
            ],
          ),
          if (_presionBasalDisponible == true) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sistólica',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: _sistolicaKey,
                        validator: _validarSistolica,
                        enabled: !_isSaving,
                        onChanged: (_) {
                          if (_validacionActiva) {
                            _diastolicaKey.currentState?.validate();
                          }
                        },
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
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        key: _diastolicaKey,
                        validator: _validarDiastolica,
                        enabled: !_isSaving,
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
        ],
      ),
    );
  }

  Widget _buildPreguntaCard(int index) {
    final bool respondido = _respuestas.containsKey(index);
    final bool esSi = respondido && _respuestas[index] == true;
    final bool esNo = respondido && _respuestas[index] == false;
    final error = _validacionActiva && !respondido;

    return Container(
      key: _preguntaKeys[index],
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: error
              ? Theme.of(context).colorScheme.error
              : const Color(0xFFB9BAB9),
          width: 2,
        ),
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
          if (error) ...[
            Text(
              'Responde Sí o No a esta condición.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _buildBotonSiNo(
                  texto: 'Sí',
                  seleccionado: esSi,
                  onTap: () => _seleccionarRespuesta(index, true),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildBotonSiNo(
                  texto: 'No',
                  seleccionado: esNo,
                  onTap: () => _seleccionarRespuesta(index, false),
                  fondoNoSeleccionado: const Color(0xFFF5F5F5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonSiNo({
    required String texto,
    required bool seleccionado,
    required VoidCallback onTap,
    Color fondoNoSeleccionado = Colors.white,
  }) {
    return GestureDetector(
      onTap: _isSaving ? null : onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: seleccionado ? const Color(0xFF4C924F) : fondoNoSeleccionado,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF4C924F)
                : const Color(0xFFB9BAB9),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              color: seleccionado ? Colors.white : const Color(0xFF434C43),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poltawski Nowy',
            ),
          ),
        ),
      ),
    );
  }
}
