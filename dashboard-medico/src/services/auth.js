const SESSION_KEY = 'hersite_web_session';

export async function iniciarSesionWeb({ dni, pin }) {
  try {
    // 1. Hacemos la petición real a FastAPI
    const respuesta = await fetch('http://127.0.0.1:8000/api/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ dni, pin }),
    });

    // 2. Si FastAPI devuelve un error (ej. PIN incorrecto, DNI no existe)
    if (!respuesta.ok) {
      const errorData = await respuesta.json();
      throw new Error(errorData.detail || 'Error de conexión al iniciar sesión');
    }

    // 3. Obtenemos la respuesta exitosa (viene con el rol y el nombre)
    const data = await respuesta.json();

    // 4. Creamos la sesión usando los datos REALES de la base de datos
    const session = {
      dni: data.dni,
      nombre: data.nombre,
      rol: data.rol, // ¡Aquí viene 'admin' o 'medico'!
      iniciadoEn: new Date().toISOString(),
    };

    localStorage.setItem(SESSION_KEY, JSON.stringify(session));

    return session;
  } catch (error) {
    throw error; // Lanzamos el error para que Login.jsx lo atrape y lo muestre
  }
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