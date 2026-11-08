#!/usr/bin/env bash
# Actualización de Nuvia en la VM conocida. No ejecutar como root.
set -Eeuo pipefail
umask 077

base=/home/jpierre1311
service=hersite-backend.service
panel=/var/www/hersite
override=/etc/systemd/system/hersite-backend.service.d/zzzz-nuvia-current.conf
public_url=https://nuvia-136-64-236-164.sslip.io
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

[[ $(id -un) == jpierre1311 ]] || { echo 'Ejecuta esto como jpierre1311.'; exit 1; }
[[ -d "$source_dir/backend/app" && -f "$source_dir/dashboard-medico/package-lock.json" ]] || {
  echo 'Faltan archivos del repositorio. Descarga la versión completa con Git.'; exit 1;
}
case "$source_dir" in "$base"/*) ;; *) echo 'El repositorio debe estar dentro de /home/jpierre1311.'; exit 1;; esac
[[ "$source_dir" =~ ^[a-zA-Z0-9_./-]+$ ]] || { echo 'Usa una ruta sin espacios ni caracteres especiales.'; exit 1; }
sudo -v
sudo test ! -L "$override" || { echo 'La configuración del servicio es un enlace inesperado; se canceló.'; exit 1; }
current_backend=$(systemctl show --value -p WorkingDirectory "$service")
current_backend=$(realpath -e -- "$current_backend")
case "$current_backend" in "$base"/*/backend) ;; *) echo 'Directorio del servicio inesperado; se canceló.'; exit 1;; esac
[[ "$current_backend" =~ ^[a-zA-Z0-9_./-]+$ ]] || exit 1
venv=$(realpath -e -- "$current_backend/.venv")
[[ "$venv" =~ ^[a-zA-Z0-9_./-]+$ && -x "$venv/bin/uvicorn" && -f "$current_backend/.env" ]] || exit 1
[[ $(realpath -e -- "$panel") == "$panel" ]] || { echo 'La raíz del panel es un enlace inesperado; se canceló.'; exit 1; }

# Comprobar que el respaldo corresponde a la BD PostgreSQL local utilizada por el servicio.
"$venv/bin/python" - "$current_backend/.env" <<'PY'
import sys
from dotenv import dotenv_values
from sqlalchemy.engine import make_url
u = make_url(dotenv_values(sys.argv[1])['DATABASE_URL'])
assert u.get_backend_name() == 'postgresql' and u.database == 'riesgo_materno_db'
assert u.host in (None, 'localhost', '127.0.0.1'), 'La BD no es local; revisa el respaldo antes de actualizar.'
PY

release=$source_dir
[[ "$current_backend" != "$release/backend" && ! -e "$release/backend/.env" && ! -e "$release/backend/.venv" ]] || {
  echo 'Usa un worktree nuevo de Git; no se sobrescribió la configuración existente.'; exit 1;
}
echo 'Compilando el panel desde el código descargado con Git…'
(cd "$release/dashboard-medico" && npm ci --no-audit --no-fund && VITE_API_BASE_URL="$public_url" npm run build)
backup=$(mktemp -d "$base/respaldo-nuvia-1.1.0.XXXXXX")
install -m 600 -- "$current_backend/.env" "$release/backend/.env"
# No hay dependencias nuevas: conserva el entorno Linux que ya funciona.
ln -s -- "$venv" "$release/backend/.venv"
(cd "$release/backend" && "$venv/bin/python" -m unittest discover -s tests -v)

echo 'Generando respaldos privados antes de activar…'
sudo -u postgres pg_dump -Fc riesgo_materno_db > "$backup/postgresql.dump"
pg_restore --list "$backup/postgresql.dump" > /dev/null
sudo systemctl cat "$service" > "$backup/servicio.txt"
override_existed=0
if sudo test -e "$override"; then
  sudo test -f "$override" || { echo 'La configuración del servicio no es un archivo regular; se canceló.'; exit 1; }
  sudo cat "$override" > "$backup/override-anterior.conf"
  override_existed=1
fi
sudo tar --dereference -czf "$backup/panel.tar.gz" -C /var/www hersite
sudo cat "$panel/index.html" > "$backup/index.html"
tar --exclude=.venv --exclude=__pycache__ -czf "$backup/backend.tar.gz" -C "$current_backend" .

activated=0
panel_touched=0
rollback() {
  local status=$1
  trap - ERR INT TERM
  echo 'No se completó la actualización. Restaurando la versión anterior…'
  if (( activated )); then
    sudo journalctl -u "$service" --since '5 minutes ago' --no-pager -n 160 > "$backup/arranque-fallido.log" 2>&1 || true
    if (( override_existed )); then
      sudo install -m 644 -- "$backup/override-anterior.conf" "$override"
    else
      sudo rm -f -- "$override"
    fi
    sudo systemctl daemon-reload
    if sudo systemctl restart "$service"; then
      "$venv/bin/python" "$source_dir/deploy/esperar_servicio.py" "$public_url" --timeout 180 || {
        echo 'No se pudo confirmar la disponibilidad de la versión anterior. Revisa el servicio.';
      }
    else
      echo 'No se pudo reiniciar la versión anterior. Revisa el servicio.'
    fi
  fi
  if (( panel_touched )); then
    sudo install -m 644 -- "$backup/index.html" "$panel/index.html"
  fi
  echo "Los respaldos están en: $backup. La base de datos NO se restauró ni se borró."
  exit "$status"
}
trap 'rollback $?' ERR
trap 'rollback 130' INT
trap 'rollback 143' TERM

printf '[Service]\nWorkingDirectory=%s/backend\nExecStart=\nExecStart=%s/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --proxy-headers --forwarded-allow-ips=127.0.0.1\n' \
  "$release" "$venv" > "$backup/servicio-nuevo.conf"
sudo install -d -m 755 -- /etc/systemd/system/hersite-backend.service.d
activated=1
sudo install -m 644 -- "$backup/servicio-nuevo.conf" "$override"
sudo systemctl daemon-reload
[[ $(systemctl show --value -p WorkingDirectory "$service") == "$release/backend" ]] || {
  echo 'Otra configuración del servicio impide activar esta versión.'; false;
}
sudo systemctl restart "$service"
sudo systemctl is-active --quiet "$service"
echo 'Esperando la disponibilidad del backend y su versión (hasta 180 segundos)…'
"$venv/bin/python" "$source_dir/deploy/esperar_servicio.py" "$public_url" --version 1.1.0 --timeout 180

# Activa el HTML al final; conserva los assets anteriores para facilitar la vuelta atrás.
panel_touched=1
while IFS= read -r -d '' file; do
  relative=${file#"$release/dashboard-medico/dist/"}
  sudo install -D -m 644 -- "$file" "$panel/$relative"
done < <(find "$release/dashboard-medico/dist" -type f ! -name index.html -print0)
sudo install -m 644 -- "$release/dashboard-medico/dist/index.html" "$panel/index.nuvia-1.1.0.tmp"
sudo mv -f -- "$panel/index.nuvia-1.1.0.tmp" "$panel/index.html"
trap - ERR INT TERM
echo 'NUVIA 1.1.0 ACTIVADA: backend y panel actualizados.'
echo "Versión instalada en: $release"
echo "Respaldos privados en: $backup"
