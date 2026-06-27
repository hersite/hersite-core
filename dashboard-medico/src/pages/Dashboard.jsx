import { useEffect, useMemo, useState } from 'react';
import { AlertTriangle, Search, CheckCircle2, RefreshCw } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { api } from '../services/api';

export default function Dashboard() {
  const [resumen, setResumen] = useState(null);
  const [evaluaciones, setEvaluaciones] = useState([]);
  const [selectedEval, setSelectedEval] = useState(null);
  const [selectedDetail, setSelectedDetail] = useState(null);
  const [busqueda, setBusqueda] = useState('');
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState(null);

  const getRiskColors = (riskClass) => {
    if (riskClass === 'danger') return { bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200', bar: 'bg-red-500' };
    if (riskClass === 'warn') return { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', bar: 'bg-amber-500' };
    return { bg: 'bg-green-50', text: 'text-green-700', border: 'border-green-200', bar: 'bg-green-500' };
  };

  const getRiskClass = (nivelRiesgo) => {
    if (nivelRiesgo === 'Riesgo_Alto') return 'danger';
    if (nivelRiesgo === 'Riesgo_Medio') return 'warn';
    return 'ok';
  };

  const getInitials = (nombre) => {
    if (!nombre) return 'G';
    return nombre
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((parte) => parte[0]?.toUpperCase())
      .join('');
  };

  const formatFecha = (fechaIso) => {
    if (!fechaIso) return 'Fecha no disponible';

    try {
      const fecha = new Date(fechaIso);
      return fecha.toLocaleString('es-PE', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
      });
    } catch {
      return fechaIso;
    }
  };

  const getProbabilidad = (detalle) => {
    const nivel = detalle?.nivel_riesgo || selectedEval?.nivel_riesgo;
    const probs = detalle?.probabilidades;

    if (Array.isArray(probs) && Array.isArray(probs[0])) {
      const valores = probs[0];
      const index = nivel === 'Riesgo_Alto' ? 2 : nivel === 'Riesgo_Medio' ? 1 : 0;
      const prob = valores[index];

      if (typeof prob === 'number') {
        return Math.round(prob * 100);
      }
    }

    if (nivel === 'Riesgo_Alto') return 90;
    if (nivel === 'Riesgo_Medio') return 55;
    return 10;
  };

  const getPresion = (detalle, campo) => {
    const value = detalle?.form_data?.[campo];
    return value ?? '--';
  };

  const chartData = useMemo(() => {
    const form = selectedDetail?.form_data || {};
    const basalSys = form.Presion_Basal_Sistolica || 110;
    const basalDia = form.Presion_Basal_Diastolica || 70;
    const actualSys = form.Presion_Sistolica || basalSys;
    const actualDia = form.Presion_Diastolica || basalDia;

    return [
      { day: 'Basal', sys: basalSys, dia: basalDia },
      { day: 'Actual', sys: actualSys, dia: actualDia },
    ];
  }, [selectedDetail]);

  const cargarDetalle = async (evaluacion) => {
    if (!evaluacion?.id) return;

    setSelectedEval(evaluacion);
    setDetailLoading(true);

    try {
      const detalle = await api.getEvaluacionDetalle(evaluacion.id);
      setSelectedDetail(detalle);
    } catch (err) {
      console.error(err);
      setSelectedDetail(null);
    } finally {
      setDetailLoading(false);
    }
  };

  const cargarDashboard = async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await api.getDashboardResumen();
      const ultimas = data.ultimas_evaluaciones || [];

      setResumen(data);
      setEvaluaciones(ultimas);

      if (ultimas.length > 0) {
        await cargarDetalle(ultimas[0]);
      } else {
        setSelectedEval(null);
        setSelectedDetail(null);
      }
    } catch (err) {
      console.error(err);
      setError(err.message || 'No se pudo conectar con el backend.');
    } finally {
      setLoading(false);
    }
  };
  

  useEffect(() => {
    let cancelado = false;

    async function cargarDashboardInicial() {
      try {
        const data = await api.getDashboardResumen();

        if (cancelado) return;

        const ultimas = data.ultimas_evaluaciones || [];

        let detalleInicial = null;

        if (ultimas.length > 0) {
          try {
            detalleInicial = await api.getEvaluacionDetalle(ultimas[0].id);
          } catch (err) {
            console.error(err);
          }
        }

        if (cancelado) return;

        setResumen(data);
        setEvaluaciones(ultimas);
        setSelectedEval(ultimas.length > 0 ? ultimas[0] : null);
        setSelectedDetail(detalleInicial);
        setError(null);
      } catch (err) {
        if (cancelado) return;

        console.error(err);
        setError(err.message || 'No se pudo conectar con el backend.');
      } finally {
        if (!cancelado) {
          setLoading(false);
        }
      }
    }

    cargarDashboardInicial();

    return () => {
      cancelado = true;
    };
  }, []);

  const evaluacionesFiltradas = evaluaciones.filter((item) => {
    const texto = `${item.gestante?.nombre || ''} ${item.gestante?.dni || ''} ${item.nivel_riesgo_legible || ''}`.toLowerCase();
    return texto.includes(busqueda.toLowerCase());
  });

  const active = selectedDetail || selectedEval;
  const gestante = active?.gestante;
  const riskClass = getRiskClass(active?.nivel_riesgo);
  const colors = getRiskColors(riskClass);
  const probabilidad = getProbabilidad(selectedDetail);

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-verdeApp" />
          <p className="text-sm font-bold text-slate-700">Cargando datos del servidor...</p>
          <p className="mt-1 text-xs text-slate-400">FastAPI /api/dashboard/resumen</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp p-6">
        <div className="max-w-md rounded-2xl border border-red-200 bg-red-50 p-6 text-center">
          <AlertTriangle className="mx-auto mb-3 h-8 w-8 text-red-600" />
          <h2 className="text-sm font-bold text-red-800">No se pudo cargar el dashboard</h2>
          <p className="mt-2 text-xs text-red-700">{error}</p>
          <button
            onClick={cargarDashboard}
            className="mt-4 rounded-xl bg-red-600 px-4 py-2 text-xs font-bold text-white hover:bg-red-700"
          >
            Reintentar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-full flex-col bg-fondoApp">
      <header className="flex shrink-0 items-center justify-between border-b border-slate-200 bg-white px-6 py-3">
        <h2 className="text-sm font-bold text-slate-800">Panel de triaje — Datos sincronizados desde Flutter</h2>
        <div className="flex items-center gap-3">
          <button
            onClick={cargarDashboard}
            className="flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-3 py-1 text-[11px] font-semibold text-slate-600 hover:bg-slate-50"
          >
            <RefreshCw size={13} /> Actualizar
          </button>
          <div className="flex items-center gap-1.5 rounded-full border border-green-200 bg-green-50 px-3 py-1 text-[11px] font-semibold text-verdeOscuro">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-verdeApp"></span> API conectada
          </div>
        </div>
      </header>

      <div className="grid shrink-0 grid-cols-3 border-b border-slate-200 bg-white">
        <div className="border-r border-slate-100 px-6 py-3 text-center">
          <div className="text-2xl font-bold leading-none text-red-500">{resumen?.riesgos?.alto ?? 0}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400">Riesgo Alto</div>
        </div>
        <div className="border-r border-slate-100 px-6 py-3 text-center">
          <div className="text-2xl font-bold leading-none text-amber-500">{resumen?.riesgos?.medio ?? 0}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400">Riesgo Medio</div>
        </div>
        <div className="px-6 py-3 text-center">
          <div className="text-2xl font-bold leading-none text-verdeApp">{resumen?.riesgos?.bajo ?? 0}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400">Estables</div>
        </div>
      </div>

      <div className="flex flex-1 overflow-hidden">
        <div className="flex w-72 shrink-0 flex-col border-r border-slate-200 bg-white">
          <div className="border-b border-slate-100 px-3 py-4">
            <div className="relative">
              <Search size={14} className="absolute left-2.5 top-2.5 text-slate-400" />
              <input
                type="text"
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                placeholder="Buscar paciente..."
                className="w-full rounded-lg border border-slate-200 py-1.5 pl-8 pr-3 text-xs outline-none focus:border-verdeApp"
              />
            </div>
          </div>

          <div className="flex-1 overflow-y-auto">
            {evaluacionesFiltradas.length === 0 ? (
              <div className="p-4 text-center text-xs text-slate-400">No hay evaluaciones sincronizadas.</div>
            ) : (
              evaluacionesFiltradas.map((item) => {
                const itemRiskClass = getRiskClass(item.nivel_riesgo);
                const itemColors = getRiskColors(itemRiskClass);
                const isActive = selectedEval?.id === item.id;
                const nombre = item.gestante?.nombre || 'Gestante sin nombre';

                return (
                  <button
                    key={item.id}
                    onClick={() => cargarDetalle(item)}
                    className={`flex w-full cursor-pointer items-center gap-3 border-b border-slate-50 p-3 text-left transition-colors ${
                      isActive ? 'border-r-2 border-r-verdeApp bg-green-50/50' : 'hover:bg-slate-50'
                    }`}
                  >
                    <div className={`h-10 w-1 shrink-0 rounded-full ${itemColors.bar}`}></div>
                    <div className="min-w-0 flex-1">
                      <p className={`truncate text-xs font-semibold ${isActive ? 'text-verdeOscuro' : 'text-slate-800'}`}>{nombre}</p>
                      <p className="mt-0.5 text-[10px] text-slate-400">
                        {item.gestante?.edad_materna ?? '--'} años · {item.gestante?.semanas_gestacion ?? '--'} sem · {item.nivel_riesgo_legible}
                      </p>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-6">
          {!active ? (
            <div className="rounded-xl border border-slate-200 bg-white p-6 text-center text-sm text-slate-500">
              Aún no hay evaluaciones para mostrar.
            </div>
          ) : (
            <>
              <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div className="flex items-center gap-4">
                  <div className="flex h-12 w-12 items-center justify-center rounded-full border-2 border-green-200 bg-green-50 font-bold text-verdeOscuro">
                    {getInitials(gestante?.nombre)}
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-slate-800">{gestante?.nombre || 'Gestante sin nombre'}</h3>
                    <p className="mt-1 text-xs text-slate-500">
                      DNI: {gestante?.dni || '--'} · {gestante?.edad_materna ?? '--'} años · {gestante?.semanas_gestacion ?? '--'} sem. gestación
                    </p>
                    <p className="mt-0.5 text-[10px] font-medium text-slate-400">Última evaluación: {formatFecha(active.fecha_hora)}</p>
                  </div>
                  <div className="ml-auto text-center">
                    <div className={`text-3xl font-black ${riskClass === 'danger' ? 'text-red-500' : riskClass === 'warn' ? 'text-amber-500' : 'text-verdeApp'}`}>
                      {probabilidad}%
                    </div>
                    <div className="mt-1 text-[10px] font-bold uppercase text-slate-400">Prob. clase</div>
                  </div>
                </div>

                <div className={`mt-5 flex items-center gap-3 rounded-lg border p-3 ${colors.bg} ${colors.border}`}>
                  <AlertTriangle className={colors.text} size={20} />
                  <div>
                    <p className={`text-xs font-bold ${colors.text}`}>{active.nivel_riesgo_legible || active.nivel_riesgo}</p>
                    <p className={`mt-0.5 text-[10px] opacity-90 ${colors.text}`}>{active.mensaje}</p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                  <div className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-400">Última lectura</div>
                  <div className="grid grid-cols-2 gap-2">
                    <div className="rounded-lg bg-slate-50 p-3">
                      <p className="text-[10px] uppercase text-slate-400">Sistólica</p>
                      <p className={`text-2xl font-bold ${riskClass === 'danger' ? 'text-red-500' : 'text-slate-800'}`}>
                        {detailLoading ? '...' : getPresion(selectedDetail, 'Presion_Sistolica')}
                        <span className="ml-1 text-xs font-normal text-slate-400">mmHg</span>
                      </p>
                    </div>
                    <div className="rounded-lg bg-slate-50 p-3">
                      <p className="text-[10px] uppercase text-slate-400">Diastólica</p>
                      <p className={`text-2xl font-bold ${riskClass === 'danger' ? 'text-red-500' : 'text-slate-800'}`}>
                        {detailLoading ? '...' : getPresion(selectedDetail, 'Presion_Diastolica')}
                        <span className="ml-1 text-xs font-normal text-slate-400">mmHg</span>
                      </p>
                    </div>
                  </div>
                </div>

                <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                  <div className="mb-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">Presión arterial registrada</div>
                  <div className="h-24 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={chartData}>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                        <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fontSize: 10, fill: '#94a3b8' }} />
                        <YAxis domain={['dataMin - 10', 'dataMax + 10']} hide />
                        <Tooltip contentStyle={{ fontSize: '10px', borderRadius: '8px' }} />
                        <Line type="monotone" dataKey="sys" stroke="#ef4444" strokeWidth={2} dot={{ r: 3 }} />
                        <Line type="monotone" dataKey="dia" stroke="#f59e0b" strokeWidth={2} dot={{ r: 3 }} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              </div>

              <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div className="flex items-start justify-between">
                  <div>
                    <div className="mb-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">Síntomas reportados</div>
                    <div className="flex flex-wrap gap-2">
                      {(active.sintomas_detectados || []).length > 0 ? (
                        active.sintomas_detectados.map((s) => (
                          <span key={s} className="rounded-md border border-red-100 bg-red-50 px-2.5 py-1 text-[11px] font-semibold text-red-700">
                            {s}
                          </span>
                        ))
                      ) : (
                        <span className="text-xs text-slate-400">Sin síntomas de alarma.</span>
                      )}
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="mb-1 text-[10px] font-bold uppercase tracking-wider text-slate-400">Estado del servidor</div>
                    <p className="flex items-center justify-end gap-1 text-xs font-semibold text-verdeApp">
                      <CheckCircle2 size={14} /> {active.estado_servidor || 'recibido'}
                    </p>
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}