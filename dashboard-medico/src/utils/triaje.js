function fechaEvaluacion(item) {
  const evaluacion = item.ultima_evaluacion;
  const fecha = Date.parse(evaluacion?.fecha_hora);
  if (Number.isFinite(fecha)) return fecha;
  const recepcion = Date.parse(evaluacion?.recibido_en);
  return Number.isFinite(recepcion) ? recepcion : -Infinity;
}

export function ordenarTriaje(items) {
  return items.filter((item) => item.gestante?.activo !== false).sort((a, b) => {
    const alto = (item) => ['Riesgo_Alto', 'ALTO'].includes(item.ultima_evaluacion?.nivel_riesgo);
    if (alto(a) !== alto(b)) return alto(a) ? -1 : 1;
    const fechaA = fechaEvaluacion(a);
    const fechaB = fechaEvaluacion(b);
    if (fechaA !== fechaB) return fechaA > fechaB ? -1 : 1;
    return (b.ultima_evaluacion?.id ?? 0) - (a.ultima_evaluacion?.id ?? 0)
      || (b.gestante?.id ?? 0) - (a.gestante?.id ?? 0);
  });
}
