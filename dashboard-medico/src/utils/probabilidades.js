export function probabilidadesModelo(raw) {
  const valores = Array.isArray(raw?.[0]) ? raw[0] : raw;
  if (!Array.isArray(valores) || valores.length !== 3 ||
      valores.some((n) => typeof n !== 'number' || !Number.isFinite(n) || n < 0 || n > 1) ||
      Math.abs(valores.reduce((sum, n) => sum + n, 0) - 1) > 0.02) return null;
  return valores;
}
