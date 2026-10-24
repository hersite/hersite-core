import 'package:flutter/material.dart';
import 'dart:async';

import '../data/perfil_gestante_temp.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../services/connectivity_sync_service.dart';
import '../services/pin_security_service.dart';
import 'antecedentes_screen.dart';

class InicioRegistrarse extends StatefulWidget {
  final bool esEdicion;

  const InicioRegistrarse({super.key, this.esEdicion = false});

  @override
  State<InicioRegistrarse> createState() => _InicioRegistrarseState();
}

class _InicioRegistrarseState extends State<InicioRegistrarse> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _fechaNacimientoCtrl = TextEditingController();
  final _semanasCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  DateTime? _fechaSeleccionada;
  bool _isSaving = false;
  bool _validacionActiva = false;
  String? _dniError;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) {
      _cargarDatosExistentes();
    } else {
      // Un registro nuevo nunca debe reutilizar el perfil activo anterior.
      PerfilGestanteTemp.limpiar();
    }
  }

  String _fechaTexto(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  int _edad(DateTime fecha) {
    final hoy = DateTime.now();
    var edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }

  Future<void> _cargarDatosExistentes() async {
    final perfil = await LocalDatabase.instance.obtenerPerfil();
    if (perfil == null || !mounted) return;
    setState(() {
      _nombreCtrl.text = perfil.nombre;
      _dniCtrl.text = perfil.dni;
      _celularCtrl.text = perfil.celular;
      _semanasCtrl.text = perfil.semanasActuales.toString();
      _fechaSeleccionada = perfil.fechaNacimiento;
      _fechaNacimientoCtrl.text = _fechaSeleccionada == null
          ? ''
          : _fechaTexto(_fechaSeleccionada!);
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _celularCtrl.dispose();
    _fechaNacimientoCtrl.dispose();
    _semanasCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime(2005, 2, 21),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (seleccion == null || !mounted) return;
    setState(() {
      _fechaSeleccionada = seleccion;
      _fechaNacimientoCtrl.text = _fechaTexto(seleccion);
    });
    if (_validacionActiva) _formKey.currentState?.validate();
  }

  String? _validarNombre(String? valor) {
    final nombre = (valor ?? '').trim();
    if (nombre.isEmpty) return 'Escribe tu nombre completo.';
    if (nombre.length < 2 ||
        !RegExp(r'[a-zA-ZÀ-ÖØ-öø-ÿĀ-ž]').hasMatch(nombre) ||
        !RegExp(r"^[a-zA-ZÀ-ÖØ-öø-ÿĀ-ž\s.'’\-]+$").hasMatch(nombre)) {
      return 'Usa letras para escribir tu nombre, sin números ni símbolos.';
    }
    return null;
  }

  String? _validarDni(String? valor) {
    if ((valor ?? '').trim().isEmpty) return 'Ingresa tu DNI.';
    if (!RegExp(r'^\d{8}$').hasMatch(valor!.trim())) {
      return 'El DNI debe tener exactamente 8 números.';
    }
    return _dniError;
  }

  String? _validarCelular(String? valor) {
    if ((valor ?? '').trim().isEmpty) return 'Ingresa tu celular.';
    if (!RegExp(r'^\d{9}$').hasMatch(valor!.trim())) {
      return 'El celular debe tener exactamente 9 números.';
    }
    return null;
  }

  String? _validarFecha(String? _) {
    if (_fechaSeleccionada == null) return 'Selecciona tu fecha de nacimiento.';
    final edad = _edad(_fechaSeleccionada!);
    if (edad < 12 || edad > 55) {
      return 'La edad permitida en este registro es de 12 a 55 años. Revisa la fecha.';
    }
    return null;
  }

  String? _validarSemanas(String? valor) {
    if ((valor ?? '').trim().isEmpty) {
      return 'Ingresa tus semanas de gestación.';
    }
    final semanas = int.tryParse(valor!.trim());
    if (semanas == null || semanas < 1 || semanas > 42) {
      return 'Escribe un número entero entre 1 y 42 semanas.';
    }
    return null;
  }

  String? _validarPin(String? valor) {
    if ((valor ?? '').isEmpty) return 'Crea un PIN para proteger tu cuenta.';
    if (!RegExp(r'^\d{6}$').hasMatch(valor!)) {
      return 'El PIN debe tener exactamente 6 números.';
    }
    return null;
  }

  bool _validarFormulario() {
    setState(() => _validacionActiva = true);
    final errores = _formKey.currentState!.validateGranularly();
    if (errores.isEmpty) return true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        errores.first.context,
        duration: const Duration(milliseconds: 300),
        alignment: 0.15,
      );
    });
    return false;
  }

  Future<void> _continuar() async {
    if (_isSaving || !_validarFormulario()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final dni = _dniCtrl.text.trim();
      if (!widget.esEdicion &&
          await LocalDatabase.instance.obtenerPerfilPorDni(dni) != null) {
        if (!mounted) return;
        setState(() {
          _dniError = 'Este DNI ya tiene una cuenta. Ingresa con tu PIN.';
        });
        _validarFormulario();
        return;
      }
      if (!mounted) return;
      final datos = <String, dynamic>{
        'Nombre': _nombreCtrl.text.trim(),
        'DNI': dni,
        'Celular': _celularCtrl.text.trim(),
        'Fecha_Nacimiento': _fechaSeleccionada!.toIso8601String(),
        'Fecha_Referencia_Gestacion': PerfilGestante.hoyLima.toIso8601String(),
        'Edad_Materna': _edad(_fechaSeleccionada!),
        'Semanas_Gestacion': int.parse(_semanasCtrl.text.trim()),
      };

      if (widget.esEdicion) {
        final perfilDb = await LocalDatabase.instance.obtenerPerfil();
        if (perfilDb == null) throw StateError('No se encontró el perfil.');
        if (int.parse(_semanasCtrl.text.trim()) == perfilDb.semanasActuales &&
            perfilDb.fechaReferenciaGestacion != null) {
          datos['Semanas_Gestacion'] = perfilDb.semanasGestacion;
          datos['Fecha_Referencia_Gestacion'] = perfilDb
              .fechaReferenciaGestacion!
              .toIso8601String();
        }
        PerfilGestanteTemp.actualizar({
          ...perfilDb.toDraftMap(),
          'IdPerfil': perfilDb.id,
          'PinHash': perfilDb.pinHash,
          'PinSalt': perfilDb.pinSalt,
          ...datos,
        });
        final perfil = PerfilGestante.fromTempMap(
          PerfilGestanteTemp.obtener()!,
        );
        await LocalDatabase.instance.guardarOActualizarPerfil(perfil);
        unawaited(
          ConnectivitySyncService.instance.trySyncNow(
            reason: 'perfil actualizado',
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Datos actualizados')));
        Navigator.pop(context, true);
      } else {
        final salt = PinSecurityService.instance.generateSalt();
        final hash = await PinSecurityService.instance.hashPin(
          pin: _pinCtrl.text,
          salt: salt,
        );
        if (!mounted) return;
        PerfilGestanteTemp.actualizar({
          ...datos,
          'PinSalt': salt,
          'PinHash': hash,
        });
        if (!mounted) return;
        setState(() => _isSaving = false);
        // Se conserva esta pantalla para poder revisar los datos personales.
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const AntecedentesScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron guardar los datos. Inténtalo nuevamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            autovalidateMode: _validacionActiva
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.esEdicion
                                ? 'Editar datos'
                                : 'Crea tu cuenta',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Tus datos están protegidos\ny son privados',
                            style: TextStyle(
                              color: Color(0xFF434C43),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          'img/logo_tesis.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_validacionActiva) ...[
                  const Text(
                    'Revisa los campos resaltados. Debajo de cada uno encontrarás qué corregir.',
                    style: TextStyle(color: Color(0xFF434C43), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],
                _campo(
                  'Nombre completo',
                  'Ej. Rosa María Huamán',
                  _nombreCtrl,
                  _validarNombre,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _campo(
                        'DNI',
                        'Ej. 12345678',
                        _dniCtrl,
                        _validarDni,
                        numero: true,
                        onChanged: (_) {
                          if (_dniError != null) {
                            setState(() => _dniError = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _campo(
                        'Fecha de nacimiento',
                        'DD/MM/AAAA',
                        _fechaNacimientoCtrl,
                        _validarFecha,
                        onTap: _seleccionarFecha,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _campo(
                        'Celular',
                        'Ej. 999000111',
                        _celularCtrl,
                        _validarCelular,
                        numero: true,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _campo(
                        'Semanas de gestación',
                        'Ej. 34',
                        _semanasCtrl,
                        _validarSemanas,
                        numero: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!widget.esEdicion)
                  _campo(
                    'Crea tu PIN (6 dígitos)',
                    '••••••',
                    _pinCtrl,
                    _validarPin,
                    numero: true,
                    ocultar: true,
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _continuar,
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.esEdicion ? 'Guardar cambios' : 'Continuar',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(
    String titulo,
    String ejemplo,
    TextEditingController controlador,
    String? Function(String?) validar, {
    bool numero = false,
    bool ocultar = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controlador,
          validator: validar,
          obscureText: ocultar,
          readOnly:
              onTap != null || (widget.esEdicion && controlador == _dniCtrl),
          onTap: onTap,
          onChanged: onChanged,
          enabled: !_isSaving,
          keyboardType: numero ? TextInputType.number : TextInputType.name,
          textCapitalization: numero || onTap != null
              ? TextCapitalization.none
              : TextCapitalization.words,
          decoration: InputDecoration(
            hintText: ejemplo,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: onTap == null
                ? null
                : const Icon(
                    Icons.calendar_today,
                    size: 19,
                    color: Color(0xFF306339),
                  ),
          ),
        ),
      ],
    );
  }
}
