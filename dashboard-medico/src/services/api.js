import { obtenerCsrf, olvidarSesionWeb } from './auth';
import { apiUrl } from './api_config';

async function requestJson(path, options = {}) {
  const url = apiUrl(path);

  const response = await fetch(url, {
    ...options,
    credentials: 'include',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': obtenerCsrf(),
      ...(options.headers || {}),
    },
  });

  if (!response.ok) {
    if (response.status === 401) {
      olvidarSesionWeb();
      window.location.assign('/');
    }
    const data = await response.json().catch(() => ({}));
    throw new Error(typeof data.detail === 'string' ? data.detail : `Error HTTP ${response.status}`);
  }

  return response.json();
}

export const api = {
  crearVinculacion(id) {
    return requestJson(`/api/gestantes/${id}/vinculacion`, { method: 'POST' });
  },
  asignarProfesional(id, dni) {
    return requestJson(`/api/gestantes/${id}/acceso/${dni}`, { method: 'PUT' });
  },
  retirarProfesional(id, dni) {
    return requestJson(`/api/gestantes/${id}/acceso/${dni}`, { method: 'DELETE' });
  },
  getHealth() {
    return requestJson('/health');
  },

  getDashboardResumen() {
    return requestJson('/api/dashboard/resumen');
  },

  getTendenciasResumen() {
    return requestJson('/api/tendencias/resumen');
  },

  getSistemaEstado() {
    return requestJson('/api/sistema/estado');
  },

  getUltimasEvaluaciones(limit = 10) {
    return requestJson(`/api/evaluaciones/ultimas?limit=${limit}`);
  },

  getEvaluacionDetalle(id) {
    return requestJson(`/api/evaluaciones/${id}`);
  },

  getGestantes() {
    return requestJson('/api/gestantes');
  },

  getEvaluacionesPorGestante(gestanteId) {
    return requestJson(`/api/gestantes/${gestanteId}/evaluaciones`);
  },

  // ==============================================================
  // NUEVA FUNCIÓN: DAR DE ALTA (Soft Delete)
  // ==============================================================
  darDeAltaGestante(id) {
    return requestJson(`/api/gestantes/${id}/alta`, {
      method: 'PUT',
    });
  },
};
