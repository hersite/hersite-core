import 'package:flutter/material.dart';
import 'test_model_screen.dart';
import 'antecedentes_screen.dart';
import '../data/perfil_gestante_temp.dart';

class InicioRegistrarse extends StatefulWidget {
  const InicioRegistrarse({super.key});

  @override
  State<InicioRegistrarse> createState() => _InicioRegistrarseState();
}

class _InicioRegistrarseState extends State<InicioRegistrarse> {
  // Controladores para capturar lo que escribe la usuaria
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _dniCtrl = TextEditingController();
  final TextEditingController _celularCtrl = TextEditingController();
  final TextEditingController _fechaNacimientoCtrl = TextEditingController();
  final TextEditingController _semanasCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  DateTime? _fechaSeleccionada;

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

  // Abre el calendario nativo de Flutter
  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 2, 21), // Fecha base de sugerencia
      firstDate: DateTime(1970), // Límite inferior (aprox 55 años)
      lastDate: DateTime.now(),  // Límite superior (hoy)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C924F), // Verde principal
              onPrimary: Colors.white, // Letras blancas sobre el verde
              onSurface: Color(0xFF434C43), // Color de los días
            ),
          ),
          child: child!,
        );
      },
    );

    if (seleccion != null) {
      setState(() {
        _fechaSeleccionada = seleccion;
        // Formateamos para que se vea bonito en el TextField: DD/MM/YYYY
        _fechaNacimientoCtrl.text = "${seleccion.day.toString().padLeft(2, '0')}/${seleccion.month.toString().padLeft(2, '0')}/${seleccion.year}";
      });
    }
  }

  void _continuar() {
    // 1. Validamos que haya seleccionado fecha y escrito las semanas
    final semanas = int.tryParse(_semanasCtrl.text.trim());

    if (_fechaSeleccionada == null || semanas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona tu fecha de nacimiento y semanas de gestación.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. Calculamos la edad exacta a partir del calendario
    final hoy = DateTime.now();
    int edadCalculada = hoy.year - _fechaSeleccionada!.year;
    if (hoy.month < _fechaSeleccionada!.month || 
       (hoy.month == _fechaSeleccionada!.month && hoy.day < _fechaSeleccionada!.day)) {
      edadCalculada--; // Le restamos 1 si aún no cumple años este año
    }

    if (edadCalculada < 12 || edadCalculada > 55) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La edad calculada no está en un rango válido para el registro.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (semanas < 1 || semanas > 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las semanas de gestación deben estar entre 1 y 42.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3. GUARDAMOS EN LA MEMORIA TEMPORAL LOS DATOS DEL ML
    PerfilGestanteTemp.actualizar({
      'Edad_Materna': edadCalculada, // Pasamos la edad calculada matemáticamente
      'Semanas_Gestacion': semanas,
      'Nombre': _nombreCtrl.text.trim(), 
    });

    // 4. Viajamos al Asistente de Antecedentes Médicos
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AntecedentesScreen()),
    );
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
              // Título y Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crea tu cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy')),
                      SizedBox(height: 5),
                      Text('Tus datos están protegidos\ny son privados', style: TextStyle(color: Color(0xFF434C43), fontSize: 13, fontFamily: 'Poltawski Nowy')),
                    ],
                  ),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF316533), width: 2)),
                    child: ClipOval(child: Image.asset('assets/img/logo_tesis.png', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pregnant_woman, size: 40, color: Color(0xFF316533)))),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // Formulario Demográfico y Clínico Básico
              _crearCajaTexto('Nombre Completo', 'Ej. Rosa María Huamán', _nombreCtrl),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: _crearCajaTexto('DNI', 'Ej. 12345678', _dniCtrl, esNumero: true)),
                  const SizedBox(width: 15),
                  // AQUÍ ESTÁ LA NUEVA CAJA DE FECHA CON CALENDARIO
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
              
              _crearCajaTexto('Crea tu PIN (4 dígitos)', '****', _pinCtrl, esNumero: true, ocultar: true),
              const SizedBox(height: 40),

              // Botón Final
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
                      child: const Text(
                        'Continuar',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poltawski Nowy'),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    // Botón para tus pruebas internas
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

  // Caja de Texto normal
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

  // NUEVA: Caja de Fecha que bloquea el teclado y abre el DatePicker
  Widget _crearCajaFecha(String titulo, String ejemplo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF434C43))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _seleccionarFecha(context),
          child: AbsorbPointer( // Esto evita que suba el teclado normal
            child: TextField(
              controller: _fechaNacimientoCtrl,
              decoration: InputDecoration(
                hintText: ejemplo,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF316533), size: 20),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)), // En disabled tmb gris
              ),
            ),
          ),
        ),
      ],
    );
  }
}