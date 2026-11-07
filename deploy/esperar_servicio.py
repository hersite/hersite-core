"""Comprueba disponibilidad HTTP real, sin modificar el servicio ni la base de datos."""
import argparse
import json
import time
from urllib.error import URLError
from urllib.request import Request, urlopen


def leer_json(url, timeout):
    request = Request(url, headers={"Accept": "application/json", "Cache-Control": "no-cache"})
    with urlopen(request, timeout=timeout) as response:
        return json.load(response)


def esperar_servicio(base_url, version=None, max_wait=180, *, fetch=leer_json,
                     clock=time.monotonic, pause=time.sleep, report=print):
    if max_wait <= 0:
        raise ValueError("La espera debe ser mayor que cero.")
    deadline = clock() + max_wait
    attempt = 0
    while clock() < deadline:
        attempt += 1
        try:
            health = fetch(base_url.rstrip('/') + '/health', min(5, deadline - clock()))
            if not isinstance(health, dict) or health.get('status') != 'ok' or health.get('service') != 'riesgo-materno-api':
                raise ValueError('Respuesta de salud inesperada.')
            if version is not None:
                remaining = deadline - clock()
                if remaining <= 0:
                    break
                data = fetch(base_url.rstrip('/') + '/api/version', min(5, remaining))
                if not isinstance(data, dict) or data.get('version') != version or data.get('revision_evaluaciones') is not True:
                    raise ValueError('La versión nueva todavía no está disponible.')
            report('Servicio disponible' + (f' · versión {version}' if version else ''))
            return
        except (URLError, OSError, ValueError):
            # Durante el arranque son normales los 502/503 o la conexión rechazada.
            # No imprimir cuerpos HTTP, credenciales ni registros clínicos.
            if attempt == 1 or attempt % 5 == 0:
                report(f'Esperando a que el servicio esté listo… intento {attempt}')
        remaining = deadline - clock()
        if remaining > 0:
            pause(min(2, remaining))
    raise TimeoutError(f'El servicio no estuvo disponible en {max_wait} segundos.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('url')
    parser.add_argument('--version')
    parser.add_argument('--timeout', type=int, default=180)
    args = parser.parse_args()
    try:
        esperar_servicio(args.url, args.version, args.timeout)
    except (TimeoutError, ValueError) as error:
        raise SystemExit(str(error))
