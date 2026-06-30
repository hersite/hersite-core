const SESSION_KEY = 'hersite_web_session';
const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000';

// 8 horas de sesión web.
const SESSION_MAX_AGE_MS = 8 * 60 * 60 * 1000;

export async function iniciarSesionWeb({ dni, pin }) {
  try {
    const respuesta = await fetch(`${API_BASE_URL}/api/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ dni, pin }),
    });

    if (!respuesta.ok) {
      let mensaje = 'No se pudo iniciar sesión.';

      try {
        const errorData = await respuesta.json();
        mensaje = errorData.detail || errorData.message || mensaje;
      } catch (_) {
        const texto = await respuesta.text();
        if (texto) mensaje = texto;
      }

      throw new Error(mensaje);
    }

    const data = await respuesta.json();

    const session = {
      dni: data.dni,
      nombre: data.nombre,
      rol: data.rol,
      iniciadoEn: new Date().toISOString(),
    };

    localStorage.setItem(SESSION_KEY, JSON.stringify(session));

    // Compatibilidad con pantallas que leen rol directamente.
    localStorage.setItem('rol', session.rol);
    localStorage.setItem('role', session.rol);

    return session;
  } catch (error) {
    console.error("Falló el login:", error); // <-- Que agregue esta línea
    throw error; 
    }
}

export function obtenerSesionWeb() {
  const raw = localStorage.getItem(SESSION_KEY);

  if (!raw) {
    return null;
  }

  try {
    const session = JSON.parse(raw);

    if (!session?.dni || !session?.rol || !session?.iniciadoEn) {
      cerrarSesionWeb();
      return null;
    }

    const iniciadoEn = new Date(session.iniciadoEn).getTime();

    if (Number.isNaN(iniciadoEn)) {
      cerrarSesionWeb();
      return null;
    }

    const sesionExpirada = Date.now() - iniciadoEn > SESSION_MAX_AGE_MS;

    if (sesionExpirada) {
      cerrarSesionWeb();
      return null;
    }

    return session;
  } catch {
    cerrarSesionWeb();
    return null;
  }
}

export function existeSesionWeb() {
  return obtenerSesionWeb() !== null;
}

export function obtenerRolWeb() {
  return obtenerSesionWeb()?.rol || null;
}

export function esAdminWeb() {
  return obtenerRolWeb() === 'admin';
}

export function cerrarSesionWeb() {
  localStorage.removeItem(SESSION_KEY);
  localStorage.removeItem('rol');
  localStorage.removeItem('role');
}