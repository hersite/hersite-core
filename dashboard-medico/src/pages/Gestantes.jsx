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
  UserCheck,
  Archive // <-- Importamos el ícono para el historial de altas
} from 'lucide-react';

import { api } from '../services/api';

function parseFecha(fechaIso) {
  if (!fechaIso) return null;
  const normalizada = fechaIso.replace(/(\.\d{3})\d+/, '$1');
  const fecha = new Date(normalizada);
  if (Number.isNaN(fecha.getTime())) return null;
  return fecha;
}

function formatearFecha(fechaIso) {
  const fecha = parseFecha(fechaIso);
  if (!fecha) return 'Fecha no disponible';
  return fecha.toLocaleString('es-PE', {
    day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit',
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
    return { riesgo: 'ALTO', riesgoClass: 'danger', label: 'ALTA PRIORIDAD' };
  }
  if (nivelRiesgo === 'Riesgo_Medio') {
    return { riesgo: 'MEDIO', riesgoClass: 'warn', label: 'RIESGO MEDIO' };
  }
  if (nivelRiesgo === 'Riesgo_Bajo') {
    return { riesgo: 'ESTABLE', riesgoClass: 'ok', label: 'ESTABLE' };
  }
  return { riesgo: 'SIN DATOS', riesgoClass: 'none', label: 'SIN EVALUACIONES' };
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
  if (riesgoClass === 'danger') return { bajo: 5, medio: 10, alto: 85 };
  if (riesgoClass === 'warn') return { bajo: 25, medio: 65, alto: 10 };
  if (riesgoClass === 'none') return { bajo: 0, medio: 0, alto: 0 };
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
  
  // NUEVO ESTADO: Filtro para visualizar pacientes dadas de alta (borrado lógico)
  const [mostrarDadasDeAlta, setMostrarDadasDeAlta] = useState(false);

  const [vista, setVista] = useState('lista');
  const [seleccionada, setSeleccionada] = useState(null);
  const [detalleSeleccionado, setDetalleSeleccionado] = useState(null);

  const [loading, setLoading] = useState(true);
  const [detalleLoading, setDetalleLoading] = useState(false);
  const [error, setError] = useState(null);
  
  const [procesandoAlta, setProcesandoAlta] = useState(false);

  const isAdmin = localStorage.getItem('rol') === 'admin' || localStorage.getItem('role') === 'admin';

  const adaptarGestante = async (gestante) => {
    const respuesta = await api.getEvaluacionesPorGestante(gestante.id);
    const evaluaciones = respuesta.evaluaciones || [];
    const ultimaEvaluacion = evaluaciones[0] || null;

    const riesgoUi = obtenerRiesgoUi(ultimaEvaluacion?.nivel_riesgo);
    const horasDesdeSync = calcularHorasDesde(ultimaEvaluacion?.fecha_hora);

    return {
      id: gestante.id,
      // Capturamos el estado activo de la base de datos (si no existe, asumimos true por compatibilidad)
      activo: gestante.activo !== false, 
      dni: gestante.dni || '',
      nombre: gestante.nombre || 'Gestante sin nombre',
      celular: gestante.celular || '',
      edad: gestante.edad_materna ?? '--',
      semanas: gestante.semanas_gestacion ?? '--',
      numeroEmbarazos: gestante.numero_embarazos ?? '--',
      tiempoCentroSalud: gestante.tiempo_centro_salud ?? 'No registrado',
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
        if (!cancelado) setLoading(false);
      }
    }
    cargarInicial();
    return () => { cancelado = true; };
  }, []);

  const gestantesFiltradas = useMemo(() => {
    return gestantes.filter((g) => {
      const coincideBusqueda =
        g.nombre.toLowerCase().includes(busqueda.toLowerCase()) || g.dni.includes(busqueda);
      const coincideRiesgo = filtroRiesgo === 'TODOS' || g.riesgo === filtroRiesgo;
      const coincideConectividad = !soloDesactualizadas || g.horasDesdeSync > 24;
      
      // LÓGICA DE FILTRO: Si mostrarDadasDeAlta es true, solo mostramos las inactivas (false). Si es false, mostramos las activas.
      const coincideEstado = mostrarDadasDeAlta ? g.activo === false : g.activo === true;

      return coincideBusqueda && coincideRiesgo && coincideConectividad && coincideEstado;
    });
  }, [gestantes, busqueda, filtroRiesgo, soloDesactualizadas, mostrarDadasDeAlta]);

  const irADetalle = async (gestante) => {
    setSeleccionada(gestante);
    setDetalleSeleccionado(null);
    setVista('detalle');
    if (!gestante.ultimaEvaluacionId) return;

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

  const handleDarDeAlta = async () => {
    const confirmacion = window.confirm(
      `¿Estás seguro de registrar el parto/dar de alta a ${seleccionada.nombre}? \n\nEsta acción quitará a la paciente del padrón activo de monitoreo.`
    );

    if (!confirmacion) return;

    setProcesandoAlta(true);
    try {
      await api.darDeAltaGestante(seleccionada.id);
      irALista();
      await cargarGestantes();
    } catch (err) {
      console.error("Error al dar de alta:", err);
      alert("Hubo un problema al intentar dar de alta a la paciente. Revisa tu conexión.");
    } finally {
      setProcesandoAlta(false);
    }
  };

  const probabilidades = obtenerProbabilidadesModelo(detalleSeleccionado, seleccionada?.riesgoClass);

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp dark:bg-slate-950 transition-colors duration-300">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-emerald-600 dark:text-emerald-500" />
          <p className="text-sm font-bold text-slate-700 dark:text-slate-300">Cargando padrón de gestantes...</p>
          <p className="mt-1 text-xs text-slate-400 dark:text-slate-500">FastAPI /api/gestantes</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp dark:bg-slate-950 p-6 transition-colors duration-300">
        <div className="max-w-md rounded-2xl border border-red-200 dark:border-red-800/60 bg-red-50 dark:bg-red-900/20 p-6 text-center shadow-sm">
          <AlertTriangle className="mx-auto mb-3 h-8 w-8 text-red-600 dark:text-red-500" />
          <h2 className="text-sm font-bold text-red-800 dark:text-red-400">No se pudo cargar el padrón</h2>
          <p className="mt-2 text-xs text-red-700 dark:text-red-300">{error}</p>
          <button
            onClick={cargarGestantes}
            className="mt-4 rounded-xl bg-red-600 px-4 py-2 text-xs font-bold text-white hover:bg-red-700 dark:hover:bg-red-500 transition-colors"
          >
            Reintentar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-full flex-col bg-fondoApp dark:bg-slate-950 transition-colors duration-300">
      
      {/* ============================================== */}
      {/* VISTA 1: LISTA (TABLA) */}
      {/* ============================================== */}
      {vista === 'lista' && (
        <div className="flex h-full w-full animate-fade-in flex-col">
          <header className="shrink-0 border-b border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 px-6 py-4 transition-colors duration-300">
            <div className="flex items-center justify-between gap-4 max-w-7xl mx-auto w-full">
              <div>
                <h2 className="font-serif text-2xl font-bold text-slate-800 dark:text-slate-100">
                  {mostrarDadasDeAlta ? 'Historial de Altas Médicas' : 'Padrón de Gestantes'}
                </h2>
                
              </div>
              <button
                onClick={cargarGestantes}
                className="flex items-center gap-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors"
              >
                <RefreshCw size={14} />
                Actualizar
              </button>
            </div>
          </header>

          <div className="flex shrink-0 flex-col items-center justify-between gap-3 border-b border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 px-6 py-3 sm:flex-row transition-colors duration-300">
            <div className="max-w-7xl mx-auto w-full flex flex-col sm:flex-row items-center justify-between gap-3">
              <div className="relative w-full sm:w-72">
                <Search size={14} className="absolute left-3 top-3 text-slate-400 dark:text-slate-500" />
                <input
                  type="text"
                  placeholder="Buscar por DNI o nombre..."
                  value={busqueda}
                  onChange={(e) => setBusqueda(e.target.value)}
                  className="w-full rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 py-2 pl-9 pr-4 text-xs font-medium text-slate-800 dark:text-slate-200 outline-none transition-all focus:border-emerald-600 dark:focus:border-emerald-500 placeholder:text-slate-400 dark:placeholder:text-slate-500"
                />
              </div>

              <div className="flex w-full flex-wrap items-center justify-end gap-2 sm:w-auto">
                <div className="flex rounded-xl border border-slate-200/60 dark:border-slate-700 bg-slate-100 dark:bg-slate-950 p-1">
                  {['TODOS', 'ALTO', 'MEDIO', 'ESTABLE', 'SIN DATOS'].map((r) => (
                    <button
                      key={r}
                      onClick={() => setFiltroRiesgo(r)}
                      className={`rounded-lg px-3 py-1 text-[10px] font-bold transition-all ${
                        filtroRiesgo === r
                          ? 'bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-100 shadow-sm'
                          : 'text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200'
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
                      ? 'border-amber-300 dark:border-amber-500/50 bg-amber-50 dark:bg-amber-500/10 text-amber-700 dark:text-amber-400 shadow-sm'
                      : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                  }`}
                >
                  <WifiOff size={14} className={soloDesactualizadas ? 'text-amber-600 dark:text-amber-500' : 'text-slate-400 dark:text-slate-500'} />
                  Desactualizadas
                </button>

                {/* NUEVO BOTÓN: Alternar entre Activas y Dadas de Alta */}
                <button
                  onClick={() => setMostrarDadasDeAlta(!mostrarDadasDeAlta)}
                  className={`flex items-center gap-1.5 rounded-xl border px-3 py-1.5 text-xs font-semibold transition-all ${
                    mostrarDadasDeAlta
                      ? 'border-indigo-300 dark:border-indigo-500/50 bg-indigo-50 dark:bg-indigo-500/10 text-indigo-700 dark:text-indigo-400 shadow-sm'
                      : 'border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700'
                  }`}
                >
                  <Archive size={14} className={mostrarDadasDeAlta ? 'text-indigo-600 dark:text-indigo-500' : 'text-slate-400 dark:text-slate-500'} />
                  {mostrarDadasDeAlta ? 'Viendo Historial' : 'Ver Altas'}
                </button>
              </div>
            </div>
          </div>

          <div className="flex-1 overflow-auto p-4 sm:p-6">
            <div className="max-w-7xl mx-auto overflow-x-auto rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 shadow-sm transition-colors duration-300">
              <table className="w-full min-w-[900px] border-collapse text-left">
                <thead className="border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/50">
                  <tr>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Paciente</th>
                    <th className="px-6 py-3.5 text-center text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Edad / EG</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Tiempo al E.S.</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Riesgo Predicho</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Última Sincronización</th>
                    <th className="px-6 py-3.5 text-right text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Acciones</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60">
                  {gestantesFiltradas.length > 0 ? (
                    gestantesFiltradas.map((g) => (
                      <tr key={g.id} className={`transition-colors hover:bg-slate-50/70 dark:hover:bg-slate-800/40 ${!g.activo ? 'opacity-70 grayscale-[30%]' : ''}`}>
                        <td className="px-6 py-4">
                          <span className="block text-xs font-bold text-slate-700 dark:text-slate-200">{g.nombre}</span>
                          <span className="mt-0.5 block font-mono text-[10px] text-slate-400 dark:text-slate-500">DNI: {g.dni || '--'}</span>
                        </td>

                        <td className="px-6 py-4 text-center text-xs font-medium text-slate-600 dark:text-slate-300">
                          {g.edad} años <br />
                          <span className="text-[10px] font-semibold text-slate-400 dark:text-slate-500">{g.semanas} semanas</span>
                        </td>

                        <td className="px-6 py-4 text-xs font-medium text-slate-600 dark:text-slate-300">{g.tiempoCentroSalud}</td>

                        <td className="px-6 py-4">
                          {g.riesgoClass === 'danger' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-red-100 dark:border-red-800/50 bg-red-50 dark:bg-red-900/20 px-2.5 py-1 text-[10px] font-bold text-red-600 dark:text-red-400">
                              <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-red-500"></span>
                              ALTA PRIORIDAD
                            </span>
                          )}

                          {g.riesgoClass === 'warn' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-amber-200 dark:border-amber-800/50 bg-amber-50 dark:bg-amber-900/20 px-2.5 py-1 text-[10px] font-bold text-amber-700 dark:text-amber-400">
                              <span className="h-1.5 w-1.5 rounded-full bg-amber-500"></span>
                              RIESGO MEDIO
                            </span>
                          )}

                          {g.riesgoClass === 'ok' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-green-200 dark:border-green-800/50 bg-green-50 dark:bg-green-900/20 px-2.5 py-1 text-[10px] font-bold text-green-700 dark:text-green-400">
                              <span className="h-1.5 w-1.5 rounded-full bg-green-500"></span>
                              {g.riesgoLabel}
                            </span>
                          )}
                          
                          {g.riesgoClass === 'none' && (
                            <span className="inline-flex items-center gap-1 rounded-full border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 px-2.5 py-1 text-[10px] font-bold text-slate-500 dark:text-slate-400">
                              <span className="h-1.5 w-1.5 rounded-full bg-slate-400 dark:bg-slate-500"></span>
                              {g.riesgoLabel}
                            </span>
                          )}
                        </td>

                        <td className="px-6 py-4">
                          <span
                            className={`flex items-center gap-1.5 text-xs font-semibold ${
                              !g.ultimaEvaluacionId 
                                ? 'text-slate-400 dark:text-slate-600' 
                                : g.horasDesdeSync > 24 ? 'text-amber-600 dark:text-amber-500' : 'text-slate-500 dark:text-slate-400'
                            }`}
                          >
                            <span
                              className={`h-1.5 w-1.5 rounded-full ${
                                !g.ultimaEvaluacionId 
                                  ? 'bg-slate-300 dark:bg-slate-600' 
                                  : g.horasDesdeSync > 24 ? 'bg-amber-500' : 'bg-green-500'
                              }`}
                            ></span>
                            {g.ultimaSync}
                          </span>
                        </td>

                        <td className="px-6 py-4 text-right">
                          <button
                            onClick={() => irADetalle(g)}
                            className="group inline-flex items-center gap-1 rounded-xl bg-slate-100 dark:bg-slate-800 px-3 py-1.5 text-xs font-bold text-slate-700 dark:text-slate-300 transition-all hover:bg-emerald-600 dark:hover:bg-emerald-600 hover:text-white"
                          >
                            Ver ficha clínica
                            <ChevronRight size={14} className="transition-transform group-hover:translate-x-0.5" />
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-xs font-medium text-slate-400 dark:text-slate-500">
                        {mostrarDadasDeAlta ? 'No hay pacientes dadas de alta.' : 'No se encontraron registros.'}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ============================================== */}
      {/* VISTA 2: DETALLE CLÍNICO */}
      {/* ============================================== */}
      {vista === 'detalle' && seleccionada && (
        <div className="flex h-full w-full animate-fade-in flex-col bg-slate-50 dark:bg-slate-950 transition-colors duration-300">
          <header className="flex shrink-0 items-center gap-4 border-b border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 px-6 py-4 transition-colors duration-300">
            <button
              onClick={irALista}
              className="rounded-xl border border-slate-200 dark:border-slate-700 p-2 text-slate-600 dark:text-slate-400 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800"
            >
              <ArrowLeft size={16} />
            </button>

            <div>
              <div className="flex items-center gap-3">
                <h2 className="font-serif text-xl font-bold text-slate-800 dark:text-slate-100">{seleccionada.nombre}</h2>
                <span className="rounded-md bg-slate-100 dark:bg-slate-800 px-2.5 py-0.5 font-mono text-xs text-slate-600 dark:text-slate-400">
                  DNI {seleccionada.dni || '--'}
                </span>
                {/* Etiqueta visual si está dada de alta */}
                {!seleccionada.activo && (
                  <span className="rounded-md bg-indigo-100 dark:bg-indigo-900/40 px-2.5 py-0.5 text-[10px] font-bold text-indigo-700 dark:text-indigo-400 uppercase tracking-wider">
                    Dada de Alta
                  </span>
                )}
              </div>
              <p className="mt-0.5 text-xs text-slate-500 dark:text-slate-500">
                Tiempo estimado al E.S.: {seleccionada.tiempoCentroSalud}
              </p>
            </div>

            <div className="ml-auto">
              <span
                className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-[10px] font-bold ${
                  seleccionada.riesgoClass === 'danger'
                    ? 'border border-red-100 dark:border-red-800/50 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400'
                    : seleccionada.riesgoClass === 'warn'
                      ? 'border border-amber-200 dark:border-amber-800/50 bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400'
                      : seleccionada.riesgoClass === 'ok'
                        ? 'border border-green-200 dark:border-green-800/50 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-400'
                        : 'border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400'
                }`}
              >
                {seleccionada.riesgoLabel}
              </span>
            </div>
          </header>

          <div className="flex-1 overflow-y-auto p-6">
            <div className="mx-auto grid max-w-5xl grid-cols-1 gap-6 md:grid-cols-3">
              
              {/* ================= COLUMNA IZQUIERDA ================= */}
              <div className="space-y-6 md:col-span-1">
                
                <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300">
                  <h3 className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                    Datos de la gestante
                  </h3>

                  <div className="space-y-3 text-xs">
                    <div className="flex justify-between border-b border-slate-50 dark:border-slate-800/50 py-1.5">
                      <span className="font-medium text-slate-500 dark:text-slate-400">Edad materna</span>
                      <span className="font-bold text-slate-800 dark:text-slate-200">{seleccionada.edad} años</span>
                    </div>
                    <div className="flex justify-between border-b border-slate-50 dark:border-slate-800/50 py-1.5">
                      <span className="font-medium text-slate-500 dark:text-slate-400">Edad gestacional</span>
                      <span className="font-bold text-emerald-700 dark:text-emerald-500">{seleccionada.semanas} semanas</span>
                    </div>
                    <div className="flex justify-between border-b border-slate-50 dark:border-slate-800/50 py-1.5">
                      <span className="font-medium text-slate-500 dark:text-slate-400">N.° embarazos</span>
                      <span className="font-bold text-slate-800 dark:text-slate-200">{seleccionada.numeroEmbarazos}</span>
                    </div>
                    <div className="flex justify-between py-1.5">
                      <span className="font-medium text-slate-500 dark:text-slate-400">Última sincronización</span>
                      <span className="font-bold text-slate-700 dark:text-slate-300">{seleccionada.ultimaSync}</span>
                    </div>
                  </div>
                </div>

                <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300">
                  <h3 className="mb-4 flex items-center gap-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                    <Activity size={14} className="text-emerald-600 dark:text-emerald-500" />
                    Probabilidades del modelo
                  </h3>

                  {detalleLoading ? (
                    <div className="flex items-center gap-2 text-xs text-slate-400 dark:text-slate-500">
                      <RefreshCw size={14} className="animate-spin" />
                      Cargando probabilidades...
                    </div>
                  ) : seleccionada.riesgoClass === 'none' ? (
                     <div className="text-center py-2 text-xs text-slate-400 dark:text-slate-500">
                        Aún no hay evaluaciones registradas para generar predicciones.
                     </div>
                  ) : (
                    <div className="space-y-4">
                      <div>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="font-semibold text-slate-700 dark:text-slate-300">Riesgo bajo</span>
                          <span className="font-bold text-green-700 dark:text-green-500">{probabilidades.bajo}%</span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-800">
                          <div className="h-2 rounded-full bg-green-500 transition-all" style={{ width: `${probabilidades.bajo}%` }}></div>
                        </div>
                      </div>

                      <div>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="font-semibold text-slate-700 dark:text-slate-300">Riesgo medio</span>
                          <span className="font-bold text-amber-600 dark:text-amber-500">{probabilidades.medio}%</span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-800">
                          <div className="h-2 rounded-full bg-amber-500 transition-all" style={{ width: `${probabilidades.medio}%` }}></div>
                        </div>
                      </div>

                      <div>
                        <div className="mb-1 flex justify-between text-xs">
                          <span className="font-semibold text-slate-700 dark:text-slate-300">Riesgo alto</span>
                          <span className="font-bold text-red-600 dark:text-red-500">{probabilidades.alto}%</span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-100 dark:bg-slate-800">
                          <div className="h-2 rounded-full bg-red-500 transition-all" style={{ width: `${probabilidades.alto}%` }}></div>
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {isAdmin && (
                  <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300">
                    <h3 className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                      Estado del servidor
                    </h3>
                    <p className="flex items-center gap-2 text-xs font-bold text-emerald-600 dark:text-emerald-500">
                      <CheckCircle2 size={15} />
                      Registro recibido por FastAPI
                    </p>
                    <p className="mt-2 text-[10px] text-slate-400 dark:text-slate-500">
                      Última evaluación: {seleccionada.ultimaFecha ? formatearFecha(seleccionada.ultimaFecha) : 'Sin fecha'}
                    </p>
                  </div>
                )}
                
                {/* LÓGICA DE VISUALIZACIÓN DEL BOTÓN DE ALTA */}
                {seleccionada.activo ? (
                  <button
                    onClick={handleDarDeAlta}
                    disabled={procesandoAlta}
                    className="group flex w-full items-center justify-center gap-2 rounded-2xl border-2 border-emerald-600 dark:border-emerald-500 bg-transparent py-3.5 text-sm font-bold text-emerald-700 dark:text-emerald-400 shadow-sm transition-all hover:bg-emerald-50 dark:hover:bg-emerald-900/20 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {procesandoAlta ? (
                      <>
                        <RefreshCw size={16} className="animate-spin" /> Procesando...
                      </>
                    ) : (
                      <>
                        <UserCheck size={16} className="transition-transform group-hover:scale-110" /> 
                        Registrar Parto / Alta
                      </>
                    )}
                  </button>
                ) : (
                  <div className="rounded-2xl border border-indigo-200 dark:border-indigo-800/60 bg-indigo-50 dark:bg-indigo-900/20 p-4 text-center shadow-sm">
                    <Archive className="mx-auto mb-2 h-6 w-6 text-indigo-500" />
                    <p className="text-xs font-bold text-indigo-700 dark:text-indigo-400">Expediente Archivado</p>
                    <p className="mt-1 text-[10px] text-indigo-600/80 dark:text-indigo-400/80">Esta paciente ya fue dada de alta del sistema de monitoreo activo.</p>
                  </div>
                )}

              </div>

              {/* ================= COLUMNA DERECHA: HISTORIAL ================= */}
              <div className="md:col-span-2">
                <div className="h-full rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-6 shadow-sm transition-colors duration-300">
                  <h3 className="mb-6 flex items-center gap-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                    <Clock size={14} className="text-emerald-600 dark:text-emerald-500" />
                    Trazabilidad y evolución de triajes móviles
                  </h3>

                  {seleccionada.historial.length === 0 ? (
                    <div className="rounded-xl border border-slate-100 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 p-4 text-xs text-slate-500 dark:text-slate-400">
                      Esta gestante aún no tiene evaluaciones sincronizadas.
                    </div>
                  ) : (
                    <div className="relative ml-3 space-y-6 border-l-2 border-slate-100 dark:border-slate-700/60">
                      {seleccionada.historial.map((item) => (
                        <div key={item.id} className="relative pl-6">
                          <div
                            className={`absolute -left-[5px] top-1 h-2.5 w-2.5 rounded-full border-2 border-white dark:border-slate-900 shadow-sm ${
                              item.riesgoClass === 'danger'
                                ? 'bg-red-500'
                                : item.riesgoClass === 'warn'
                                  ? 'bg-amber-500'
                                  : 'bg-green-500'
                            }`}
                          ></div>

                          <div className="mb-2 flex flex-col justify-between gap-1 sm:flex-row sm:items-center">
                            <span className="text-sm font-bold text-slate-800 dark:text-slate-200">
                              Semana de gestación: {item.semana}
                            </span>
                            <span className="text-[11px] font-medium text-slate-400 dark:text-slate-500">{item.fecha}</span>
                          </div>

                          <div className="mb-2">
                            {item.riesgoClass === 'danger' ? (
                              <span className="inline-flex items-center gap-1 rounded-md border border-red-100 dark:border-red-800/50 bg-red-50 dark:bg-red-900/20 px-2 py-0.5 text-[10px] font-bold text-red-600 dark:text-red-400">
                                ALTA PRIORIDAD
                              </span>
                            ) : item.riesgoClass === 'warn' ? (
                              <span className="inline-flex items-center gap-1 rounded-md border border-amber-100 dark:border-amber-800/50 bg-amber-50 dark:bg-amber-900/20 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:text-amber-400">
                                RIESGO MEDIO
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 rounded-md border border-green-100 dark:border-green-800/50 bg-green-50 dark:bg-green-900/20 px-2 py-0.5 text-[10px] font-bold text-green-700 dark:text-green-400">
                                ESTABLE
                              </span>
                            )}
                          </div>

                          <div className="rounded-xl border border-slate-100/70 dark:border-slate-700/50 bg-slate-50 dark:bg-slate-800/40 p-3.5 text-xs leading-relaxed text-slate-600 dark:text-slate-300">
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