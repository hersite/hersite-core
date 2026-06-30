import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class IndicadorConexion extends StatefulWidget {
  const IndicadorConexion({super.key});

  @override
  State<IndicadorConexion> createState() => _IndicadorConexionState();
}

class _IndicadorConexionState extends State<IndicadorConexion> {
  bool _hayConexion = false;
  late StreamSubscription<List<ConnectivityResult>> _conexionSubscription;

  @override
  void initState() {
    super.initState();
    _verificarConexionInicial();
    
    // Escuchar cambios de red automáticamente
    _conexionSubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _hayConexion = results.any((result) => result != ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _verificarConexionInicial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hayConexion = results.any((result) => result != ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _conexionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _hayConexion ? const Color(0xFF2E7D32) : const Color(0xFF6EA377),
        borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 🟢 Importante para que no ocupe toda la pantalla
        children: [
          Icon(
            _hayConexion ? Icons.wifi : Icons.wifi_off,
            color: _hayConexion ? Colors.white : const Color(0xFF2CE42C),
            size: 14
          ),
          const SizedBox(width: 5),
          Text(
            _hayConexion ? 'Sincronizado' : 'Modo offline',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}