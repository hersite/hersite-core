# Recuperación de cuentas y guía inicial

La recuperación utiliza el DNI y el PIN de la gestante. No utiliza las cuentas del personal del panel médico, SMS ni códigos del administrador.

## Activación en Google Cloud

Estos cambios de código no actualizan por sí solos la VM. Antes de probarlos con datos reales:

1. Respaldar PostgreSQL y desplegar la nueva versión del backend en la VM, manteniendo su `DATABASE_URL` y sus volúmenes actuales.
2. Reiniciar el backend. La actualización agrega dos columnas de recuperación a `gestante` y crea las tablas de autorizaciones temporales y respaldo de recordatorios. No elimina pacientes ni evaluaciones.
3. Comprobar que el dominio tiene un certificado HTTPS válido y que el proxy dirige `/api/*` y `/health` al backend. `/health` debe devolver JSON con `status: ok` y `service: riesgo-materno-api`, no la página del panel.
4. Configurar el proxy y Uvicorn para reconocer HTTPS correctamente. No desactivar la verificación de certificados ni permitir HTTP público para transmitir DNI, PIN o información de salud.

La dirección base se mantiene en `config/google_cloud.json`. `/dashboard` corresponde al panel, no a la API. Antes de desplegar, comprobar que `/api/mobile/registro`, `/api/mobile/recuperar` y `/api/mobile/recordatorios` están publicadas: que `/health` responda no garantiza que la versión del backend sea compatible con la app.

En instalaciones antiguas donde `.env` y `.venv` estuvieron versionados, la actualización de Git puede retirarlos del directorio. Respaldar la configuración y PostgreSQL fuera del repositorio, revisar los cambios locales y conservar o reconstruir el entorno de Python antes de actualizar. No usar `git reset --hard` ni `git clean` para resolver conflictos en la VM. Desplegar también el panel compatible con la autenticación del backend, conservando su configuración de producción. La creación de un commit o APK no actualiza automáticamente el servicio de la VM.

Ejecutar la app contra esa VM, desde la raíz del proyecto:

```powershell
flutter run --dart-define-from-file=config/google_cloud.json
```

En Android Studio se puede añadir `--dart-define-from-file=config/google_cloud.json` a los argumentos de ejecución de Flutter. Sin esa opción se conserva el destino local de desarrollo `http://10.0.2.2:8000`. Para otro dominio o una API alojada en otra dirección, cambiar únicamente `API_BASE_URL` en ese archivo. No incluir `/dashboard` ni `/api` al final si las rutas se publican directamente en la raíz.

## Cuentas existentes

- Abrir la versión actualizada, ingresar con el PIN y permitir que termine el respaldo antes de desinstalar o cambiar de teléfono. El dispositivo ya autorizado habilita la recuperación del PIN sin enviarlo como texto legible ni modificar un PIN central existente.
- Una cuenta antigua que nunca habilitó la recuperación y que ya perdió su dispositivo autorizado no puede recuperarse solo con DNI y un PIN que el servidor nunca recibió. Requiere una verificación asistida; no se habilita una toma de cuenta basada en el DNI.
- Si un perfil se registra sin conexión con un DNI ya existente, no sobrescribe la cuenta ni su PIN. Al volver la conexión, se ofrece «Recuperar mi cuenta» y se exige el PIN anterior.
- El cambio de PIN ahora requiere conexión y confirmación del servicio para mantener el mismo PIN en el teléfono y en la recuperación.

## Datos y límites

Se recuperan los datos personales, antecedentes, evaluaciones y recordatorios que hayan llegado al servicio. Se conserva el UUID de cada evaluación para no duplicarla. Antes de confirmar se muestran los datos recuperados; los datos personales centrales pasan a usarse en el teléfono, manteniendo evaluaciones nuevas pendientes. Los recordatorios nuevos sin respaldo también se conservan, y los ya eliminados de la copia no se reactivan por un reintento. Se usan IDs de alarma nuevos y no se programan citas vencidas ni recordatorios completados.

Cada recuperación autoriza el teléfono nuevo y revoca la autorización de respaldo del anterior. No borra el contenido local de aquel teléfono. La primera recuperación requiere conexión; después el PIN local sigue funcionando sin internet. Solo puede recuperarse lo que se respaldó antes de perder el dispositivo.

Se deshabilita la copia automática de Android y se excluyen los archivos en las reglas de transferencia. Las claves de cifrado están ligadas al dispositivo: restaurar únicamente los archivos cifrados mediante la copia del sistema puede impedir abrir la base. El respaldo recuperable se realiza explícitamente con el servicio de la aplicación, no con la cuenta Google del teléfono. Esta configuración no elimina datos del dispositivo ni de PostgreSQL.

La guía de siete pasos resalta los controles reales y oscurece el resto de la pantalla. Aparece una vez por perfil recién registrado; permite avanzar, retroceder u omitir y puede repetirse con el botón de ayuda en Inicio. Si se cierra el proceso antes de terminarla, vuelve a ofrecerse al ingresar; no se muestra automáticamente por editar un perfil o recuperar una cuenta anterior.

## Comprobaciones

Backend, con SQLite en memoria y sin conectar a la VM:

```powershell
cd backend
.venv\Scripts\python.exe -B -m unittest discover -s tests -p test_mobile_recovery.py
```

Flutter, desde la raíz:

```powershell
flutter test test/recuperacion_y_guia_test.dart
```
