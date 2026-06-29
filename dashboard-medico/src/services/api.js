const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000';

async function requestJson(path, options = {}) {
  const url = `${API_BASE_URL}${path}`;

  const response = await fetch(url, {
    headers: {
      Accept: 'application/json',
      ...(options.headers || {}),
    },
    ...options,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Error HTTP ${response.status}: ${errorText}`);
  }

  return response.json();
}

export const api = {
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