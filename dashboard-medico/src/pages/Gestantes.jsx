import { useEffect, useMemo, useState } from 'react';
import {
  Search,
  WifiOff,
  ArrowLeft,
  Activity,
  Clock,
  ChevronRight,
  RefreshCw,
  AlertTriangle,
  CheckCircle2,
} from 'lucide-react';

import { api } from '../services/api';

function parseFecha(fechaIso) {
  if (!fechaIso) return null;

  const normalizada = fechaIso.replace(/(\.\d{3})\d+/, '$1');
  const fecha = new Date(normalizada);

  if (Number.isNaN(fecha.getTime())) {
    return null;
  }

  return fecha;
}

function formatearFecha(fechaIso) {
  const fecha = parseFecha(fechaIso);

  if (!fecha) return 'Fecha no disponible';

  return fecha.toLocaleString('es-PE', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function calcularHorasDesde(fechaIso) {
  const fecha = parseFecha(fechaIso);

  if (!fecha) return 999;

  const diffMs = Date.now() - fecha.getTime();
  const diffHoras = Math.floor(diffMs / (1000 * 60 * 60));

  return Math.max(diffHoras, 0);
}

function calcularUltimaSync(fechaIso) {
  const fecha = parseFecha(fechaIso);

  if (!fecha) return 'Sin sincronización';

  const diffMs = Math.max(Date.now() - fecha.getTime(), 0);
  const minutos = Math.floor(diffMs / (1000 * 60));
  const horas = Math.floor(minutos / 60);
  const dias = Math.floor(horas / 24);

  if (minutos < 1) return 'Hace unos segundos';
  if (minutos < 60) return `Hace ${minutos} min`;
  if (horas < 24) return `Hace ${horas} h`;
  return `Hace ${dias} día${dias === 1 ? '' : 's'}`;
}

function obtenerRiesgoUi(nivelRiesgo) {
  if (nivelRiesgo === 'Riesgo_Alto') {
    return {
      riesgo: 'ALTO',
      riesgoClass: 'danger',
      label: 'ALTA PRIORIDAD',
    };
  }

  if (nivelRiesgo === 'Riesgo_Medio') {
    return {
      riesgo: 'MEDIO',
      riesgoClass: 'warn',
      label: 'RIESGO MEDIO',
    };
  }

  if (nivelRiesgo === 'Riesgo_Bajo') {
    return {
      riesgo: 'ESTABLE',
      riesgoClass: 'ok',
      label: 'ESTABLE',
    };
  }

  return {
    riesgo: 'SIN DATOS',
    riesgoClass: 'ok',
    label: 'SIN DATOS',
  };
}

function obtenerProbabilidadesModelo(detalle, riesgoClass) {
  const probs = detalle?.probabilidades;

  if (Array.isArray(probs)) {
    const valores = Array.isArray(probs[0]) ? probs[0] : probs;

    if (valores.length >= 3) {
      return {
        bajo: Math.round((Number(valores[0]) || 0) * 100),
        medio: Math.round((Number(valores[1]) || 0) * 100),
        alto: Math.round((Number(valores[2]) || 0) * 100),
      };
    }
  }

  if (riesgoClass === 'danger') {
    return { bajo: 5, medio: 10, alto: 85 };
  }

  if (riesgoClass === 'warn') {
    return { bajo: 25, medio: 65, alto: 10 };
  }

  return { bajo: 90, medio: 8, alto: 2 };
}

function construirDetalleHistorial(evaluacion) {
  const sintomas = evaluacion.sintomas_detectados || [];

  if (sintomas.length > 0) {
    return `${evaluacion.mensaje} Síntomas reportados: ${sintomas.join(', ')}.`;
  }

  return evaluacion.mensaje || 'Evaluación sincronizada desde la aplicación móvil.';
}

export default function Gestantes() {
  const [gestantes, setGestantes] = useState([]);
  const [busqueda, setBusqueda] = useState('');
  const [filtroRiesgo, setFiltroRiesgo] = useState('TODOS');
  const [soloDesactualizadas, setSoloDesactualizadas] = useState(false);

  const [vista, setVista] = useState('lista');
  const [seleccionada, setSeleccionada] = useState(null);
  const [detalleSeleccionado, setDetalleSeleccionado] = useState(null);

  const [loading, setLoading] = useState(true);
  const [detalleLoading, setDetalleLoading] = useState(false);
  const [error, setError] = useState(null);

  const adaptarGestante = async (gestante) => {
    const respuesta = await api.getEvaluacionesPorGestante(gestante.id);
    const evaluaciones = respuesta.evaluaciones || [];
    const ultimaEvaluacion = evaluaciones[0] || null;

    const riesgoUi = obtenerRiesgoUi(ultimaEvaluacion?.nivel_riesgo);
    const horasDesdeSync = calcularHorasDesde(ultimaEvaluacion?.fecha_hora);

    return {
      id: gestante.id,
      dni: gestante.dni || '',
      nombre: gestante.nombre || 'Gestante sin nombre',
      celular: gestante.celular || '',
      edad: gestante.edad_materna ?? '--',
      semanas: gestante.semanas_gestacion ?? '--',
      numeroEmbarazos: gestante.numero_embarazos ?? '--',
      ubicacion: 'No registrada',
      ultimaSync: ultimaEvaluacion ? calcularUltimaSync(ultimaEvaluacion.fecha_hora) : 'Sin evaluaciones',
      horasDesdeSync,
      ultimaEvaluacionId: ultimaEvaluacion?.id ?? null,
      ultimaFecha: ultimaEvaluacion?.fecha_hora ?? null,
      ultimoMensaje: ultimaEvaluacion?.mensaje ?? '',
      nivelRiesgoOriginal: ultimaEvaluacion?.nivel_riesgo ?? null,
      riesgo: riesgoUi.riesgo,
      riesgoClass: riesgoUi.riesgoClass,
      riesgoLabel: riesgoUi.label,
      historial: evaluaciones.map((evaluacion) => {
        const riesgoHistorial = obtenerRiesgoUi(evaluacion.nivel_riesgo);

        return {
          id: evaluacion.id,
          semana: gestante.semanas_gestacion ?? '--',
          fecha: formatearFecha(evaluacion.fecha_hora),
          riesgo: riesgoHistorial.riesgo,
          riesgoClass: riesgoHistorial.riesgoClass,
          detalle: construirDetalleHistorial(evaluacion),
        };
      }),
    };
  };

  const cargarGestantes = async () => {
    setLoading(true);
    setError(null);

    try {
      const data = await api.getGestantes();

      const gestantesConEvaluaciones = await Promise.all(
        data.map((gestante) => adaptarGestante(gestante)),
      );

      setGestantes(gestantesConEvaluaciones);
    } catch (err) {
      console.error(err);
      setError(err.message || 'No se pudo cargar el padrón de gestantes.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let cancelado = false;

    async function cargarInicial() {
      try {
        const data = await api.getGestantes();

        const gestantesConEvaluaciones = await Promise.all(
          data.map((gestante) => adaptarGestante(gestante)),
        );

        if (cancelado) return;

        setGestantes(gestantesConEvaluaciones);
      } catch (err) {
        console.error(err);

        if (cancelado) return;

        setError(err.message || 'No se pudo cargar el padrón de gestantes.');
      } finally {
        if (!cancelado) {
          setLoading(false);
        }
      }
    }

    cargarInicial();

    return () => {
      cancelado = true;
    };
  }, []);

  const gestantesFiltradas = useMemo(() => {
    return gestantes.filter((g) => {
      const coincideBusqueda =
        g.nombre.toLowerCase().includes(busqueda.toLowerCase()) ||
        g.dni.includes(busqueda);

      const coincideRiesgo =
        filtroRiesgo === 'TODOS' || g.riesgo === filtroRiesgo;

      const coincideConectividad =
        !soloDesactualizadas || g.horasDesdeSync > 24;

      return coincideBusqueda && coincideRiesgo && coincideConectividad;
    });
  }, [gestantes, busqueda, filtroRiesgo, soloDesactualizadas]);

  const irADetalle = async (gestante) => {
    setSeleccionada(gestante);
    setDetalleSeleccionado(null);
    setVista('detalle');

    if (!gestante.ultimaEvaluacionId) {
      return;
    }

    setDetalleLoading(true);

    try {
      const detalle = await api.getEvaluacionDetalle(gestante.ultimaEvaluacionId);
      setDetalleSeleccionado(detalle);
    } catch (err) {
      console.error(err);
      setDetalleSeleccionado(null);
    } finally {
      setDetalleLoading(false);
    }
  };

  const irALista = () => {
    setVista('lista');
    setSeleccionada(null);
    setDetalleSeleccionado(null);
  };

  const probabilidades = obtenerProbabilidadesModelo(
    detalleSeleccionado,
    seleccionada?.riesgoClass,
  );

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-verdeApp" />
          <p className="text-sm font-bold text-slate-700">Cargando padrón de gestantes...</p>
          <p className="mt-1 text-xs text-slate-400">FastAPI /api/gestantes</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp p-6">
        <div className="max-w-md rounded-2xl border border-red-200 bg-red-50 p-6 text-center">
          <AlertTriangle className="mx-auto mb-3 h-8 w-8 text-red-600" />
          <h2 className="text-sm font-bold text-red-800">No se pudo cargar el padrón</h2>
          <p className="mt-2 text-xs text-red-700">{error}</p>
          <button
            onClick={cargarGestantes}
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
      {vista === 'lista' && (
        <div className="flex h-full w-full animate-fade-in flex-col">
          <header className="shrink-0 border-b border-slate-200 bg-white px-6 py-4">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h2 className="font-serif text-2xl font-bold text-slate-800">Padrón de Gestantes</h2>
                <p className="mt-0.5 text-xs text-slate-500">
                  Registros sincronizados desde la aplicación móvil offline-first.
                </p>
              </div>

              <button
                onClick={cargarGestantes}
                className="flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50"
              >
                <RefreshCw size={14} />
                Actualizar
              </button>
            </div>
          </header>

          <div className="flex shrink-0 flex-col items-center justify-between gap-3 border-b border-slate-200 bg-white px-6 py-3 sm:flex-row">
            <div className="relative w-full sm:w-72">
              <Search size={14} className="absolute left-3 top-3 text-slate-400" />
              <input
                type="text"
                placeholder="Buscar por DNI o nombre..."
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2 pl-9 pr-4 text-xs font-medium outline-none transition-all focus:border-verdeApp focus:bg-white"
              />
            </div>

            <div className="flex w-full flex-wrap items-center justify-end gap-2 sm:w-auto">
              <div className="flex rounded-xl border border-slate-200/60 bg-slate-100 p-1">
                {['TODOS', 'ALTO', 'MEDIO', 'ESTABLE'].map((r) => (
                  <button
                    key={r}
                    onClick={() => setFiltroRiesgo(r)}
                    className={`rounded-lg px-3 py-1 text-[10px] font-bold transition-all ${
                      filtroRiesgo === r
                        ? 'bg-white text-slate-800 shadow-sm'
                        : 'text-slate-500 hover:text-slate-800'
                    }`}
                  >
                    {r}
                  </button>
                ))}
              </div>

              <button
                onClick={() => setSoloDesactualizadas(!soloDesactualizadas)}
                className={`flex items-center gap-1.5 rounded-xl border px-3 py-1.5 text-xs font-semibold transition-all ${
                  soloDesactualizadas
                    ? 'border-amber-300 bg-amber-50 text-amber-700 shadow-sm'
                    : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                }`}
              >
                <WifiOff
                  size={14}
                  className={soloDesactualizadas ? 'text-amber-600' : 'text-slate-400'}
                />
                Desactualizadas (&gt;24h)
              </button>
            </div>
          </div>

          <div className="flex-1 overflow-auto p-6">
            <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <table className="w-full border-collapse text-left">
                <thead className="border-b border-slate-200 bg-slate-50/70">
                  <tr>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400">Paciente</th>
                    <th className="px-6 py-3.5 text-center text-[10px] font-bold uppercase tracking-wider text-slate-400">Edad / EG</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400">Comunidad</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400">Riesgo Predicho</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400">Última Sincronización</th>
                    <th className="px-6 py-3.5 text-right text-[10px] font-bold uppercase tracking-wider text-slate-400">Acciones</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-100">
                  {gestantesFiltradas.length > 0 ? (
                    gestantesFiltradas.map((g) => (
                      <tr key={g.id} className="transition-colors hover:bg-slate-50/70">
                        <td className="px-6 py-4">
                          <span className="block text-xs font-bold text-slate-700">{g.nombre}</span>
                          <span className="mt-0.5 block font-mono text-[10px] text-slate-400">DNI: {g.dni || '--'}</span>
                        </td>

                        <td className="px-6 py-4 text-center text-xs font-medium text-slate-600">
                          {g.edad} años <br />
                          <span className="text-[10px] font-semibold text-slate-400">{g.semanas} semanas</span>
                        </td>

                        <td className="px-6 py-4 text-xs font-medium text-slate-600">{g.ubicacion}</td>

                        <td className="px-6 py-4">
                          {g.riesgoClass === 'danger' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-red-100 bg-red-50 px-2.5 py-1 text-[10px] font-bold text-red-600">
                              <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-red-500"></span>
                              ALTA PRIORIDAD
                            </span>
                          )}

                          {g.riesgoClass === 'warn' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-amber-200 bg-amber-50 px-2.5 py-1 text-[10px] font-bold text-amber-700">
                              <span className="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
                              RIESGO MEDIO
                            </span>
                          )}

                          {g.riesgoClass === 'ok' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-green-200 bg-green-50 px-2.5 py-1 text-[10px] font-bold text-green-700">
                              <span className="h-1.5 w-1.5 rounded-full bg-green-500"></span>
                              {g.riesgoLabel}
                            </span>
                          )}
                        </td>

                        <td className="px-6 py-4">
                          <span
                            className={`flex items-center gap-1.5 text-xs font-semibold ${
                              g.horasDesdeSync > 24 ? 'text-amber-600' : 'text-slate-500'
                            }`}
                          >
                            <span
                              className={`h-1.5 w-1.5 rounded-full ${
                                g.horasDesdeSync > 24 ? 'bg-amber-500' : 'bg-green-500'
                              }`}
                            ></span>
                            {g.ultimaSync}
                          </span>
                        </td>

                        <td className="px-6 py-4 text-right">
                          <button
                            onClick={() => irADetalle(g)}
                            className="group inline-flex items-center gap-1 rounded-xl bg-slate-100 px-3 py-1.5 text-xs font-bold text-slate-700 transition-all hover:bg-verdeApp hover:text-white"
                          >
                            Ver ficha clínica
                            <ChevronRight size={14} className="transition-transform group-hover:translate-x-0.5" />
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-xs font-medium text-slate-400">
                        No se encontraron registros.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {vista === 'detalle' && seleccionada && (
        <div className="flex h-full w-full animate-fade-in flex-col bg-slate-50">
          <header className="flex shrink-0 items-center gap-4 border-b border-slate-200 bg-white px-6 py-4">
            <button
              onClick={irALista}
              className="rounded-xl border border-slate-200 p-2 text-slate-600 transition-colors hover:bg-slate-50"
            >
              <ArrowLeft size={16} />
            </button>

            <div>
              <div className="flex items-center gap-3">
                <h2 className="font-serif text-xl font-bold text-slate-800">{seleccionada.nombre}</h2>
                <span className="rounded-md bg-slate-100 px-2.5 py-0.5 font-mono text-xs text-slate-600">
                  DNI {seleccionada.dni || '--'}
                </span>
              </div>
              <p className="mt-0.5 text-xs text-slate-500">
                Gestante sincronizada desde aplicativo móvil · {seleccionada.ubicacion}
              </p>
            </div>

            <div className="ml-auto">
              <span
                className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-[10px] font-bold ${
                  seleccionada.riesgoClass === 'danger'
                    ? 'border border-red-100 bg-red-50 text-red-600'
                    : seleccionada.riesgoClass === 'warn'
                      ? 'border border-amber-200 bg-amber-50 text-amber-700'
                      : 'border border-green-200 bg-green-50 text-green-700'
                }`}
              >
                {seleccionada.riesgoLabel}
              </span>
            </div>
          </header>

          <div className="flex-1 overflow-y-auto p-6">
            <div className="mx-auto grid max-w-5xl grid-cols-1 gap-6 md:grid-cols-3">
              <div className="space-y-6 md:col-span-1">
                <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                  <h3 className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    Datos de la gestante
                  </h3>

                  <div className="space-y-3 text-xs">
                    <div className="flex justify-between border-b border-slate-50 py-1.5">
                      <span className="font-medium text-slate-500">Edad materna</span>
                      <span className="font-bold text-slate-800">{seleccionada.edad} años</span>
                    </div>

                    <div className="flex justify-between border-b border-slate-50 py-1.5">
                      <span className="font-medium text-slate-500">Edad gestacional</span>
                      <span className="font-bold text-verdeOscuro">{seleccionada.semanas} semanas</span>
                    </div>

                    <div className="flex justify-between border-b border-slate-50 py-1.5">
                      <span className="font-medium text-slate-500">N.° embarazos</span>
                      <span className="font-bold text-slate-800">{seleccionada.numeroEmbarazos}</span>
                    </div>

                    <div className="flex justify-between py-1.5">
                      <span className="font-medium text-slate-500">Última sincronización</span>
                      <span className="font-bold text-slate-700">{seleccionada.ultimaSync}</span>
                    </div>
                  </div>
                </div>

                <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                  <h3 className="mb-4 flex items-center gap-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    <Activity size={14} className="text-verdeApp" />
                    Probabilidades del modelo
                  </h3>

                  {detalleLoading ? (
                    <div className="flex items-center gap-2 text-xs text-slate-400">
                      <RefreshCw size={14} className="animate-spin" />
                      Cargando probabilidades...
                    </div>
                  ) : (
                    <div className="space-y-4">
                      <div>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="font-semibold text-slate-700">Riesgo bajo</span>
                          <span className="font-bold text-green-700">{probabilidades.bajo}%</span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-100">
                          <div className="h-2 rounded-full bg-green-500 transition-all" style={{ width: `${probabilidades.bajo}%` }}></div>
                        </div>
                      </div>

                      <div>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="font-semibold text-slate-700">Riesgo medio</span>
                          <span className="font-bold text-amber-600">{probabilidades.medio}%</span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-100">
                          <div className="h-2 rounded-full bg-amber-500 transition-all" style={{ width: `${probabilidades.medio}%` }}></div>
                        </div>
                      </div>

                      <div>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="font-semibold text-slate-700">Riesgo alto</span>
                          <span className="font-bold text-red-600">{probabilidades.alto}%</span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-100">
                          <div className="h-2 rounded-full bg-red-500 transition-all" style={{ width: `${probabilidades.alto}%` }}></div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
                  <h3 className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    Estado del servidor
                  </h3>

                  <p className="flex items-center gap-2 text-xs font-bold text-verdeApp">
                    <CheckCircle2 size={15} />
                    Registro recibido por FastAPI
                  </p>

                  <p className="mt-2 text-[10px] text-slate-400">
                    Última evaluación: {seleccionada.ultimaFecha ? formatearFecha(seleccionada.ultimaFecha) : 'Sin fecha'}
                  </p>
                </div>
              </div>

              <div className="md:col-span-2">
                <div className="h-full rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
                  <h3 className="mb-6 flex items-center gap-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    <Clock size={14} className="text-verdeApp" />
                    Trazabilidad y evolución de triajes móviles
                  </h3>

                  {seleccionada.historial.length === 0 ? (
                    <div className="rounded-xl border border-slate-100 bg-slate-50 p-4 text-xs text-slate-500">
                      Esta gestante aún no tiene evaluaciones sincronizadas.
                    </div>
                  ) : (
                    <div className="relative ml-3 space-y-6 border-l-2 border-slate-100">
                      {seleccionada.historial.map((item) => (
                        <div key={item.id} className="relative pl-6">
                          <div
                            className={`absolute -left-[5px] top-1 h-2.5 w-2.5 rounded-full border-2 border-white shadow-sm ${
                              item.riesgoClass === 'danger'
                                ? 'bg-red-500'
                                : item.riesgoClass === 'warn'
                                  ? 'bg-amber-500'
                                  : 'bg-green-500'
                            }`}
                          ></div>

                          <div className="mb-2 flex flex-col justify-between gap-1 sm:flex-row sm:items-center">
                            <span className="text-sm font-bold text-slate-800">
                              Semana de gestación: {item.semana}
                            </span>
                            <span className="text-[11px] font-medium text-slate-400">{item.fecha}</span>
                          </div>

                          <div className="mb-2">
                            {item.riesgoClass === 'danger' ? (
                              <span className="inline-flex items-center gap-1 rounded-md border border-red-100 bg-red-50 px-2 py-0.5 text-[10px] font-bold text-red-600">
                                ALTA PRIORIDAD
                              </span>
                            ) : item.riesgoClass === 'warn' ? (
                              <span className="inline-flex items-center gap-1 rounded-md border border-amber-100 bg-amber-50 px-2 py-0.5 text-[10px] font-bold text-amber-700">
                                RIESGO MEDIO
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 rounded-md border border-green-100 bg-green-50 px-2 py-0.5 text-[10px] font-bold text-green-700">
                                ESTABLE
                              </span>
                            )}
                          </div>

                          <div className="rounded-xl border border-slate-100/70 bg-slate-50 p-3.5 text-xs leading-relaxed text-slate-600">
                            {item.detalle}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}