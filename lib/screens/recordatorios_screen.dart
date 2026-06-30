import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

// --- MODELOS DE DATOS ---
class PastillaItem {
  final int id;
  final String titulo;
  final String fecha;
  final String hora;
  final IconData icono;
  bool completado;

  PastillaItem({required this.id, required this.titulo, required this.fecha, required this.hora, required this.icono, this.completado = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'fecha': fecha,
    'hora': hora,
    'icono': icono.codePoint, 
    'completado': completado,
  };

  factory PastillaItem.fromJson(Map<String, dynamic> json) => PastillaItem(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
    titulo: json['titulo'],
    fecha: json['fecha'],
    hora: json['hora'],
    icono: IconData(json['icono'], fontFamily: 'MaterialIcons'),
    completado: json['completado'],
  );
}

class CitaItem {
  final int id;
  final String titulo;
  final String fecha;
  final String hora;
  bool completado;

  CitaItem({required this.id, required this.titulo, required this.fecha, required this.hora, this.completado = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'fecha': fecha,
    'hora': hora,
    'completado': completado,
  };

  factory CitaItem.fromJson(Map<String, dynamic> json) => CitaItem(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
    titulo: json['titulo'],
    fecha: json['fecha'],
    hora: json['hora'],
    completado: json['completado'],
  );
}

// --- PANTALLA PRINCIPAL ---
class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  List<PastillaItem> pastillas = [];
  List<CitaItem> citas = [];
  String filtroActual = 'Pendientes';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? pastillasString = prefs.getString('mis_pastillas');
    if (pastillasString != null) {
      final List<dynamic> jsonList = json.decode(pastillasString);
      if (mounted) setState(() { pastillas = jsonList.map((item) => PastillaItem.fromJson(item)).toList(); });
    }

    final String? citasString = prefs.getString('mis_citas');
    if (citasString != null) {
      final List<dynamic> jsonList = json.decode(citasString);
      if (mounted) setState(() { citas = jsonList.map((item) => CitaItem.fromJson(item)).toList(); });
    }
  }

