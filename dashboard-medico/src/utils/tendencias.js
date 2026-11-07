const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

// Años completos: conserva el histórico e incluye también el año actual.
export function completarMeses(filas, anioActual = Number(new Intl.DateTimeFormat('es-PE', {
  year: 'numeric', timeZone: 'America/Lima',
}).format(new Date()))) {
  const porMes = new Map(filas.map((fila) => [fila.key, fila]));
  const anios = filas.filter((fila) => /^\d{4}-(0[1-9]|1[0-2])$/.test(fila.key))
    .map((fila) => Number(fila.key.slice(0, 4)));
  const resultado = [];
  for (let anio = Math.min(anioActual, ...anios); anio <= Math.max(anioActual, ...anios); anio++) {
    for (let mes = 1; mes <= 12; mes++) {
      const key = `${anio}-${String(mes).padStart(2, '0')}`;
      resultado.push(porMes.get(key) ?? {
        key, mes: `${meses[mes - 1]} ${anio}`, bajo: 0, medio: 0, alto: 0, total: 0,
      });
    }
  }
  // No ocultar evaluaciones antiguas cuya fecha no se pudo interpretar.
  if (porMes.has('sin-fecha')) resultado.push(porMes.get('sin-fecha'));
  return resultado;
}
