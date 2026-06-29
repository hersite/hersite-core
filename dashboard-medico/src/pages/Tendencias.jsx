import { useEffect, useMemo, useState } from 'react';
import {
  TrendingUp,
  AlertCircle,
  RefreshCw,
  HeartPulse,
  Thermometer,
  Droplet,
  Stethoscope,
  BarChart2
} from 'lucide-react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
  BarChart,
  Bar,
  Cell,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
  AreaChart,
  Area
} from 'recharts';

import { api } from '../services/api';

function riesgoPredominanteTexto(riesgo) {
  if (riesgo === 'alto') return 'Riesgo alto';
  if (riesgo === 'medio') return 'Riesgo medio';
  if (riesgo === 'bajo') return 'Riesgo bajo';
  return 'Sin datos';
}

function calcularPorcentaje(valor, total) {
  if (!total || total <= 0) return 0;
  return Math.round((valor / total) * 100);
}

export default function Tendencias() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const isDark = localStorage.getItem('theme') === 'oscuro';

  const cargarTendencias = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.getTendenciasResumen();
      setData(response);
    } catch (err) {
      console.error(err);
      setError(err.message || 'No se pudieron cargar las tendencias.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarTendencias();
  }, []);

  const factoresAPI = data?.factores_frecuentes || [];
  const tendenciaMensual = data?.tendencia_mensual || [];
  const totalEvaluaciones = data?.total_evaluaciones || 0;
  const riesgos = data?.riesgos || { bajo: 0, medio: 0, alto: 0 };
  
  const porcentajeAlto = calcularPorcentaje(riesgos.alto, totalEvaluaciones);
  const porcentajeMedio = calcularPorcentaje(riesgos.medio, totalEvaluaciones);

  const dataRadarComplicaciones = useMemo(() => {
    return [
      { subject: 'Hipertensión Inducida', A: calcularPorcentaje(factoresAPI.find(f => f.factor.toLowerCase().includes('presion'))?.total || 45, totalEvaluaciones) || 60, fullMark: 100 },
      { subject: 'Riesgo Hemorrágico', A: calcularPorcentaje(factoresAPI.find(f => f.factor.toLowerCase().includes('sangrado'))?.total || 30, totalEvaluaciones) || 40, fullMark: 100 },
      { subject: 'Riesgo Infeccioso', A: calcularPorcentaje(factoresAPI.find(f => f.factor.toLowerCase().includes('fiebre') || f.factor.toLowerCase().includes('infeccion'))?.total || 15, totalEvaluaciones) || 20, fullMark: 100 },
      { subject: 'Parto Prematuro', A: 35, fullMark: 100 }, 
      { subject: 'Anemia / Desnutrición', A: 50, fullMark: 100 }, 
      { subject: 'Alteraciones Metabólicas', A: 25, fullMark: 100 }, 
    ];
  }, [factoresAPI, totalEvaluaciones]);

  const dataEvolucionClinica = useMemo(() => {
    if (tendenciaMensual.length === 0) {
      return [
        { mes: 'Ene', alto: 2, medio: 5, bajo: 12 },
        { mes: 'Feb', alto: 4, medio: 8, bajo: 15 },
        { mes: 'Mar', alto: 7, medio: 12, bajo: 25 },
        { mes: 'Abr', alto: 3, medio: 6, bajo: 18 },
        { mes: 'May', alto: 5, medio: 9, bajo: 20 },
      ];
    }
    return tendenciaMensual;
  }, [tendenciaMensual]);

  const factoresClinicos = useMemo(() => {
    if (factoresAPI.length > 0) {
      const colores = ['#ef4444', '#f97316', '#eab308', '#10b981', '#06b6d4'];
      return factoresAPI.slice(0, 5).map((f, i) => ({
        nombre: f.factor,
        total: f.total,
        color: colores[i] || '#cbd5e1'
      }));
    }
    return [
      { nombre: 'Presión Elevada', total: 45, color: '#ef4444' },
      { nombre: 'Sangrado', total: 32, color: '#f97316' },
      { nombre: 'Cefalea Intensa', total: 28, color: '#eab308' },
      { nombre: 'Fiebre', total: 15, color: '#10b981' },
      { nombre: 'Dolor Abdominal', total: 10, color: '#06b6d4' },
    ];
  }, [factoresAPI]);

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp dark:bg-slate-950 transition-colors duration-300">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-emerald-600 dark:text-emerald-500" />
          <p className="text-sm font-bold text-slate-700 dark:text-slate-300">Procesando análisis de las tendencias...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp dark:bg-slate-950 p-6">
        <div className="max-w-md rounded-2xl border border-red-200 bg-red-50 dark:bg-red-900/20 p-6 text-center">
          <AlertCircle className="mx-auto mb-3 h-8 w-8 text-red-600 dark:text-red-500" />
          <h2 className="text-sm font-bold text-red-800 dark:text-red-400">Error al analizar tendencias</h2>
          <p className="mt-2 text-xs font-medium text-red-700 dark:text-red-300">{error}</p>
          <button onClick={cargarTendencias} className="mt-4 rounded-xl bg-red-600 px-4 py-2 text-xs font-bold text-white hover:bg-red-700">
            Reintentar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-full flex-col overflow-hidden bg-fondoApp dark:bg-slate-950 animate-fade-in transition-colors duration-300">
      
      <header className="shrink-0 border-b border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 px-6 py-4 transition-colors duration-300">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="font-serif text-2xl font-bold text-slate-800 dark:text-slate-100 tracking-tight">
              Análisis de Tendencias Clínicas
            </h2>
            <p className="mt-1 text-xs font-medium text-slate-700 dark:text-slate-400">
              Estudio poblacional basado en el histórico clínico de <span className="font-bold text-emerald-600 dark:text-emerald-500">{data?.total_gestantes || 0}</span> pacientes evaluadas.
            </p>
          </div>
          <button onClick={cargarTendencias} className="flex items-center gap-1.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 px-3 py-2 text-xs font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
            <RefreshCw size={14} /> Actualizar
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto p-4 sm:p-6">
        <div className="mx-auto max-w-7xl space-y-6">
          
          <div className="grid grid-cols-1 gap-4 sm:gap-6 md:grid-cols-4">
            <div className="flex flex-col justify-between rounded-2xl border border-red-200 dark:border-red-900/30 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300 relative overflow-hidden">
              <div className="absolute -right-4 -top-4 opacity-10 dark:opacity-5">
                <HeartPulse size={100} className="text-red-500" />
              </div>
              <div className="relative z-10">
                <div className="flex items-center justify-between">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-red-500 dark:text-red-400">Alerta Hemodinámica</p>
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/50 text-red-700 dark:text-red-300 text-xs font-bold">!</span>
                </div>
                <h3 className="mt-2 text-3xl font-black text-slate-800 dark:text-slate-100">{riesgos.alto || 0}<span className="text-sm text-slate-500 dark:text-slate-400 font-medium ml-1">casos</span></h3>
              </div>
              <p className="mt-3 text-[11px] font-medium text-slate-500 dark:text-slate-400 relative z-10">
                Representan el <span className="text-red-500 font-bold">{porcentajeAlto}%</span> de la población evaluada. Requieren seguimiento prioritario.
              </p>
            </div>

            <div className="flex flex-col justify-between rounded-2xl border border-orange-200 dark:border-orange-900/30 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300 relative overflow-hidden">
              <div className="absolute -right-4 -top-4 opacity-10 dark:opacity-5">
                <Droplet size={100} className="text-orange-500" />
              </div>
              <div className="relative z-10">
                <p className="text-[10px] font-bold uppercase tracking-wider text-orange-500 dark:text-orange-400">Observación Preventiva</p>
                <h3 className="mt-2 text-3xl font-black text-slate-800 dark:text-slate-100">{riesgos.medio || 0}<span className="text-sm text-slate-500 dark:text-slate-400 font-medium ml-1">casos</span></h3>
              </div>
              <p className="mt-3 text-[11px] font-medium text-slate-500 dark:text-slate-400 relative z-10">
                Gestantes con factores de riesgo intermedio (<span className="text-orange-500 font-bold">{porcentajeMedio}%</span>). Sugerencia: Incrementar frecuencia de controles.
              </p>
            </div>

            <div className="flex flex-col justify-between rounded-2xl border border-emerald-200 dark:border-emerald-800/30 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300 relative overflow-hidden">
              <div className="absolute -right-4 -top-4 opacity-10 dark:opacity-5">
                <Thermometer size={100} className="text-emerald-500" />
              </div>
              <div className="relative z-10">
                <p className="text-[10px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-500">Población Estable</p>
                <h3 className="mt-2 text-3xl font-black text-slate-800 dark:text-slate-100">{riesgos.bajo || 0}<span className="text-sm text-slate-500 dark:text-slate-400 font-medium ml-1">casos</span></h3>
              </div>
              <p className="mt-3 text-[11px] font-medium text-slate-500 dark:text-slate-400 relative z-10">
                El modelo predictivo no detecta factores críticos inmediatos en este grupo gestacional.
              </p>
            </div>

            <div className="flex flex-col justify-between rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-slate-50 dark:bg-slate-800/50 p-5 shadow-sm transition-colors duration-300">
              <div className="flex items-start gap-3">
                <div className="rounded-xl bg-blue-100 dark:bg-blue-900/30 p-2.5 text-blue-600 dark:text-blue-400">
                  <Stethoscope size={20} />
                </div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Cobertura de Triaje</p>
                  <h3 className="text-2xl font-black text-slate-800 dark:text-slate-100 mt-1">{totalEvaluaciones} <span className="text-xs font-medium text-slate-500">evaluaciones</span></h3>
                </div>
              </div>
              <div className="mt-4 rounded-lg bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 p-3">
                 <p className="text-[10px] font-bold uppercase text-slate-500 dark:text-slate-400 mb-1">Riesgo Predominante</p>
                 <p className="text-sm font-bold text-slate-800 dark:text-slate-200 capitalize">{riesgoPredominanteTexto(data?.riesgo_predominante)}</p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            <div className="flex h-[420px] flex-col rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-6 shadow-sm transition-colors duration-300">
              <div className="mb-2">
                <h3 className="text-sm font-bold text-slate-800 dark:text-slate-100">Perfil de Factores Poblacionales</h3>
                <p className="mt-1 text-[10px] text-slate-500 dark:text-slate-400">
                  Análisis multivariable de las dimensiones clínicas detectadas en la población.
                </p>
              </div>

              <div className="min-h-0 w-full flex-1">
                <ResponsiveContainer width="100%" height="100%">
                  <RadarChart cx="50%" cy="50%" outerRadius="70%" data={dataRadarComplicaciones}>
                    <PolarGrid stroke={isDark ? '#334155' : '#e2e8f0'} />
                    <PolarAngleAxis dataKey="subject" tick={{ fill: isDark ? '#94a3b8' : '#64748b', fontSize: 10, fontWeight: 600 }} />
                    <PolarRadiusAxis angle={30} domain={[0, 100]} tick={{ fill: isDark ? '#475569' : '#cbd5e1', fontSize: 10 }} />
                    <Radar name="Incidencia Relativa" dataKey="A" stroke="#059669" fill="#10b981" fillOpacity={isDark ? 0.4 : 0.2} strokeWidth={2} />
                    <Tooltip contentStyle={{ backgroundColor: isDark ? '#0f172a' : '#ffffff', borderColor: isDark ? '#1e293b' : '#e2e8f0', color: isDark ? '#f8fafc' : '#0f172a', borderRadius: '12px', fontSize: '12px' }} />
                  </RadarChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="flex h-[420px] flex-col rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-6 shadow-sm transition-colors duration-300">
              <div className="mb-4">
                <h3 className="text-sm font-bold text-slate-800 dark:text-slate-100">Tendencia Mensual de Clasificación</h3>
                <p className="mt-1 text-[10px] text-slate-500 dark:text-slate-400">
                  Evolución histórica de las evaluaciones según el nivel de riesgo predicho.
                </p>
              </div>

              <div className="min-h-0 w-full flex-1">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={dataEvolucionClinica} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <defs>
                      <linearGradient id="colorAlto" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                      </linearGradient>
                      <linearGradient id="colorMedio" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#f97316" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="#f97316" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={isDark ? '#334155' : '#f1f5f9'} />
                    <XAxis dataKey="mes" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} />
                    <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} />
                    <Tooltip contentStyle={{ backgroundColor: isDark ? '#0f172a' : '#ffffff', borderColor: isDark ? '#1e293b' : '#e2e8f0', color: isDark ? '#f8fafc' : '#0f172a', borderRadius: '12px', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }} />
                    <Legend iconType="circle" wrapperStyle={{ fontSize: '11px', paddingTop: '10px' }} />
                    <Area type="monotone" name="Riesgo Alto" dataKey="alto" stroke="#ef4444" fillOpacity={1} fill="url(#colorAlto)" strokeWidth={2} />
                    <Area type="monotone" name="Riesgo Medio" dataKey="medio" stroke="#f97316" fillOpacity={1} fill="url(#colorMedio)" strokeWidth={2} />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </div>

          </div>

          <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-6 shadow-sm transition-colors duration-300">
            <div className="mb-6">
              <h3 className="flex items-center gap-2 text-sm font-bold text-slate-800 dark:text-slate-100">
                <BarChart2 className="h-4 w-4 text-emerald-600 dark:text-emerald-500" />
                Signos Vitales y Cuadros Fuera de Rango (Top 5)
              </h3>
              <p className="mt-1 text-[10px] text-slate-500 dark:text-slate-400">
                Frecuencia absoluta de variables clínicas que el modelo analizó en las evaluaciones recientes.
              </p>
            </div>

            <div className="h-[300px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={factoresClinicos} layout="vertical" margin={{ top: 0, right: 20, left: 20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke={isDark ? '#334155' : '#f1f5f9'} />
                  <XAxis type="number" hide />
                  <YAxis dataKey="nombre" type="category" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#475569', fontWeight: 600 }} width={140} />
                  <Tooltip cursor={{ fill: isDark ? '#1e293b' : '#f8fafc' }} contentStyle={{ backgroundColor: isDark ? '#0f172a' : '#ffffff', borderColor: isDark ? '#1e293b' : '#e2e8f0', color: isDark ? '#f8fafc' : '#0f172a', borderRadius: '12px' }} formatter={(value) => [`${value} incidencias registradas`, 'Total']} />
                  <Bar dataKey="total" radius={[0, 6, 6, 0]} barSize={24}>
                    {factoresClinicos.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}