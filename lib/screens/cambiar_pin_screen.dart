import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../services/pin_security_service.dart';

class CambiarPinScreen extends StatefulWidget {
  final PerfilGestante perfil;

  const CambiarPinScreen({
    super.key,
    required this.perfil,
  });

  @override
  State<CambiarPinScreen> createState() => _CambiarPinScreenState();
}

class _CambiarPinScreenState extends State<CambiarPinScreen> {
  final TextEditingController _pinActualCtrl = TextEditingController();
  final TextEditingController _nuevoPinCtrl = TextEditingController();
  final TextEditingController _confirmarPinCtrl = TextEditingController();

  bool _guardando = false;
  bool _verPinActual = false;
  bool _verNuevoPin = false;
  bool _verConfirmarPin = false;

  String? _mensajeError;

  @override
  void dispose() {
    _pinActualCtrl.dispose();
    _nuevoPinCtrl.dispose();
    _confirmarPinCtrl.dispose();
    super.dispose();
  }

  bool _pinTieneFormatoValido(String pin) {
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  void _mostrarError(String mensaje) {
    setState(() {
      _mensajeError = mensaje;
    });
  }

  Future<void> _guardarNuevoPin() async {
    if (_guardando) return;

    final pinActual = _pinActualCtrl.text.trim();
    final nuevoPin = _nuevoPinCtrl.text.trim();
    final confirmarPin = _confirmarPinCtrl.text.trim();

    if (!_pinTieneFormatoValido(pinActual)) {
      _mostrarError('El PIN actual debe tener 6 dígitos.');
      return;
    }

    if (!_pinTieneFormatoValido(nuevoPin)) {
      _mostrarError('El nuevo PIN debe tener 6 dígitos.');
      return;
    }

    if (nuevoPin != confirmarPin) {
      _mostrarError('El nuevo PIN y la confirmación no coinciden.');
      return;
    }

    if (pinActual == nuevoPin) {
      _mostrarError('El nuevo PIN debe ser diferente al PIN actual.');
      return;
    }

    final hashActualIngresado = PinSecurityService.instance.hashPin(
      pin: pinActual,
      salt: widget.perfil.pinSalt,
    );

    if (hashActualIngresado != widget.perfil.pinHash) {
      _mostrarError('El PIN actual no es correcto.');
      return;
    }

    setState(() {
      _guardando = true;
      _mensajeError = null;
    });

    try {
      final nuevoSalt = PinSecurityService.instance.generateSalt();

      final nuevoHash = PinSecurityService.instance.hashPin(
        pin: nuevoPin,
        salt: nuevoSalt,
      );

      final perfilActualizado = PerfilGestante(
        id: widget.perfil.id,
        nombre: widget.perfil.nombre,
        dni: widget.perfil.dni,
        celular: widget.perfil.celular,
        pinHash: nuevoHash,
        pinSalt: nuevoSalt,
        edadMaterna: widget.perfil.edadMaterna,
        semanasGestacion: widget.perfil.semanasGestacion,
        numeroEmbarazos: widget.perfil.numeroEmbarazos,
        cesareaPrevia: widget.perfil.cesareaPrevia,
        diabetes: widget.perfil.diabetes,
        hipertensionPrevia: widget.perfil.hipertensionPrevia,
        preeclampsiaPrevia: widget.perfil.preeclampsiaPrevia,
        anemiaGestacional: widget.perfil.anemiaGestacional,
        presionBasalDisponible: widget.perfil.presionBasalDisponible,
        embarazoMultiple: widget.perfil.embarazoMultiple,
        antecedenteHemorragia: widget.perfil.antecedenteHemorragia,
        presionBasalSistolica: widget.perfil.presionBasalSistolica,
        presionBasalDiastolica: widget.perfil.presionBasalDiastolica,
      );

      await LocalDatabase.instance.guardarOActualizarPerfil(perfilActualizado);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
        _mensajeError = 'Error al cambiar el PIN: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Cambiar PIN',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poltawski Nowy',
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEFFEF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4C924F)),
                ),
                child: const Text(
                  'Para cambiar tu PIN, primero ingresa el PIN actual y luego registra uno nuevo de 6 dígitos.',
                  style: TextStyle(
                    color: Color(0xFF306339),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_mensajeError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4E4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD33232)),
                  ),
                  child: Text(
                    _mensajeError!,
                    style: const TextStyle(
                      color: Color(0xFF970A0A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildPinField(
                label: 'PIN actual',
                controller: _pinActualCtrl,
                visible: _verPinActual,
                onToggle: () {
                  setState(() {
                    _verPinActual = !_verPinActual;
                  });
                },
              ),
              const SizedBox(height: 18),

              _buildPinField(
                label: 'Nuevo PIN',
                controller: _nuevoPinCtrl,
                visible: _verNuevoPin,
                onToggle: () {
                  setState(() {
                    _verNuevoPin = !_verNuevoPin;
                  });
                },
              ),
              const SizedBox(height: 18),

              _buildPinField(
                label: 'Confirmar nuevo PIN',
                controller: _confirmarPinCtrl,
                visible: _verConfirmarPin,
                onToggle: () {
                  setState(() {
                    _verConfirmarPin = !_verConfirmarPin;
                  });
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarNuevoPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C924F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Guardar nuevo PIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poltawski Nowy',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      keyboardType: TextInputType.number,
      maxLength: 6,
      enabled: !_guardando,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: _guardando ? null : onToggle,
          icon: Icon(
            visible ? Icons.visibility_off : Icons.visibility,
          ),
        ),
      ),
    );
  }
}