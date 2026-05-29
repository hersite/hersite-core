import 'package:flutter/material.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart';
import '../services/pin_security_service.dart';
import '../services/session_state_service.dart';
import 'home_screen.dart';
import 'registrar_screen.dart';

class InicioLogin extends StatefulWidget {
  final bool modoCuentaActiva;

  const InicioLogin({
    super.key,
    this.modoCuentaActiva = false,
  });

  @override
  State<InicioLogin> createState() => _InicioLoginState();
}

class _InicioLoginState extends State<InicioLogin> {
  final TextEditingController _dniCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  bool _cargando = true;
  bool _iniciandoSesion = false;
  bool _usarCuentaActiva = false;

  String _nombreUsuario = '';
  PerfilGestante? _perfilActivo;

  @override
  void initState() {
    super.initState();
    _prepararPantalla();
  }

  Future<void> _prepararPantalla() async {
    try {
      if (!widget.modoCuentaActiva) {
        if (!mounted) return;

        setState(() {
          _usarCuentaActiva = false;
          _perfilActivo = null;
          _nombreUsuario = '';
          _cargando = false;
        });

        return;
      }

      final activeProfileId =
          await SessionStateService.instance.getActiveProfileId();

      PerfilGestante? perfil;

      if (activeProfileId != null) {
        perfil = await LocalDatabase.instance.obtenerPerfilPorId(activeProfileId);
      }

      if (!mounted) return;

      if (perfil != null) {
        final perfilSeguro = perfil;
        setState(() {
          _usarCuentaActiva = true;
          _perfilActivo = perfilSeguro;
          _nombreUsuario = perfilSeguro.nombre.trim().isEmpty
              ? 'Gestante'
              : perfilSeguro.nombre.trim().split(' ').first;
          _cargando = false;
        });
      } else {
        setState(() {
          _usarCuentaActiva = false;
          _perfilActivo = null;
          _nombreUsuario = '';
          _cargando = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _usarCuentaActiva = false;
        _perfilActivo = null;
        _nombreUsuario = '';
        _cargando = false;
      });
    }
  }

  Future<void> _iniciarSesion() async {
    if (_iniciandoSesion) return;

    setState(() {
      _iniciandoSesion = true;
    });

    try {
      final pinIngresado = _pinCtrl.text.trim();

      if (pinIngresado.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El PIN debe tener 6 dígitos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      PerfilGestante? perfil;

      if (_usarCuentaActiva && _perfilActivo != null) {
        perfil = _perfilActivo;
      } else {
        final dniIngresado = _dniCtrl.text.trim();

        if (dniIngresado.length != 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El DNI debe tener 8 dígitos.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }

        perfil = await LocalDatabase.instance.obtenerPerfilPorDni(dniIngresado);

        if (perfil == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No existe una cuenta local con ese DNI.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      if (perfil == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cuenta local no tiene un identificador válido.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final perfilSeguro = perfil;

      if (perfilSeguro.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La cuenta local no tiene un identificador válido.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (perfilSeguro.pinHash.isEmpty || perfilSeguro.pinSalt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta cuenta no tiene PIN configurado. Registra la cuenta nuevamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final pinValido = PinSecurityService.instance.verifyPin(
        inputPin: pinIngresado,
        storedHash: perfilSeguro.pinHash,
        storedSalt: perfilSeguro.pinSalt,
      );

      if (!pinValido) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN incorrecto. Inténtalo nuevamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      await SessionStateService.instance.setActiveProfileId(perfilSeguro.id!);
      await SessionStateService.instance.markSessionActive();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Home(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar sesión: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _iniciandoSesion = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dniCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBFFFB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4C924F)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF316533),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'img/logo_tesis.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                Text(
                  _usarCuentaActiva
                      ? '¡Hola, $_nombreUsuario!'
                      : 'Iniciar sesión',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                    color: Color(0xFF434C43),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _usarCuentaActiva
                      ? 'Ingresa tu PIN para continuar.'
                      : 'Ingresa tu DNI y PIN de seguridad.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
                const SizedBox(height: 40),

                if (!_usarCuentaActiva) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documento de Identidad (DNI)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF434C43),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dniCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: InputDecoration(
                          hintText: 'Ej. 12345678',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            Icons.badge,
                            color: Color(0xFF306339),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF4C924F),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PIN de Seguridad (6 dígitos)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF434C43),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '******',
                        hintStyle: const TextStyle(letterSpacing: 2),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Color(0xFF306339),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4C924F),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _iniciandoSesion ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C924F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _iniciandoSesion ? 'Validando...' : 'Ingresar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (!_usarCuentaActiva)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes una cuenta?',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InicioRegistrarse(),
                            ),
                          );
                        },
                        child: const Text(
                          'Regístrate aquí',
                          style: TextStyle(
                            color: Color(0xFF306339),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (_usarCuentaActiva)
                  TextButton(
                    onPressed: () async {
                      await SessionStateService.instance.markSessionClosed();

                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InicioLogin(
                            modoCuentaActiva: false,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Ingresar con otra cuenta',
                      style: TextStyle(
                        color: Color(0xFF306339),
                        fontWeight: FontWeight.bold,
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
}