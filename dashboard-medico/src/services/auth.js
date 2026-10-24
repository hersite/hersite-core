import { apiUrl } from './api_config';
let sesion = null;

// La credencial de acceso vive en una cookie HttpOnly; el rol no se toma del almacenamiento local.
export function obtenerSesionWeb() { return sesion; }
export function existeSesionWeb() { return sesion !== null; }
export function obtenerRolWeb() { return sesion?.rol || null; }
export function esAdminWeb() { return obtenerRolWeb() === 'admin'; }
export function obtenerCsrf() { return sesion?.csrf_token || ''; }
export function olvidarSesionWeb() {
  sesion = null;
  for (const key of ['hersite_web_session', 'rol', 'role']) localStorage.removeItem(key);
}

async function respuestaJson(response) {
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(typeof data.detail === 'string' ? data.detail : 'No se pudo completar la solicitud.');
  }
  return data;
}

export async function restaurarSesionWeb() {
  olvidarSesionWeb();
  const response = await fetch(apiUrl('/api/sesion'), { credentials: 'include' });
  if (response.status === 401) return null;
  sesion = await respuestaJson(response);
  return sesion;
}

export async function iniciarSesionWeb({ dni, pin }) {
  const response = await fetch(apiUrl('/api/login'), {
    method: 'POST', credentials: 'include',
    headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ dni, pin }),
  });
  sesion = await respuestaJson(response);
  return sesion;
}

export async function cerrarSesionWeb() {
  const response = await fetch(apiUrl('/api/logout'), {
    method: 'POST', credentials: 'include', headers: { 'X-CSRF-Token': obtenerCsrf() },
  });
  if (!response.ok && response.status !== 401) await respuestaJson(response);
  olvidarSesionWeb();
}

export async function cambiarPinWeb(actual, nueva) {
  const response = await fetch(apiUrl('/api/cambiar-pin'), {
    method: 'POST', credentials: 'include',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': obtenerCsrf() },
    body: JSON.stringify({ actual, nueva }),
  });
  sesion = await respuestaJson(response);
  return sesion;
}
