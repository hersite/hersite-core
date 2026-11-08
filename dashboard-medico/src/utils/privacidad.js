// Solo presentación: el DNI original se conserva para buscar y operar con la API.
export function enmascararDni(dni) {
  const valor = String(dni ?? '').trim();
  if (!valor) return '--';
  if (!/^\d{8}$/.test(valor)) return 'XXXXXXXX';
  return `${valor.slice(0, 2)}XXXXXX`;
}
