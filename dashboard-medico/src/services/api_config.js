export function apiUrl(path) {
  const local = ['localhost', '127.0.0.1', '[::1]'].includes(window.location.hostname);
  const configured = import.meta.env.VITE_API_BASE_URL ||
    (local ? `${window.location.protocol}//${window.location.hostname}:8000` : window.location.origin);
  const base = new URL(configured);
  const localApi = ['localhost', '127.0.0.1', '[::1]'].includes(base.hostname);
  if (base.protocol !== 'https:' && !(local && localApi && base.protocol === 'http:')) {
    throw new Error('La conexión con el servidor debe utilizar HTTPS.');
  }
  return `${base.href.replace(/\/$/, '')}${path}`;
}
