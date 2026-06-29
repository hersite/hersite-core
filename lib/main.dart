import 'package:flutter/material.dart';
import 'screens/inicio_screen.dart';
import 'services/connectivity_sync_service.dart';
//import 'screens/prediccion_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz; // 🟢 IMPORTANTE: Faltaba este import para leer la locación
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Variable global para usarla en toda la app
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 🟢 SOLUCIÓN: Esta función DEBE ir aquí afuera, antes del main()
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  debugPrint('Notificación tocada en segundo plano: ${details.payload}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🟢 CONFIGURACIÓN DE ZONA HORARIA
 tz.initializeTimeZones();
  final String timeZoneName = 'America/Lima'; 
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Modifica tu bloque de inicialización así:
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      debugPrint('Notificación tocada: ${details.payload}');
    },
    // 🟢 AQUÍ LLAMAMOS A LA FUNCIÓN GLOBAL
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  runApp(const MiAppTesis());
}

class MiAppTesis extends StatelessWidget {
  const MiAppTesis({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Gestantes',
      home: InicioPrimer(),
    );
  }
}