#!/usr/bin/env bash
# Actualización de Nuvia en la VM conocida. No ejecutar como root.
set -Eeuo pipefail
umask 077

base=/home/jpierre1311
service=hersite-backend.service
panel=/var/www/hersite
override=/etc/systemd/system/hersite-backend.service.d/zzzz-nuvia-1.1.0.conf
public_url=https://nuvia-136-64-236-164.sslip.io
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)

[[ $(id -un) == jpierre1311 ]] || { echo 'Ejecuta esto como jpierre1311.'; exit 1; }
[[ -d "$source_dir/backend/app" && -f "$source_dir/dashboard-medico/package-lock.json" ]] || {
  echo 'Faltan archivos del repositorio. Descarga la versión completa con Git.'; exit 1;
}
case "$source_dir" in "$base"/*) ;; *) echo 'El repositorio debe estar dentro de /home/jpierre1311.'; exit 1;; esac
[[ "$source_dir" =~ ^[a-zA-Z0-9_./-]+$ ]] || { echo 'Usa una ruta sin espacios ni caracteres especiales.'; exit 1; }
sudo -v
sudo test ! -e "$override" || { echo 'Esta versión ya tiene un servicio configurado. No se sobrescribió.'; exit 1; }
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
    sudo rm -f -- "$override"
    sudo systemctl daemon-reload
    sudo systemctl restart "$service" || true
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
  "$release" "$venv" > "$release/servicio.conf"
sudo install -d -m 755 -- /etc/systemd/system/hersite-backend.service.d
activated=1
sudo install -m 644 -- "$release/servicio.conf" "$override"
sudo systemctl daemon-reload
sudo systemctl restart "$service"
sudo systemctl is-active --quiet "$service"
curl --fail --silent --show-error --retry 8 --retry-connrefused --retry-delay 1 --max-time 10 \
  "$public_url/health" > "$backup/health.json"
"$venv/bin/python" - "$public_url" <<'PY'
import json, sys, urllib.request
with urllib.request.urlopen(sys.argv[1] + '/api/version', timeout=15) as response:
    version = json.load(response)
assert version['version'] == '1.1.0', 'El proxy no apunta a la versión nueva.'
assert version['revision_evaluaciones'] is True
PY

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
