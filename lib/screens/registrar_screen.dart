import 'package:flutter/material.dart';
import 'test_model_screen.dart';
import 'antecedentes_screen.dart';
import '../data/perfil_gestante_temp.dart';
import '../services/pin_security_service.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart'; // IMPORTANTE AÑADIR ESTO

class InicioRegistrarse extends StatefulWidget {
  final bool esEdicion; // NUEVO: Bandera para saber si edita o crea

  const InicioRegistrarse({super.key, this.esEdicion = false});

  @override
  State<InicioRegistrarse> createState() => _InicioRegistrarseState();
}

class _InicioRegistrarseState extends State<InicioRegistrarse> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _dniCtrl = TextEditingController();
  final TextEditingController _celularCtrl = TextEditingController();
  final TextEditingController _fechaNacimientoCtrl = TextEditingController();
  final TextEditingController _semanasCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  DateTime? _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    // NUEVO: Si estamos en modo edición, cargamos los datos previos
    if (widget.esEdicion) {
      _cargarDatosExistentes();
    }
  }

  Future<void> _cargarDatosExistentes() async {
    final perfilDb = await LocalDatabase.instance.obtenerPerfil();
    if (perfilDb != null && mounted) {
      setState(() {
        _nombreCtrl.text = perfilDb.nombre;
        _dniCtrl.text = perfilDb.dni;
        _celularCtrl.text = perfilDb.celular;
        _semanasCtrl.text = perfilDb.semanasGestacion.toString();
        
        // Como la fecha de nacimiento no se guardaba en BD (solo la edad),
        // hacemos un cálculo inverso aproximado para rellenar el campo visualmente
        _fechaSeleccionada = DateTime.now().subtract(Duration(days: (perfilDb.edadMaterna * 365)));
        _fechaNacimientoCtrl.text = "${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}";
      });
    }
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

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime(2005, 2, 21),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C924F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF434C43),
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccion != null) {
      setState(() {
        _fechaSeleccionada = seleccion;
        _fechaNacimientoCtrl.text = "${seleccion.day.toString().padLeft(2, '0')}/${seleccion.month.toString().padLeft(2, '0')}/${seleccion.year}";
      });
    }
  }

  Future<void> _continuar() async {
    final nombre = _nombreCtrl.text.trim();
    final dni = _dniCtrl.text.trim();
    final celular = _celularCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final semanas = int.tryParse(_semanasCtrl.text.trim());

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa tu nombre completo.'), backgroundColor: Colors.redAccent));
      return;
    }

    if (dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El DNI debe tener 8 dígitos.'), backgroundColor: Colors.redAccent));
      return;
    }

    // Validación de DNI duplicado SOLO si es un registro nuevo
    if (!widget.esEdicion) {
      final perfilExistente = await LocalDatabase.instance.obtenerPerfilPorDni(dni);
      if (perfilExistente != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya existe una cuenta con este DNI. Ingresa con tu PIN.'), backgroundColor: Colors.redAccent));
        return;
      }
    }

    if (celular.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El celular debe tener 9 dígitos.'), backgroundColor: Colors.redAccent));
      return;
    }

    // Validación de PIN SOLO si es un registro nuevo
    if (!widget.esEdicion && pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El PIN debe tener 6 dígitos.'), backgroundColor: Colors.redAccent));
      return;
    }

    if (_fechaSeleccionada == null || semanas == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona tu fecha y semanas.'), backgroundColor: Colors.redAccent));
      return;
    }

    final hoy = DateTime.now();
    var edadCalculada = hoy.year - _fechaSeleccionada!.year;
    if (hoy.month < _fechaSeleccionada!.month || (hoy.month == _fechaSeleccionada!.month && hoy.day < _fechaSeleccionada!.day)) {
      edadCalculada--;
    }

    if (edadCalculada < 12 || edadCalculada > 55) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rango de edad inválido.'), backgroundColor: Colors.redAccent));
      return;
    }

    if (semanas < 1 || semanas > 42) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las semanas deben estar entre 1 y 42.'), backgroundColor: Colors.redAccent));
      return;
    }

    // === LÓGICA DIVIDIDA: EDICIÓN vs CREACIÓN ===
    if (widget.esEdicion) {
      // MODO EDICIÓN: Actualizar directo en la base de datos
      final perfilDb = await LocalDatabase.instance.obtenerPerfil();
      if (perfilDb != null) {
        PerfilGestanteTemp.actualizar({
          'IdPerfil': perfilDb.id,
          'Nombre': nombre,
          'DNI': dni,
          'Celular': celular,
          'Edad_Materna': edadCalculada,
          'Semanas_Gestacion': semanas,
          'PinHash': perfilDb.pinHash, // Se mantiene el que ya tenía
          'PinSalt': perfilDb.pinSalt, // Se mantiene el que ya tenía
          ...perfilDb.toModelInput(), // Trae los antecedentes existentes para no borrarlos
        });
        
        final perfilMap = PerfilGestanteTemp.obtener();
        final perfilActualizado = PerfilGestante.fromTempMap(perfilMap!);
        
        await LocalDatabase.instance.guardarOActualizarPerfil(perfilActualizado);
        
        if (!mounted) return;
        Navigator.pop(context); // Cierra y vuelve a la pantalla de Perfil
      }
    } else {
      // MODO REGISTRO (Tu código original)
      final pinSalt = PinSecurityService.instance.generateSalt();
      final pinHash = PinSecurityService.instance.hashPin(pin: pin, salt: pinSalt);

      PerfilGestanteTemp.actualizar({
        'Nombre': nombre,
        'DNI': dni,
        'Celular': celular,
        'PinHash': pinHash,
        'PinSalt': pinSalt,
        'Edad_Materna': edadCalculada,
        'Semanas_Gestacion': semanas,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AntecedentesScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título Dinámico
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.esEdicion ? 'Editar datos' : 'Crea tu cuenta', 
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')
                      ),
                      const SizedBox(height: 5),
                      const Text('Tus datos están protegidos\ny son privados', style: TextStyle(color: Color(0xFF434C43), fontSize: 13, fontFamily: 'Poltawski Nowy')),
                    ],
                  ),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF316533), width: 2)),
                    child: ClipOval(child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pregnant_woman, size: 40, color: Color(0xFF316533)))),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              _crearCajaTexto('Nombre Completo', 'Ej. Rosa María Huamán', _nombreCtrl),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _crearCajaTexto('DNI', 'Ej. 12345678', _dniCtrl, esNumero: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _crearCajaFecha('Fecha Nac.', '21/02/2005')),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _crearCajaTexto('Celular', 'Ej. 999000111', _celularCtrl, esNumero: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _crearCajaTexto('Sem. Gestación', 'Ej. 34', _semanasCtrl, esNumero: true)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Mostrar PIN solo si NO estamos editando
              if (!widget.esEdicion) ...[
                _crearCajaTexto('Crea tu PIN (6 dígitos)', '******', _pinCtrl, esNumero: true, ocultar: true),
                const SizedBox(height: 40),
              ] else ...[
                const SizedBox(height: 20),
              ],

              // Botón Final Dinámico
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _continuar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C924F),
                        minimumSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        widget.esEdicion ? 'Guardar cambios' : 'Continuar',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    if (!widget.esEdicion)
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TestModelScreen()));
                        },
                        child: const Text('Probar modelo ML (Dev)'),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _crearCajaTexto(String titulo, String ejemplo, TextEditingController controlador, {bool esNumero = false, bool ocultar = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434C43))),
        const SizedBox(height: 8),
        TextField(
          controller: controlador,
          obscureText: ocultar,
          keyboardType: esNumero ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: ejemplo,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF316533), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _crearCajaFecha(String titulo, String ejemplo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434C43))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _seleccionarFecha(context),
          child: AbsorbPointer(
            child: TextField(
              controller: _fechaNacimientoCtrl,
              decoration: InputDecoration(
                hintText: ejemplo,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF316533), size: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)), 
              ),
            ),
          ),
        ),
      ],
    );
  }
}