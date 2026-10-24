import 'package:flutter/material.dart';
import 'screens/app_entry_gate.dart';
//import 'screens/prediccion_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart'
    as tz; // 🟢 IMPORTANTE: Faltaba este import para leer la locación
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/recordatorio_notificaciones.dart';

// Variable global para usarla en toda la app
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    RecordatorioNotificaciones.instance.plugin;

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
    final colores = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4C924F),
      primary: const Color(0xFF4C924F),
      onPrimary: Colors.white,
      secondary: const Color(0xFF306339),
      surface: const Color(0xFFFBFFFB),
      onSurface: const Color(0xFF434C43),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Gestantes',
      theme: ThemeData(
        colorScheme: colores,
        fontFamily: 'Poltawski Nowy',
        scaffoldBackgroundColor: colores.surface,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorMaxLines: 4,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFB9BAB9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colores.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colores.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colores.error, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: colores.primary,
          ),
        ),
      ),
      home: const AppEntryGate(),
    );
  }
}
