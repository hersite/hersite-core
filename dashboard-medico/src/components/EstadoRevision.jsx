import { useState } from 'react';
import { api } from '../services/api';

function fechaTexto(fecha) {
  if (!fecha) return 'Fecha no disponible';
  const valor = new Date(fecha);
  return Number.isNaN(valor.getTime()) ? 'Fecha no disponible' : valor.toLocaleString('es-PE');
}

function recepcionTexto(fecha) {
  if (!fecha || !Number.isFinite(Date.parse(fecha))) return 'Fecha de recepción no registrada';
  const minutos = Math.max(0, Math.floor((Date.now() - Date.parse(fecha)) / 60000));
  if (minutos < 1) return 'Recibida hace unos segundos';
  if (minutos < 60) return `Recibida hace ${minutos} min`;
  if (minutos < 1440) return `Recibida hace ${Math.floor(minutos / 60)} h`;
  return `Recibida el ${fechaTexto(fecha)}`;
}

export default function EstadoRevision({ evaluacion, onRevisada }) {
  const [guardando, setGuardando] = useState(false);
  const [error, setError] = useState(null);
  const revisada = evaluacion.estado_revision === 'revisada';

  async function confirmar() {
    if (guardando || !window.confirm('¿Confirmas que revisaste esta evaluación? Esto no registra una atención ni cambia su nivel de riesgo.')) return;
    setGuardando(true);
    setError(null);
    try {
      const resultado = await api.marcarEvaluacionRevisada(evaluacion.id);
      onRevisada(evaluacion.id, resultado);
      window.dispatchEvent(new Event('nuvia:revision-actualizada'));
    } catch (err) {
      setError(err.message || 'No se pudo guardar la revisión. Inténtalo otra vez.');
    } finally {
      setGuardando(false);
    }
  }

  return (
    <section aria-label="Estado de revisión" className="mt-3 rounded-xl border border-slate-200 bg-slate-50 p-3 text-left dark:border-slate-700 dark:bg-slate-800/50 sm:ml-auto sm:max-w-xs">
      <p className="text-[10px] font-bold uppercase tracking-wide text-slate-500 dark:text-slate-400">Estado de revisión</p>
      <p className={`mt-1 text-sm font-bold ${revisada ? 'text-verdeOscuro dark:text-green-400' : 'text-amber-700 dark:text-amber-400'}`}>
        {revisada ? 'Revisada' : 'Por revisar'}
      </p>
      <p className="mt-1 text-[11px] text-slate-600 dark:text-slate-300">{recepcionTexto(evaluacion.recibido_en)}</p>
      {revisada ? (
        <p className="mt-1 text-[11px] text-slate-600 dark:text-slate-300">
          {evaluacion.revisado_por} · {fechaTexto(evaluacion.revisado_en)}
        </p>
      ) : (
        <button type="button" disabled={guardando} onClick={confirmar} className="mt-2 rounded-lg bg-verdeOscuro px-3 py-2 text-xs font-bold text-white hover:bg-verdeApp disabled:opacity-50">
          {guardando ? 'Guardando…' : 'Marcar como revisada'}
        </button>
      )}
      <p className="mt-2 text-[10px] text-slate-500 dark:text-slate-400">La revisión no confirma atención ni cambia la prioridad de riesgo.</p>
      {error && <p role="alert" className="mt-2 text-xs text-red-700 dark:text-red-400">{error}</p>}
    </section>
  );
}
