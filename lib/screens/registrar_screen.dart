import 'package:flutter/material.dart';
import 'antecedentes_screen.dart';
import '../data/perfil_gestante_temp.dart';
import '../services/pin_security_service.dart';
import '../database/local_database.dart';
import '../models/perfil_gestante.dart'; 

import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class InicioRegistrarse extends StatefulWidget {
  final bool esEdicion; 

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
        _nombreCtrl.text = perfilDb.nombre;
        _dniCtrl.text = perfilDb.dni;
        _celularCtrl.text = perfilDb.celular;
        _semanasCtrl.text = perfilDb.semanasGestacion.toString();
        
        _fechaSeleccionada = DateTime.now().subtract(Duration(days: (perfilDb.edadMaterna * 365)));
        _fechaNacimientoCtrl.text = "${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/${_fechaSeleccionada!.year}";
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _dniCtrl.dispose(); _celularCtrl.dispose(); _fechaNacimientoCtrl.dispose(); _semanasCtrl.dispose(); _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime(2005, 2, 21),
      firstDate: DateTime(1970), lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF4C924F), onPrimary: Colors.white, onSurface: Color(0xFF434C43))), child: child!);
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
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final nombre = _nombreCtrl.text.trim();
    final dni = _dniCtrl.text.trim();
    final celular = _celularCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    final semanas = int.tryParse(_semanasCtrl.text.trim());

    if (nombre.isEmpty || dni.length != 8 || celular.length != 9 || _fechaSeleccionada == null || semanas == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa todos los campos correctamente.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    if (!widget.esEdicion && pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El PIN debe tener 6 dígitos.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    if (!widget.esEdicion) {
      final perfilExistente = await LocalDatabase.instance.obtenerPerfilPorDni(dni);
      if (perfilExistente != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya existe una cuenta con este DNI. Ingresa con tu PIN.'), backgroundColor: Colors.redAccent));
        setState(() => _isSaving = false);
        return;
      }
    }

    final hoy = DateTime.now();
    var edadCalculada = hoy.year - _fechaSeleccionada!.year;
    if (hoy.month < _fechaSeleccionada!.month || (hoy.month == _fechaSeleccionada!.month && hoy.day < _fechaSeleccionada!.day)) edadCalculada--;

    if (edadCalculada < 12 || edadCalculada > 55 || semanas < 1 || semanas > 42) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valores de edad o semanas fuera de rango.'), backgroundColor: Colors.redAccent));
      setState(() => _isSaving = false);
      return;
    }

    if (widget.esEdicion) {
      // 🟢 MODO EDICIÓN CORREGIDO
      // 🟢 MODO EDICIÓN CORREGIDO
      try {
        final perfilDb = await LocalDatabase.instance.obtenerPerfil();
        if (perfilDb != null) {
          PerfilGestanteTemp.actualizar({
            ...perfilDb.toModelInput(), 
            'IdPerfil': perfilDb.id, 
            'Nombre': nombre, 
            'DNI': dni, 
            'Celular': celular, 
            'Edad_Materna': edadCalculada, 
            'Semanas_Gestacion': semanas, 
            'PinHash': perfilDb.pinHash, 
            'PinSalt': perfilDb.pinSalt, 
          });
          
          final perfilActualizado = PerfilGestante.fromTempMap(PerfilGestanteTemp.obtener()!);
          
          // 1. Guarda en el celular (SQLite)
          await LocalDatabase.instance.guardarOActualizarPerfil(perfilActualizado);
          
          // 🟢 2. INTENTA SINCRONIZAR CON EL SERVIDOR (FastAPI -> pgAdmin)
          try {
            await ApiClient.instance.enviarPerfil(perfilActualizado);
            debugPrint('Sincronización con el servidor exitosa.');
          } catch (e) {
            debugPrint('Guardado localmente. Se sincronizará cuando haya red: $e');
          }

          // 3. Reseteamos la fecha ancla
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fecha_ancla_usuario', DateTime.now().toIso8601String());

          // 4. Actualiza la memoria visual
          await LocalDatabase.instance.obtenerPerfil();

          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados y actualizados', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF4C924F)));
          Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) setState(() => _isSaving = false);
      }
    } else {
      // 🟢 MODO CREACIÓN NORMAL
      final pinSalt = PinSecurityService.instance.generateSalt();
      final pinHash = PinSecurityService.instance.hashPin(pin: pin, salt: pinSalt);

      PerfilGestanteTemp.actualizar({'Nombre': nombre, 'DNI': dni, 'Celular': celular, 'PinHash': pinHash, 'PinSalt': pinSalt, 'Edad_Materna': edadCalculada, 'Semanas_Gestacion': semanas});
      
      setState(() => _isSaving = false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AntecedentesScreen()));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.esEdicion ? 'Editar datos' : 'Crea tu cuenta', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')), const SizedBox(height: 5), const Text('Tus datos están protegidos\ny son privados', style: TextStyle(color: Color(0xFF434C43), fontSize: 13, fontFamily: 'Poltawski Nowy'))]),
                  Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF316533), width: 2)), child: ClipOval(child: Image.asset('img/logo_tesis.png', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pregnant_woman, size: 40, color: Color(0xFF316533))))),
                ],
              ),
              const SizedBox(height: 30),

              _crearCajaTexto('Nombre Completo', 'Ej. Rosa María Huamán', _nombreCtrl), const SizedBox(height: 20),
              Row(children: [Expanded(child: _crearCajaTexto('DNI', 'Ej. 12345678', _dniCtrl, esNumero: true)), const SizedBox(width: 15), Expanded(child: _crearCajaFecha('Fecha Nac.', '21/02/2005'))]),
              const SizedBox(height: 20),
              Row(children: [Expanded(child: _crearCajaTexto('Celular', 'Ej. 999000111', _celularCtrl, esNumero: true)), const SizedBox(width: 15), Expanded(child: _crearCajaTexto('Sem. Gestación', 'Ej. 34', _semanasCtrl, esNumero: true))]),
              const SizedBox(height: 20),
              
              if (!widget.esEdicion) ...[_crearCajaTexto('Crea tu PIN (6 dígitos)', '******', _pinCtrl, esNumero: true, ocultar: true), const SizedBox(height: 40)] else ...[const SizedBox(height: 20)],

              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _continuar,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), minimumSize: const Size(200, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: _isSaving 
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(widget.esEdicion ? 'Guardar cambios' : 'Continuar', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                    ),
                    const SizedBox(height: 12),
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
        Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434C43))), const SizedBox(height: 8),
        TextField(controller: controlador, obscureText: ocultar, keyboardType: esNumero ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: ejemplo, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF316533), width: 2)))),
      ],
    );
  }

  Widget _crearCajaFecha(String titulo, String ejemplo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434C43))), const SizedBox(height: 8),
        GestureDetector(onTap: () => _seleccionarFecha(context), child: AbsorbPointer(child: TextField(controller: _fechaNacimientoCtrl, decoration: InputDecoration(hintText: ejemplo, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF316533), size: 20), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)))))),
      ],
    );
  }
}