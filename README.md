# Nuvia

Aplicación de acompañamiento del embarazo para Android, con evaluaciones locales, recordatorios y material educativo. Incluye una API en FastAPI y el panel médico.

## Aplicación Android

```bash
flutter pub get
flutter run --dart-define-from-file=config/google_cloud.json
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config/google_cloud.json
```

La dirección pública del servicio está en `config/google_cloud.json`; no contiene credenciales. El APK se genera en `build/app/outputs/flutter-apk/`. La firma actual es de desarrollo, no de publicación en Play Store.

## Backend y despliegue

Consultar [recuperación de cuentas y actualización del servidor](backend/RECUPERACION_CUENTAS.md). Conservar el `.env` y la base de datos de la VM: un commit o un APK no actualizan el servidor automáticamente. No versionar credenciales, entornos virtuales, bases de datos ni APK.

