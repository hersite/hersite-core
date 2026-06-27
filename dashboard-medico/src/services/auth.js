const SESSION_KEY = 'hersite_web_session';

export function iniciarSesionWeb({ dni }) {
  const session = {
    dni,
    nombre: 'Dra. M. Quispe',
    rol: 'Médico encargado',
    iniciadoEn: new Date().toISOString(),
  };

  localStorage.setItem(SESSION_KEY, JSON.stringify(session));

  return session;
}

export function obtenerSesionWeb() {
  const raw = localStorage.getItem(SESSION_KEY);

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw);
  } catch {
    localStorage.removeItem(SESSION_KEY);
    return null;
  }
}

export function existeSesionWeb() {
  return obtenerSesionWeb() !== null;
}

export function cerrarSesionWeb() {
  localStorage.removeItem(SESSION_KEY);
}