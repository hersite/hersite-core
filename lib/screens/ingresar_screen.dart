import 'package:flutter/material.dart';
import '../database/local_database.dart'; // IMPORTANTE: Necesitamos leer si ya existe
import 'home_screen.dart';
import 'registrar_screen.dart'; 

class InicioLogin extends StatefulWidget {
  const InicioLogin({super.key});

  @override
  State<InicioLogin> createState() => _InicioLoginState();
}

class _InicioLoginState extends State<InicioLogin> {
  final TextEditingController _dniCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  
  // Variables para la nueva lógica inteligente
  bool _cargando = true;
  bool _tienePerfilLocal = false;
  String _nombreUsuario = '';

  @override
  void initState() {
    super.initState();
    _verificarSiYaExistePerfil();
  }

  // Esta función revisa el SQLite para ver si la gestante ya usaba la app
  Future<void> _verificarSiYaExistePerfil() async {
    try {
      final perfil = await LocalDatabase.instance.obtenerPerfil();
      if (perfil != null && mounted) {
        setState(() {
          _tienePerfilLocal = true;
          // Sacamos solo el primer nombre para que sea más amigable
          _nombreUsuario = perfil.nombre.split(' ')[0]; 
          _cargando = false;
        });
      } else {
        setState(() {
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _iniciarSesion() {
    // Si NO tiene perfil local, le exigimos el DNI
    if (!_tienePerfilLocal) {
      if (_dniCtrl.text.trim().length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El DNI debe tener al menos 8 dígitos.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // Siempre exigimos el PIN de 6 dígitos
    if (_pinCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El PIN debe tener 6 dígitos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // TODO: Aquí a futuro se validará que el PIN coincida con el guardado en BD.
    // Por ahora, pasamos directo al Home.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  @override
  void dispose() {
    _dniCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras revisamos el SQLite
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBFFFB),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4C924F))),
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
                // ==============================
                // TU LOGO ORIGINAL RESTAURADO
                // ==============================
                Container(
                  width: 120, 
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    border: Border.all(color: const Color(0xFF316533), width: 2)
                  ),
                  child: ClipOval(
                    child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover)
                  ),
                ),
                const SizedBox(height: 25),

                // ==============================
                // SALUDO INTELIGENTE
                // ==============================
                Text(
                  _tienePerfilLocal ? '¡Hola, $_nombreUsuario!' : '¡Bienvenida!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poltawski Nowy',
                    color: Color(0xFF434C43),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _tienePerfilLocal 
                      ? 'Ingresa tu PIN de seguridad para continuar.' 
                      : 'Tu información clínica está protegida.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontFamily: 'Poltawski Nowy',
                  ),
                ),
                const SizedBox(height: 40),

                // ==============================
                // CAJA DE DNI (Se oculta si ya la conocemos)
                // ==============================
                if (!_tienePerfilLocal) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documento de Identidad (DNI)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF434C43)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dniCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: InputDecoration(
                          hintText: "Ej. 12345678",
                          counterText: "", 
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.badge, color: Color(0xFF306339)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF4C924F), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ==============================
                // CAJA DE PIN (Siempre visible)
                // ==============================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PIN de Seguridad (6 dígitos)', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF434C43)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6, 
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "******", 
                        hintStyle: const TextStyle(letterSpacing: 2),
                        counterText: "",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF306339)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF4C924F), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ==============================
                // BOTÓN INGRESAR
                // ==============================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C924F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Ingresar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poltawski Nowy',
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // ==============================
                // ENLACE A CREAR CUENTA (Se oculta si ya tiene perfil)
                // ==============================
                if (!_tienePerfilLocal)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "¿No tienes una cuenta?",
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
                          "Regístrate aquí",
                          style: TextStyle(
                            color: Color(0xFF306339),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}