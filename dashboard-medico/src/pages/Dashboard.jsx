import { useEffect, useMemo, useState, useRef } from 'react';
import { AlertTriangle, Search, CheckCircle2, RefreshCw, UserCircle2 } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, LabelList } from 'recharts';
import { api } from '../services/api';

export default function Dashboard() {
  const [listaGestantes, setListaGestantes] = useState([]);
  const [stats, setStats] = useState({ total: 0, alto: 0, medio: 0, bajo: 0 }); // NUEVO: Contadores dinámicos
  const [selectedItem, setSelectedItem] = useState(null);
  const [selectedDetail, setSelectedDetail] = useState(null);
  const [busqueda, setBusqueda] = useState('');
  const [loading, setLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [error, setError] = useState(null);

  const isDark = localStorage.getItem('theme') === 'oscuro';
  const alertedCases = useRef(new Set());
  const isAdmin = localStorage.getItem('rol') === 'admin' || localStorage.getItem('role') === 'admin';

  const getRiskColors = (riskClass) => {
    if (riskClass === 'danger')
      return { bg: 'bg-red-50 dark:bg-red-900/20', text: 'text-red-700 dark:text-red-400', border: 'border-red-200 dark:border-red-800/50', bar: 'bg-red-500' };
    if (riskClass === 'warn')
      return { bg: 'bg-amber-50 dark:bg-amber-900/20', text: 'text-amber-700 dark:text-amber-400', border: 'border-amber-200 dark:border-amber-800/50', bar: 'bg-amber-500' };
    if (riskClass === 'ok')
      return { bg: 'bg-green-50 dark:bg-green-900/20', text: 'text-green-700 dark:text-green-400', border: 'border-green-200 dark:border-green-800/50', bar: 'bg-green-500' };
    
    return { bg: 'bg-slate-50 dark:bg-slate-800/50', text: 'text-slate-500 dark:text-slate-400', border: 'border-slate-200 dark:border-slate-700', bar: 'bg-slate-300 dark:bg-slate-600' };
  };
  
  const getRiskClass = (nivelRiesgo) => {
    if (nivelRiesgo === 'Riesgo_Alto' || nivelRiesgo === 'ALTO') return 'danger';
    if (nivelRiesgo === 'Riesgo_Medio' || nivelRiesgo === 'MEDIO') return 'warn';
    if (nivelRiesgo === 'Riesgo_Bajo' || nivelRiesgo === 'BAJO') return 'ok';
    return 'none';
  };

  const getInitials = (nombre) => {
    if (!nombre) return 'G';
    return nombre.trim().split(/\s+/).slice(0, 2).map((parte) => parte[0]?.toUpperCase()).join('');
  };

  const formatFecha = (fechaIso) => {
    if (!fechaIso) return 'Fecha no disponible';
    try {
      const fecha = new Date(fechaIso);
      return fecha.toLocaleString('es-PE', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
    } catch {
      return fechaIso;
    }
  };

  const getProbabilidad = (detalle, evalBase) => {
    const nivel = detalle?.nivel_riesgo || evalBase?.nivel_riesgo;
    const probs = detalle?.probabilidades || evalBase?.probabilidades;

    if (Array.isArray(probs) && Array.isArray(probs[0])) {
      const valores = probs[0];
      const index = getRiskClass(nivel) === 'danger' ? 2 : getRiskClass(nivel) === 'warn' ? 1 : 0;
      const prob = valores[index];
      if (typeof prob === 'number') return Math.round(prob * 100);
    }

    if (getRiskClass(nivel) === 'danger') return 90;
    if (getRiskClass(nivel) === 'warn') return 55;
    if (getRiskClass(nivel) === 'ok') return 10;
    return 0;
  };

  const leerNumero = (data, campo) => {
    const value = data?.[campo];

    if (value === null || value === undefined) return null;

    const numero = Number(value);

    return Number.isFinite(numero) ? numero : null;
  };

  const leerFlag = (data, campo) => {
    const value = data?.[campo];

    return value === 1 || value === '1' || value === true || value === 'true';
  };

  const getFormData = (detalle, evalBase) => {
    return detalle?.form_data || evalBase?.form_data || {};
  };

  const tienePresionActualRegistrada = (data) => {
    const disponible = leerFlag(data, 'Presion_Actual_Disponible');
    const sistolica = leerNumero(data, 'Presion_Sistolica');
    const diastolica = leerNumero(data, 'Presion_Diastolica');

    return disponible && sistolica !== null && diastolica !== null && sistolica > 0 && diastolica > 0;
  };

  const tienePresionBasalRegistrada = (data) => {
    const disponible = leerFlag(data, 'Presion_Basal_Disponible');
    const sistolica = leerNumero(data, 'Presion_Basal_Sistolica');
    const diastolica = leerNumero(data, 'Presion_Basal_Diastolica');

    return disponible && sistolica !== null && diastolica !== null && sistolica > 0 && diastolica > 0;
  };

  const getPresion = (detalle, evalBase, campo) => {
    const data = getFormData(detalle, evalBase);

    if (campo === 'Presion_Sistolica' || campo === 'Presion_Diastolica') {
      if (!tienePresionActualRegistrada(data)) return 'No registrada';
    }

    if (campo === 'Presion_Basal_Sistolica' || campo === 'Presion_Basal_Diastolica') {
      if (!tienePresionBasalRegistrada(data)) return 'No registrada';
    }

    const value = leerNumero(data, campo);

    if (value === null || value <= 0) return 'No registrada';

    return value;
  };

  const normalizarSintoma = (sintoma) => {
    const limpio = String(sintoma || '').trim();

    const equivalencias = {
      'Taquicardia sostenida': 'Taquicardia sostenida',
      'Cefalea intensa': 'Cefalea intensa',
      'Alteración visual': 'Alteración visual',
      'Zumbido oídos': 'Zumbido de oídos',
      'Zumbido de oídos': 'Zumbido de oídos',
      'Dolor hipocondrio derecho': 'Dolor en hipocondrio derecho',
      'Dolor en hipocondrio derecho': 'Dolor en hipocondrio derecho',
      'Dolor boca estómago': 'Dolor en boca del estómago',
      'Dolor en boca del estómago': 'Dolor en boca del estómago',
      'Hinchazón cara manos': 'Hinchazón en cara y manos',
      'Hinchazón en cara y manos': 'Hinchazón en cara y manos',
      'Sangrado vaginal': 'Sangrado vaginal',
      'Mareo desmayo': 'Mareo o desmayo',
      'Mareo o desmayo': 'Mareo o desmayo',
      'Sudoración fría': 'Sudoración fría',
      'Fiebre escalofríos': 'Fiebre o escalofríos',
      'Fiebre o escalofríos': 'Fiebre o escalofríos',
      'Hipotermia subjetiva': 'Sensación de hipotermia',
      'Sensación de hipotermia': 'Sensación de hipotermia',
      'Flujo vaginal fétido': 'Flujo vaginal fétido',
      'Dolor abdominal bajo': 'Dolor abdominal bajo',
      'Pérdida líquido amniótico': 'Pérdida de líquido amniótico',
      'Pérdida de líquido amniótico': 'Pérdida de líquido amniótico',
      'Confusión somnolencia': 'Confusión o somnolencia',
      'Confusión o somnolencia': 'Confusión o somnolencia',
      'Movimientos fetales disminuidos': 'Movimientos fetales disminuidos',
      'Dificultad respirar': 'Dificultad para respirar',
      'Dificultad para respirar': 'Dificultad para respirar',
    };

    return equivalencias[limpio] || limpio;
  };

  const reproducirAlertaSiEsNecesario = (gestantesActivas) => {
    const alertaActivada = localStorage.getItem('alertaSonora') !== 'false';
    if (!alertaActivada) return;

    let hayNuevoCritico = false;
    
    gestantesActivas.forEach((item) => {
      const isDanger = getRiskClass(item.ultima_evaluacion?.nivel_riesgo) === 'danger';
      const uniqueId = item.ultima_evaluacion?.id || `${item.gestante?.id}-${item.ultima_evaluacion?.fecha_hora}`;

      if (isDanger && uniqueId && !alertedCases.current.has(uniqueId)) {
        alertedCases.current.add(uniqueId);
        hayNuevoCritico = true;
      }
    });

    if (hayNuevoCritico) {
      const audio = new Audio('/alerta-roja.mp3');
      audio.volume = 1.0; 
      
      const playPromise = audio.play();
      if (playPromise !== undefined) {
        playPromise.catch(error => {
          console.warn('Autoplay bloqueado. Requiere interacción del usuario.', error);
        });
      }
    }
  };

  const chartData = useMemo(() => {
    const form = getFormData(selectedDetail, selectedItem?.ultima_evaluacion);

    const data = [];

    if (tienePresionBasalRegistrada(form)) {
      data.push({
        day: 'Basal',
        sys: leerNumero(form, 'Presion_Basal_Sistolica'),
        dia: leerNumero(form, 'Presion_Basal_Diastolica'),
      });
    }

    if (tienePresionActualRegistrada(form)) {
      data.push({
        day: 'Actual',
        sys: leerNumero(form, 'Presion_Sistolica'),
        dia: leerNumero(form, 'Presion_Diastolica'),
      });
    }

    return data;
  }, [selectedDetail, selectedItem]);

  const cargarDetalle = async (item) => {
    if (!item) return;
    setSelectedItem(item);
    
    if (item.ultima_evaluacion?.id) {
      setDetailLoading(true);
      try {
        const detalle = await api.getEvaluacionDetalle(item.ultima_evaluacion.id);
        setSelectedDetail(detalle);
      } catch (err) {
        console.error(err);
        setSelectedDetail(null);
      } finally {
        setDetailLoading(false);
      }
    } else {
      setSelectedDetail(null);
    }
  };

  // NUEVO: Función para procesar y filtrar datos puros
  const procesarDatos = (data) => {
    const ultimasRaw = data.ultimas_gestantes || [];
    
    // 1. Filtramos estrictamente a las que están activas
    const activas = ultimasRaw.filter(item => item.gestante?.activo !== false);
    
    // 2. Recalculamos los contadores del header basándonos SOLO en las activas
    let cAlto = 0, cMedio = 0, cBajo = 0;
    activas.forEach(item => {
      const rClass = getRiskClass(item.ultima_evaluacion?.nivel_riesgo);
      if (rClass === 'danger') cAlto++;
      else if (rClass === 'warn') cMedio++;
      else if (rClass === 'ok') cBajo++;
    });

    setStats({ total: activas.length, alto: cAlto, medio: cMedio, bajo: cBajo });
    setListaGestantes(activas);
    return activas;
  };

  const cargarDashboard = async (fondo = false) => {
    if (!fondo) {
      setLoading(true);
      setError(null);
    }

    try {
      const data = await api.getDashboardResumen();
      const activas = procesarDatos(data);
      
      reproducirAlertaSiEsNecesario(activas);

      if (!fondo && activas.length > 0) {
        await cargarDetalle(activas[0]);
      } else if (!fondo) {
        setSelectedItem(null);
        setSelectedDetail(null);
      }
    } catch (err) {
      console.error(err);
      if (!fondo) setError(err.message || 'No se pudo conectar con el backend.');
    } finally {
      if (!fondo) setLoading(false);
    }
  };
  
  useEffect(() => {
    let cancelado = false;
    let intervalo;

    async function cargarDashboardInicial() {
      try {
        const data = await api.getDashboardResumen();
        if (cancelado) return;

        const activas = procesarDatos(data);
        let detalleInicial = null;

        if (activas.length > 0 && activas[0].ultima_evaluacion?.id) {
          try {
            detalleInicial = await api.getEvaluacionDetalle(activas[0].ultima_evaluacion.id);
          } catch (err) {
            console.error(err);
          }
        }

        if (cancelado) return;

        setSelectedItem(activas.length > 0 ? activas[0] : null);
        setSelectedDetail(detalleInicial);
        setError(null);
        
        reproducirAlertaSiEsNecesario(activas);
      } catch (err) {
        if (cancelado) return;
        console.error(err);
        setError(err.message || 'No se pudo conectar con el backend.');
      } finally {
        if (!cancelado) setLoading(false);
      }
    }

    cargarDashboardInicial();

    const tiempoPolling = parseInt(localStorage.getItem('polling') || '30') * 1000;
    intervalo = setInterval(() => {
      cargarDashboard(true);
    }, tiempoPolling);

    return () => { 
      cancelado = true;
      clearInterval(intervalo);
    };
  }, []);

  const gestantesFiltradas = listaGestantes.filter((item) => {
    // Ya no filtramos el activo aquí porque listaGestantes YA está limpia
    const estadoEval = item.ultima_evaluacion ? item.ultima_evaluacion.nivel_riesgo_legible : 'sin evaluación';
    const texto = `${item.gestante?.nombre || ''} ${item.gestante?.dni || ''} ${estadoEval}`.toLowerCase();
    return texto.includes(busqueda.toLowerCase());
  });

  const gestante = selectedItem?.gestante;
  const evalActiva = selectedDetail || selectedItem?.ultima_evaluacion;
  const riskClass = getRiskClass(evalActiva?.nivel_riesgo);
  const colors = getRiskColors(riskClass);
  const probabilidad = getProbabilidad(selectedDetail, evalActiva);
  const formActivo = getFormData(selectedDetail, evalActiva);
  const hayPresionActual = tienePresionActualRegistrada(formActivo);
  const presionSistolicaTexto = getPresion(selectedDetail, evalActiva, 'Presion_Sistolica');
  const presionDiastolicaTexto = getPresion(selectedDetail, evalActiva, 'Presion_Diastolica');

  const getProfileInitialsColors = (rClass) => {
    if (rClass === 'danger') return 'border-red-200 dark:border-red-800/50 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400';
    if (rClass === 'warn') return 'border-amber-200 dark:border-amber-800/50 bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400';
    if (rClass === 'ok') return 'border-green-200 dark:border-green-800/50 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400';
    return 'border-slate-200 dark:border-slate-700 bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400';
  };

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp dark:bg-slate-950 transition-colors">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-verdeApp dark:text-green-500" />
          <p className="text-sm font-bold text-slate-700 dark:text-slate-300">Cargando datos del servidor...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp dark:bg-slate-950 p-4 sm:p-6 transition-colors">
        <div className="max-w-md w-full rounded-2xl border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-900/20 p-6 text-center shadow-sm">
          <AlertTriangle className="mx-auto mb-3 h-8 w-8 text-red-600 dark:text-red-500" />
          <h2 className="text-sm font-bold text-red-800 dark:text-red-400">No se pudo cargar el dashboard</h2>
          <p className="mt-2 text-xs text-red-700 dark:text-red-300">{error}</p>
          <button onClick={() => cargarDashboard(false)} className="mt-4 rounded-xl bg-red-600 px-4 py-2 text-xs font-bold text-white hover:bg-red-700 dark:hover:bg-red-500 transition-colors">
            Reintentar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-full flex-col bg-fondoApp dark:bg-slate-950 overflow-hidden transition-colors duration-300">
      
      {/* HEADER RESPONSIVE */}
      <header className="flex flex-col sm:flex-row shrink-0 items-start sm:items-center justify-between gap-3 sm:gap-0 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 px-4 md:px-6 py-3 transition-colors duration-300">
        <h2 className="text-sm font-bold text-slate-800 dark:text-white">Panel de triaje — Monitoreo de gestantes</h2>
        <button onClick={() => cargarDashboard(false)} className="flex items-center gap-1.5 rounded-full border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-1.5 text-[11px] font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
          <RefreshCw size={13} /> Actualizar
        </button>
      </header>

      {/* STATS RESPONSIVE (AHORA CON LOS CONTADORES DINÁMICOS) */}
      <div className="grid shrink-0 grid-cols-2 md:grid-cols-4 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 transition-colors duration-300">
        <div className="border-b md:border-b-0 border-r border-slate-100 dark:border-slate-800 px-4 py-3 sm:px-6 sm:py-4 text-center bg-slate-50 dark:bg-slate-900/50">
          <div className="text-2xl font-bold leading-none text-slate-700 dark:text-white">{stats.total}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-500 dark:text-slate-400">Gestantes</div>
        </div>
        <div className="border-b md:border-b-0 md:border-r border-slate-100 dark:border-slate-800 px-4 py-3 sm:px-6 sm:py-4 text-center">
          <div className="text-2xl font-bold leading-none text-red-500">{stats.alto}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400 dark:text-slate-500">Riesgo Alto</div>
        </div>
        <div className="border-r border-slate-100 dark:border-slate-800 px-4 py-3 sm:px-6 sm:py-4 text-center">
          <div className="text-2xl font-bold leading-none text-amber-500">{stats.medio}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400 dark:text-slate-500">Riesgo Medio</div>
        </div>
        <div className="px-4 py-3 sm:px-6 sm:py-4 text-center">
          <div className="text-2xl font-bold leading-none text-verdeApp dark:text-green-500">{stats.bajo}</div>
          <div className="mt-1 text-[10px] font-semibold uppercase tracking-widest text-slate-400 dark:text-slate-500">Estables</div>
        </div>
      </div>

      {/* LAYOUT PRINCIPAL RESPONSIVE */}
      <div className="flex flex-1 flex-col md:flex-row overflow-hidden">
        
        {/* SIDEBAR RESPONSIVE */}
        <div className="flex w-full md:w-72 shrink-0 flex-col border-b md:border-b-0 md:border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 max-h-[35vh] md:max-h-none md:h-full transition-colors duration-300">
          <div className="border-b border-slate-100 dark:border-slate-800 px-4 md:px-3 py-3 md:py-4 shrink-0">
            <div className="relative">
              <Search size={14} className="absolute left-2.5 top-[10px] text-slate-400 dark:text-slate-500" />
              <input
                type="text"
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                placeholder="Buscar paciente activa..."
                className="w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-800 dark:text-white py-1.5 pl-8 pr-3 text-xs outline-none focus:border-verdeApp dark:focus:border-green-500 placeholder:text-slate-400 dark:placeholder:text-slate-500 transition-colors"
              />
            </div>
          </div>

          <div className="flex-1 overflow-y-auto">
            {gestantesFiltradas.length === 0 ? (
              <div className="p-4 text-center text-xs text-slate-400 dark:text-slate-500">No se encontraron gestantes activas.</div>
            ) : (
              gestantesFiltradas.map((item) => {
                const itemEval = item.ultima_evaluacion;
                const itemRiskClass = getRiskClass(itemEval?.nivel_riesgo);
                const itemColors = getRiskColors(itemRiskClass);
                const isActive = selectedItem?.gestante?.id === item.gestante?.id;
                const nombre = item.gestante?.nombre || 'Gestante sin nombre';

                return (
                <button
                 key={item.gestante?.id}
                 onClick={() => cargarDetalle(item)}
                 className={`flex w-full cursor-pointer items-center gap-3 border-b border-slate-100 dark:border-slate-800 border-r-4 p-3 text-left transition-all ${
                    isActive 
                    ? 'border-r-green-500 bg-slate-50 dark:bg-slate-800/80'  
                    : 'border-r-transparent hover:bg-slate-50 dark:hover:bg-slate-800/40' }`}
                >
                    <div className={`h-10 w-1 shrink-0 rounded-full ${itemColors.bar}`}></div>
                    <div className="min-w-0 flex-1">
                      <p className={`truncate text-xs font-semibold ${isActive ? 'text-verdeOscuro dark:text-green-400' : 'text-slate-800 dark:text-slate-200'}`}>{nombre}</p>
                      <p className="mt-0.5 text-[10px] text-slate-400 dark:text-slate-500">
                        {item.gestante?.edad_materna ?? '--'} años · {item.gestante?.semanas_gestacion ?? '--'} sem · {itemEval ? itemEval.nivel_riesgo_legible : 'Sin evaluación'}
                      </p>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* CONTENIDO PRINCIPAL (DETALLES) RESPONSIVE */}
        <div className="flex flex-1 flex-col gap-4 overflow-y-auto p-4 sm:p-6">
          {!selectedItem ? (
            <div className="rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-6 text-center text-sm text-slate-500 dark:text-slate-400 transition-colors">
              Selecciona una gestante de la lista para ver sus detalles.
            </div>
          ) : (
            <>
              {/* TARJETA DEL PERFIL RESPONSIVE */}
              <div className="rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4 sm:p-5 shadow-sm transition-colors duration-300">
                <div className="flex flex-col sm:flex-row items-center sm:items-start gap-4 text-center sm:text-left">
                  
                  <div className={`flex h-14 w-14 sm:h-12 sm:w-12 shrink-0 items-center justify-center rounded-full border-2 font-bold text-lg sm:text-base ${getProfileInitialsColors(riskClass)}`}>
                    {getInitials(gestante?.nombre)}
                  </div>

                  <div className="flex-1">
                    <h3 className="text-lg font-bold text-slate-800 dark:text-white">{gestante?.nombre || 'Gestante sin nombre'}</h3>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                      DNI: {gestante?.dni || '--'} · {gestante?.edad_materna ?? '--'} años · {gestante?.semanas_gestacion ?? '--'} sem. gestación
                    </p>
                    {evalActiva && (
                      <p className="mt-1 sm:mt-0.5 text-[10px] font-medium text-slate-400 dark:text-slate-500">Última evaluación: {formatFecha(evalActiva.fecha_hora)}</p>
                    )}
                  </div>
                  
                  {evalActiva && (
                    <div className="mt-3 sm:mt-0 sm:ml-auto text-center shrink-0">
                      <div className={`text-3xl sm:text-4xl font-black ${riskClass === 'danger' ? 'text-red-500 dark:text-red-400' : riskClass === 'warn' ? 'text-amber-500 dark:text-amber-400' : 'text-green-600 dark:text-green-500'}`}>
                        {probabilidad}%
                      </div>
                      <div className="mt-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Prob. clase</div>
                    </div>
                  )}
                </div>

                {evalActiva ? (
                  <div className={`mt-5 flex flex-col sm:flex-row items-start sm:items-center gap-3 rounded-lg border p-3 ${colors.bg} ${colors.border}`}>
                    <AlertTriangle className={`shrink-0 ${colors.text}`} size={20} />
                    <div>
                      <p className={`text-xs font-bold ${colors.text}`}>{evalActiva.nivel_riesgo_legible || evalActiva.nivel_riesgo}</p>
                      <p className={`mt-0.5 text-[10px] opacity-90 ${colors.text}`}>{evalActiva.mensaje}</p>
                    </div>
                  </div>
                ) : (
                  <div className="mt-5 flex flex-col sm:flex-row items-start sm:items-center gap-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50 p-3">
                    <UserCircle2 className="shrink-0 text-slate-400 dark:text-slate-500" size={20} />
                    <div>
                      <p className="text-xs font-bold text-slate-600 dark:text-slate-300">Paciente registrada exitosamente</p>
                      <p className="mt-0.5 text-[10px] text-slate-500 dark:text-slate-400">Esta gestante aún no ha completado una evaluación de riesgo médico en la aplicación.</p>
                    </div>
                  </div>
                )}
              </div>

              {evalActiva && (
                <>
                {/* BLOQUE GRÁFICOS RESPONSIVE */}
<div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
  
  {/* TARJETA IZQUIERDA: Última lectura */}
  <div className="flex flex-col h-full rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4 sm:p-5 shadow-sm transition-colors duration-300">
    <div className="mb-4 shrink-0 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
      Última lectura
    </div>
    
    <div className="grid flex-1 grid-cols-2 gap-3 sm:gap-2">
      <div className="flex flex-col justify-center rounded-lg bg-slate-50 dark:bg-slate-800/50 p-4">
        <p className="mb-1 text-[10px] uppercase text-slate-400 dark:text-slate-500">Sistólica</p>
        <p className={`${hayPresionActual ? 'text-4xl' : 'text-sm'} font-black ${hayPresionActual ? colors.text : 'text-slate-400 dark:text-slate-500'}`}>
          {detailLoading ? '...' : presionSistolicaTexto}
          {hayPresionActual && (
            <span className="ml-1 text-xs font-normal text-slate-400 dark:text-slate-500">mmHg</span>
          )}
        </p>
      </div>
      
      <div className="flex flex-col justify-center rounded-lg bg-slate-50 dark:bg-slate-800/50 p-4">
        <p className="mb-1 text-[10px] uppercase text-slate-400 dark:text-slate-500">Diastólica</p>
        <p className={`${hayPresionActual ? 'text-4xl' : 'text-sm'} font-black ${hayPresionActual ? colors.text : 'text-slate-400 dark:text-slate-500'}`}>
          {detailLoading ? '...' : presionDiastolicaTexto}
          {hayPresionActual && (
            <span className="ml-1 text-xs font-normal text-slate-400 dark:text-slate-500">mmHg</span>
          )}
        </p>
      </div>
    </div>
  </div>

  {/* TARJETA DERECHA: Gráfico */}
  <div className="flex flex-col h-full rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4 sm:p-5 shadow-sm transition-colors duration-300">
    <div className="mb-2 shrink-0 flex items-center justify-between">
      <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
        Presión arterial registrada
      </span>
    </div>
    
    {/* min-h-[160px] asegura que el gráfico tenga espacio aunque la pantalla sea pequeña */}
    <div className="flex-1 min-h-[160px] w-full mt-2">
      {chartData.length === 0 ? (
        <div className="flex h-full min-h-[160px] items-center justify-center rounded-lg border border-dashed border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/40 px-4 text-center">
          <p className="text-xs font-semibold text-slate-400 dark:text-slate-500">
            No hay presión basal ni presión actual registrada para graficar.
          </p>
        </div>
      ) : (
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData} margin={{ top: 25, right: 20, left: 20, bottom: 10 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={isDark ? '#334155' : '#f1f5f9'} />

            <XAxis 
              dataKey="day" 
              axisLine={false} 
              tickLine={false} 
              tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 500 }} 
              padding={{ left: 20, right: 30 }} 
              tickMargin={10} 
            />

            <YAxis domain={['dataMin - 25', 'dataMax + 25']} hide />

            <Tooltip contentStyle={{ fontSize: '10px', borderRadius: '8px', backgroundColor: isDark ? '#1e293b' : '#fff', border: isDark ? 'none' : '1px solid #e2e8f0', color: isDark ? '#fff' : '#000' }} />

            <Legend wrapperStyle={{ fontSize: '10px', top: -10 }} verticalAlign="top" align="right" />

            <Line type="monotone" name="Sistólica" dataKey="sys" stroke="#ef4444" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }}>
              <LabelList dataKey="sys" position="top" offset={8} fill="#ef4444" fontSize={11} fontWeight="bold" />
            </Line>

            <Line type="monotone" name="Diastólica" dataKey="dia" stroke="#f59e0b" strokeWidth={2} dot={{ r: 4 }} activeDot={{ r: 6 }}>
              <LabelList dataKey="dia" position="bottom" offset={8} fill="#f59e0b" fontSize={11} fontWeight="bold" />
            </Line>
          </LineChart>
        </ResponsiveContainer>
      )}
    </div>
  </div>

</div>

                  {/* SÍNTOMAS RESPONSIVE */}
                  <div className="rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4 sm:p-5 shadow-sm transition-colors duration-300">
                    <div className="flex flex-col sm:flex-row items-start justify-between gap-4 sm:gap-0">
                      <div className="w-full sm:w-auto">
                        <div className="mb-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Síntomas reportados</div>
                        <div className="flex flex-wrap gap-2">
                          {(evalActiva.sintomas_detectados || []).length > 0 ? (
                            evalActiva.sintomas_detectados.map((s) => {
                              const sintomaTexto = normalizarSintoma(s);

                              return (
                                <span key={`${s}-${sintomaTexto}`} className="rounded-md border border-red-100 dark:border-red-800/50 bg-red-50 dark:bg-red-900/20 px-2.5 py-1 text-[11px] font-semibold text-red-700 dark:text-red-400">
                                  {sintomaTexto}
                                </span>
                              );
                            })
                          ) : (
                            <span className="text-xs text-slate-400 dark:text-slate-500">Sin síntomas de alarma.</span>
                          )}
                        </div>
                      </div>
                      
                      {isAdmin && (
                        <div className="w-full sm:w-auto text-left sm:text-right border-t border-slate-100 dark:border-slate-800 sm:border-0 pt-3 sm:pt-0">
                          <div className="mb-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">Estado del servidor</div>
                          <p className="flex items-center justify-start sm:justify-end gap-1 text-xs font-semibold text-green-600 dark:text-green-500">
                            <CheckCircle2 size={14} /> {evalActiva.estado_servidor || 'recibido'}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}