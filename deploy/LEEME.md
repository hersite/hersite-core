# Actualizar el panel y el backend desde Git

El panel 1.1.0 incorpora revisión explícita por evaluación, meses completos en
Tendencias y triaje por riesgo alto y recencia. No modifica Android: no requiere
un APK nuevo. Revisar una evaluación no registra atención ni elimina su prioridad.

## 1. En la computadora

Después del commit, subir los cambios a la rama `her`:

```bash
git push origin her
```

## 2. En la terminal SSH de la VM de Google Cloud

Descargar la rama y preparar una copia limpia de la versión. Este `worktree`
pertenece al mismo repositorio y conserva intacta la instalación anterior y sus
configuraciones locales; no requiere subir paquetes comprimidos.

```bash
set -e
cd /home/jpierre1311/hersite-core
git fetch origin her
version=$(git rev-parse --short origin/her)
destino="/home/jpierre1311/nuvia-panel-$version"
git worktree add --detach "$destino" origin/her
bash "$destino/deploy/actualizar_vm.sh"
```

No ejecutar `git pull`, `reset` ni `clean` sobre la carpeta antigua de la VM sin
revisar sus cambios locales. El procedimiento anterior no los sobrescribe.

El script verifica la instalación conocida, compila con `npm ci`, ejecuta pruebas
aisladas y respalda PostgreSQL, el código/configuración privada, servicio y panel
antes de activar. Conserva el `.env` y reutiliza el entorno Python Linux actual:
no se añadieron dependencias. No elimina cuentas ni evaluaciones. La tabla de
revisiones se crea de forma aditiva; no se inventan revisiones ni fechas pasadas.

Tras reiniciar, comprueba tanto `/health` como la versión durante un máximo de
180 segundos, tolerando errores temporales de conexión y 502/503 durante el
arranque. No publica el panel hasta que ambas comprobaciones pasan. No basta
con que systemd indique «active»: Python puede seguir iniciando la aplicación.

Si falla la activación intenta volver al servicio e índice anteriores. No restaura
automáticamente la BD, para no perder evaluaciones recibidas después del respaldo.
Si aparece un error, conservar la salida y no borrar archivos ni repetir a ciegas.

Al terminar debe aparecer `NUVIA 1.1.0 ACTIVADA`. Actualizar el navegador y comprobar
con una cuenta de prueba: abrir su ficha no marca la evaluación; el botón explícito
sí guarda profesional y fecha. Una evaluación nueva queda «Por revisar» y conserva
el historial anterior. La prioridad de riesgo alto se mantiene.

No eliminar el directorio ni el entorno Python de la versión anterior: siguen
siendo necesarios para el servicio y la posibilidad de volver atrás.
Los respaldos contienen datos privados: no compartirlos ni subirlos al repositorio.
