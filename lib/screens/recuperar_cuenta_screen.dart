import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/recuperar_cuenta_service.dart';
import '../services/connectivity_sync_service.dart';
import '../models/perfil_gestante.dart';
import 'home_screen.dart';

class RecuperarCuentaScreen extends StatefulWidget {
  const RecuperarCuentaScreen({super.key, this.dni});
  final String? dni;
  @override
  State<RecuperarCuentaScreen> createState() => _RecuperarCuentaScreenState();
}

class _RecuperarCuentaScreenState extends State<RecuperarCuentaScreen> {
  final _form = GlobalKey<FormState>();
  final _dni = TextEditingController();
  final _pin = TextEditingController();
  final _service = RecuperarCuentaService();
  bool _ocupado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dni.text = widget.dni ?? '';
  }

  @override
  void dispose() {
    _dni.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _recuperar() async {
    if (_ocupado || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final dni = _dni.text.trim();
    final pin = _pin.text.trim();
    try {
      final datos = await _service.consultar(dni, pin);
      if (!mounted) return;
      final perfil = Map<String, dynamic>.from(datos['perfil'] as Map);
      final vista = PerfilGestante.fromMapDb({
        ...perfil,
        'pin_hash': '',
        'pin_salt': '',
      });
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Encontramos tu cuenta'),
          scrollable: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                perfil['nombre'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('DNI: ${perfil['dni']}'),
              Text('Celular: ${perfil['celular']}'),
              Text(
                'Fecha de nacimiento: ${vista.fechaNacimiento == null ? 'No registrada' : '${vista.fechaNacimiento!.day}/${vista.fechaNacimiento!.month}/${vista.fechaNacimiento!.year}'}',
              ),
              Text('Semanas de embarazo: ${vista.semanasActuales}'),
              Text('Embarazos: ${vista.numeroEmbarazos}'),
              Text(
                vista.presionBasalDisponible == 1
                    ? 'Presión: ${vista.presionBasalSistolica}/${vista.presionBasalDiastolica}'
                    : 'Presión: no registrada',
              ),
              const SizedBox(height: 8),
              for (final campo in {
                'Cesárea previa': vista.cesareaPrevia,
                'Diabetes': vista.diabetes,
                'Hipertensión previa': vista.hipertensionPrevia,
                'Pre-eclampsia previa': vista.preeclampsiaPrevia,
                'Anemia gestacional': vista.anemiaGestacional,
                'Embarazo múltiple': vista.embarazoMultiple,
                'Hemorragia importante previa': vista.antecedenteHemorragia,
              }.entries)
                Text('${campo.key}: ${campo.value == 1 ? 'Sí' : 'No'}'),
              const SizedBox(height: 12),
              Text(
                '${(datos['evaluaciones'] as List).length} evaluaciones guardadas',
              ),
              const SizedBox(height: 12),
              const Text(
                'Usaremos los datos de esta cuenta. Las evaluaciones y los recordatorios nuevos de este teléfono se conservarán.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Después ingresarás con el PIN que acabas de escribir.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Recuperar'),
            ),
          ],
        ),
      );
      if (confirmado != true || !mounted) return;
      await _service.recuperar(dni, pin, datos['token'] as String);
      if (!mounted) return;
      unawaited(ConnectivitySyncService.instance.start());
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError
              ? error.message
              : 'No pudimos recuperar tu cuenta. Inténtalo otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_ocupado,
    child: Scaffold(
      appBar: AppBar(title: const Text('Recuperar mi cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: Color(0xFF306339),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Cambiaste de teléfono o instalaste de nuevo la app?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Escribe tu DNI y el PIN que usabas antes. Necesitas conexión a internet.',
                  style: TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _dni,
                  enabled: !_ocupado,
                  readOnly: widget.dni != null,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tu DNI',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => RegExp(r'^\d{8}$').hasMatch(v ?? '')
                      ? null
                      : 'Escribe los 8 números de tu DNI.',
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _pin,
                  enabled: !_ocupado,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'El PIN que usabas antes',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => RegExp(r'^\d{6}$').hasMatch(v ?? '')
                      ? null
                      : 'Escribe los 6 números de tu PIN.',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _ocupado ? null : _recuperar,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      _ocupado ? 'Un momento…' : 'Recuperar mi cuenta',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Solo podrás recuperar los datos que se guardaron antes de cambiar de teléfono.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