  Future<void> _guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mis_pastillas', json.encode(pastillas.map((p) => p.toJson()).toList()));
    await prefs.setString('mis_citas', json.encode(citas.map((c) => c.toJson()).toList()));
  }

  // === PRUEBAS MANUALES (DEBUG) ===
  Future<void> _testNotificacionInmediata() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel', 'Canal de Pruebas', importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher');
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(999, 'Prueba Inmediata 🟢', 'El sistema funciona.', platformDetails);
  }

  Future<void> _testNotificacionProgramada() async {
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestExactAlarmsPermission();
    await androidImplementation?.requestNotificationsPermission();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel', 'Canal de Alarmas', importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher');
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    final tz.TZDateTime fechaProgramada = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      1000, 'Alarma 5 seg ⏰', 'Timezone funcionando perfecto.', fechaProgramada, platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // === MAGIA DE LA ALARMA PROGRAMADA (VERSIÓN BLINDADA) ===
  Future<void> _programarAlarmaPush(int idAlarma, String titulo, DateTime fechaHora) async {
    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      // 1. Solicitar permisos de manera explícita (Crítico para Android 13+)
      final bool? permisosConcedidos = await androidImplementation?.requestExactAlarmsPermission();
      debugPrint('¿Permiso de alarmas exactas concedido?: $permisosConcedidos');
      
      await androidImplementation?.requestNotificationsPermission();

      // 2. Cálculo preciso del Timezone
      final tz.TZDateTime fechaProgramada = tz.TZDateTime.from(fechaHora, tz.local);
      final tz.TZDateTime ahora = tz.TZDateTime.now(tz.local);

      debugPrint('Hora actual (TZ): $ahora');
      debugPrint('Hora programada (TZ): $fechaProgramada');

      if (fechaProgramada.isBefore(ahora)) {
        debugPrint('Error: La fecha programada está en el pasado.');
        return;
      }

      // 3. Configuración extrema del canal
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'recordatorios_urgentes_v1', 
        'Recordatorios Urgentes',
        channelDescription: 'Alarmas críticas de salud',
        importance: Importance.max,
        priority: Priority.max, 
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true, 
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      // 4. Programación
      await flutterLocalNotificationsPlugin.zonedSchedule(
        idAlarma,
        '¡Recordatorio de Salud! 💊',
        'Es hora de: $titulo',
        fechaProgramada,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Alarma programada con éxito para: $fechaProgramada');

    } catch (e) {
      debugPrint('❌ Error catastrófico al programar la alarma: $e');
    }
  }

  Future<void> _cancelarAlarmaPush(int idAlarma) async {
    await flutterLocalNotificationsPlugin.cancel(idAlarma);
  }

  @override
  Widget build(BuildContext context) {
    List<PastillaItem> pastillasFiltradas = pastillas.where((p) {
      if (filtroActual == 'Pendientes') return !p.completado;
      if (filtroActual == 'Completados') return p.completado;
      return true; 
    }).toList();
    
    List<CitaItem> citasFiltradas = citas.where((c) {
      if (filtroActual == 'Pendientes') return !c.completado;
      if (filtroActual == 'Completados') return c.completado;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFFFB), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFFFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF306339)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(context),
          _buildFiltros(),
          // 🟢 La zona expandida es SOLO para las listas que hacen scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('MIS PASTILLAS'),
                  const SizedBox(height: 15),
                  if (pastillasFiltradas.isEmpty) _buildEmptyState('No hay pastillas en esta vista.')
                  else ...pastillasFiltradas.map((pastilla) => _buildPillCard(pastilla)),
                  
                  const SizedBox(height: 35),
                  _buildSectionTitle('MIS CITAS MÉDICAS'),
                  const SizedBox(height: 15),
                  if (citasFiltradas.isEmpty) _buildEmptyState('No hay citas en esta vista.')
                  else ...citasFiltradas.map((cita) => _buildAppointmentCard(cita)),
                  
                  // Agregamos un poco de espacio al final de la lista
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // 🟢 Los botones ahora están FUERA del scroll, pegados abajo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFFFB),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 10, 
                  offset: const Offset(0, -5)
                )
              ]
            ),
            child: _buildActionButtons(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ['Pendientes', 'Completados', 'Todos'].map((filtro) {
          bool activo = filtroActual == filtro;
          return GestureDetector(
            onTap: () => setState(() => filtroActual = filtro),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: activo ? const Color(0xFF4C924F) : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
              child: Text(filtro, style: TextStyle(color: activo ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
           );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(mensaje, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7A8C7A), letterSpacing: 1.1));
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF306339), 
        borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recordatorios', 
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  fontFamily: 'Poltawski Nowy'
                )
              ),
              SizedBox(height: 5),
              Text(
                'Tus pastillas y citas', 
                style: TextStyle(
                  color: Color(0xFFEEFFEF), 
                  fontSize: 15, 
                  fontFamily: 'Poltawski Nowy'
                )
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onSelected: (value) {
              if (value == 'inmediata') _testNotificacionInmediata();
              if (value == 'programada') _testNotificacionProgramada();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'inmediata', child: Text('Probar Notif. Inmediata')),
              const PopupMenuItem(value: 'programada', child: Text('Probar Notif. en 5 seg')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillCard(PastillaItem pastilla) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: pastilla.completado ? const Color(0xFF4C924F) : Colors.grey.shade200)),
      color: pastilla.completado ? const Color(0xFFEEFFEF) : Colors.white,
      child: ListTile(
        onTap: () => _marcarComoTomada(pastilla),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: pastilla.completado ? const Color(0xFF4C924F).withOpacity(0.2) : const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
          child: Icon(pastilla.icono, color: const Color(0xFF4C924F)),
        ),
        title: Text(pastilla.titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: pastilla.completado ? TextDecoration.lineThrough : null)),
        subtitle: Text('${pastilla.fecha} - ${pastilla.hora}', style: TextStyle(color: pastilla.completado ? const Color(0xFF4C924F) : Colors.grey.shade600, fontSize: 12)),
        trailing: pastilla.completado ? const Icon(Icons.check_circle, color: Color(0xFF4C924F)) : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildAppointmentCard(CitaItem cita) {
    return Card(
      elevation: 1, margin: const EdgeInsets.only(bottom: 12), shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), 
        side: BorderSide(color: cita.completado ? const Color(0xFF4C924F) : Colors.transparent)
      ),
      color: cita.completado ? const Color(0xFFEEFFEF) : Colors.white,
      child: ListTile(
        onTap: () {
          setState(() { cita.completado = !cita.completado; });
          if (cita.completado) { _cancelarAlarmaPush(cita.id); }
          _guardarDatos();
        },
        leading: const Icon(Icons.calendar_month, size: 35, color: Color(0xFF4C924F)),
        title: Text(cita.titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, decoration: cita.completado ? TextDecoration.lineThrough : null)),
        subtitle: Text('${cita.fecha} - ${cita.hora}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: cita.completado ? const Icon(Icons.check_circle, color: Color(0xFF4C924F)) : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400),
      ),
    );
  }

  void _marcarComoTomada(PastillaItem pastilla) {
    if (pastilla.completado) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Deshacer', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('¿Deseas volver a marcar "${pastilla.titulo}" como pendiente?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                setState(() { pastilla.completado = false; });
                _guardarDatos(); 
                Navigator.pop(context);
              }, 
              child: const Text('Sí, pendiente', style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      );
      return; 
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Ya te tomaste: ${pastilla.titulo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Aún no', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              setState(() { pastilla.completado = true; });
              _cancelarAlarmaPush(pastilla.id); 
              _guardarDatos(); 
              Navigator.pop(context);
            }, 
            child: const Text('Sí, ya la tomé', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _mostrarFormulario(context, 'Pastilla'),
            icon: const Icon(Icons.add, size: 18), label: const Text('Pastilla'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _mostrarFormulario(context, 'Cita'),
            icon: const Icon(Icons.calendar_today, size: 18), label: const Text('Cita'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color(0xFF4C924F)), foregroundColor: const Color(0xFF4C924F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ),
      ],
    );
  }

  void _mostrarFormulario(BuildContext context, String tipo) {
    final TextEditingController nombreCtrl = TextEditingController();
    final TextEditingController fechaCtrl = TextEditingController();
    final TextEditingController horaCtrl = TextEditingController();
    
    DateTime? fechaSeleccionada;
    TimeOfDay? horaSeleccionada;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Agregar $tipo", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(controller: nombreCtrl, decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fechaCtrl, readOnly: true,
                    onTap: () async {
                      fechaSeleccionada = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (fechaSeleccionada != null && context.mounted) {
                        fechaCtrl.text = "${fechaSeleccionada!.day.toString().padLeft(2, '0')}/${fechaSeleccionada!.month.toString().padLeft(2, '0')}/${fechaSeleccionada!.year}";
                      }
                    },
                    decoration: InputDecoration(labelText: 'Fecha', suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF4C924F)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: horaCtrl, readOnly: true,
                    onTap: () async {
                      horaSeleccionada = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (horaSeleccionada != null && context.mounted) {
                        horaCtrl.text = horaSeleccionada!.format(context);
                      }
                    },
                    decoration: InputDecoration(labelText: 'Hora', suffixIcon: const Icon(Icons.access_time, color: Color(0xFF4C924F)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nombreCtrl.text.isNotEmpty && fechaSeleccionada != null && horaSeleccionada != null) {
                    final int idUnico = DateTime.now().millisecondsSinceEpoch.remainder(100000);
                    DateTime fechaHoraFinal = DateTime(
                      fechaSeleccionada!.year, fechaSeleccionada!.month, fechaSeleccionada!.day,
                      horaSeleccionada!.hour, horaSeleccionada!.minute,
                    );

                    setState(() {
                      if (tipo == 'Pastilla') {
                        pastillas.add(PastillaItem(id: idUnico, titulo: nombreCtrl.text, fecha: fechaCtrl.text, hora: horaCtrl.text, icono: Icons.medication));
                      } else {
                        citas.add(CitaItem(id: idUnico, titulo: nombreCtrl.text, fecha: fechaCtrl.text, hora: horaCtrl.text));
                      }
                    });
                    
                    _programarAlarmaPush(idUnico, nombreCtrl.text, fechaHoraFinal);
                    _guardarDatos(); 
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}