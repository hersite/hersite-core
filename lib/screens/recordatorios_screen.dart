import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart'; // Asegúrate de que este import traiga el plugin correctamente

class RecordatoriosScreen extends StatelessWidget {
  const RecordatoriosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo más limpio
      backgroundColor: const Color(0xFFF9F9F9), 
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('PASTILLAS DE HOY'),
                  const SizedBox(height: 15),
                  _buildPillCard('Tomar Hierro', 'Pendiente - 8:00 am', Icons.medication_liquid),
                  const SizedBox(height: 12),
                  _buildPillCard('Tomar Vitaminas', 'Pendiente - 10:00 am', Icons.medication),
                  
                  const SizedBox(height: 35),
                  _buildSectionTitle('PRÓXIMA CITA'),
                  const SizedBox(height: 15),
                  _buildAppointmentCard(),

                  const SizedBox(height: 40),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENTES VISUALES MEJORADOS ---

  Widget _buildSectionTitle(String title) {
    return Text(title, 
      style: const TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w800, 
        color: Color(0xFF7A8C7A), // Un verde grisáceo más elegante
        letterSpacing: 1.1
      )
    );
  }

Widget _buildHeader(BuildContext context) {
    return Container(
      // Respetamos el espacio de la barra de estado (la hora, batería)
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 10, right: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF4C924F), // Tu verde de marca
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Botón de regreso (siempre es bueno tenerlo)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context), 
          ),
          const SizedBox(width: 5),
          const Text('Recordatorios', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const Spacer(),
          // ¡TU CAMPANA DE VUELTA!
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () => _mostrarNotificacion(), // Esto disparará la notificación local
          ),
        ],
      ),
    );
  }

  Widget _buildPillCard(String title, String subtitle, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF4C924F)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ),
    );
  }

  Widget _buildAppointmentCard() {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 35, color: Color(0xFF4C924F)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Control Prenatal #7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Jueves 15 de mayo - 10:00 am', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _mostrarFormulario(context, 'Pastilla'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Pastilla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C924F), 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _mostrarFormulario(context, 'Cita'),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Cita'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF4C924F)),
              foregroundColor: const Color(0xFF4C924F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
          ),
        ),
      ],
    );
  }

  // --- FORMULARIO Y NOTIFICACIONES ---
  void _mostrarFormulario(BuildContext context, String tipo) {
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
            const SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: 'Hora', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C924F), foregroundColor: Colors.white),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarNotificacion() async {
    // 1. Pedir permiso (Obligatorio en Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // 2. Configurar cómo se verá la notificación en Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'recordatorios_channel', // ID del canal (interno)
      'Recordatorios Médicos', // Nombre que ve el usuario en los ajustes
      channelDescription: 'Notificaciones para pastillas y citas',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Usa el ícono de tu app
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // 3. ¡Lanzar la notificación!
    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      '¡Recordatorio de Salud! 💊', // Título
      'Es hora de tomar tu suplemento de Hierro.', // Cuerpo del mensaje
      platformChannelSpecifics,
      payload: 'pastilla_hierro', // Datos ocultos si quieres leerlos al hacer clic
    );
  }
}