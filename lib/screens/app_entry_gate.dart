import 'package:flutter/material.dart';

import '../database/local_database.dart';
import '../services/session_state_service.dart';
import 'inicio_screen.dart';
import 'ingresar_screen.dart';

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _cargando = true;
  bool _debePedirSoloPin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verificarEstadoLocal();
  }

  Future<void> _verificarEstadoLocal() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final sesionCerrada =
          await SessionStateService.instance.isSessionClosed();

      final activeProfileId =
          await SessionStateService.instance.getActiveProfileId();

      var perfilActivoExiste = false;

      if (activeProfileId != null) {
        final perfil =
            await LocalDatabase.instance.obtenerPerfilPorId(activeProfileId);

        perfilActivoExiste = perfil != null;
      }

      if (!mounted) return;

      setState(() {
        _debePedirSoloPin =
            !sesionCerrada && activeProfileId != null && perfilActivoExiste;

        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F8F1),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4C924F),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F8F1),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo verificar la sesión local.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF434C43),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verificarEstadoLocal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C924F),
                    ),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_debePedirSoloPin) {
      return const InicioLogin(modoCuentaActiva: true);
    }

    return const InicioPrimer();
  }
}