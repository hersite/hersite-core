import { useEffect, useMemo, useState } from 'react';
import {
  TrendingUp,
  Activity,
  BarChart2,
  AlertCircle,
  RefreshCw,
  PieChart,
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
    let cancelado = false;

    async function cargarInicial() {
      try {
        const response = await api.getTendenciasResumen();

        if (cancelado) return;

        setData(response);
      } catch (err) {
        console.error(err);

        if (cancelado) return;

        setError(err.message || 'No se pudieron cargar las tendencias.');
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
  const distribucionRiesgo = useMemo(() => {
    const riesgos = data?.riesgos || { bajo: 0, medio: 0, alto: 0 };

    return [
      {
        name: 'Riesgo bajo',
        key: 'bajo',
        value: riesgos.bajo || 0,
        color: '#4C924F',
      },
      {
        name: 'Riesgo medio',
        key: 'medio',
        value: riesgos.medio || 0,
        color: '#f59e0b',
      },
      {
        name: 'Riesgo alto',
        key: 'alto',
        value: riesgos.alto || 0,
        color: '#ef4444',
      },
    ];
  }, [data]);

  const factores = data?.factores_frecuentes || [];
  const tendenciaMensual = data?.tendencia_mensual || [];
  const totalEvaluaciones = data?.total_evaluaciones || 0;
  const totalGestantes = data?.total_gestantes || 0;
  const riesgos = data?.riesgos || { bajo: 0, medio: 0, alto: 0 };

  const porcentajeAlto = calcularPorcentaje(riesgos.alto, totalEvaluaciones);
  const porcentajeMedio = calcularPorcentaje(riesgos.medio, totalEvaluaciones);
  const porcentajeBajo = calcularPorcentaje(riesgos.bajo, totalEvaluaciones);

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-verdeApp" />
          <p className="text-sm font-bold text-slate-700">Cargando tendencias poblacionales...</p>
          <p className="mt-1 text-xs text-slate-400">FastAPI /api/tendencias/resumen</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp p-6">
        <div className="max-w-md rounded-2xl border border-red-200 bg-red-50 p-6 text-center">
          <AlertCircle className="mx-auto mb-3 h-8 w-8 text-red-600" />
          <h2 className="text-sm font-bold text-red-800">No se pudieron cargar las tendencias</h2>
          <p className="mt-2 text-xs text-red-700">{error}</p>
          <button
            onClick={cargarTendencias}
            className="mt-4 rounded-xl bg-red-600 px-4 py-2 text-xs font-bold text-white hover:bg-red-700"
          >
            Reintentar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-full w-full flex-col overflow-hidden bg-fondoApp animate-fade-in">
      <header className="shrink-0 border-b border-slate-200 bg-white px-6 py-4">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="font-serif text-2xl font-bold text-slate-800">
              Análisis Poblacional y Tendencias
            </h2>
            <p className="mt-0.5 text-xs text-slate-500">
              Monitoreo de evaluaciones sincronizadas desde la aplicación móvil offline-first.
            </p>
          </div>

          <button
            onClick={cargarTendencias}
            className="flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50"
          >
            <RefreshCw size={14} />
            Actualizar
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="mx-auto max-w-6xl space-y-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
            <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="rounded-xl bg-green-50 p-3">
                <Activity className="h-6 w-6 text-verdeApp" />
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  Gestantes monitoreadas
                </p>
                <h3 className="text-xl font-bold text-slate-800">{totalGestantes}</h3>
              </div>
            </div>

            <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="rounded-xl bg-slate-100 p-3">
                <BarChart2 className="h-6 w-6 text-slate-700" />
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  Evaluaciones recibidas
                </p>
                <h3 className="text-xl font-bold text-slate-800">{totalEvaluaciones}</h3>
              </div>
            </div>

            <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="rounded-xl bg-amber-50 p-3">
                <TrendingUp className="h-6 w-6 text-amber-600" />
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  Riesgo predominante
                </p>
                <h3 className="text-xl font-bold text-slate-800">
                  {riesgoPredominanteTexto(data?.riesgo_predominante)}
                </h3>
              </div>
            </div>

            <div className="flex items-center gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="rounded-xl bg-red-50 p-3">
                <AlertCircle className="h-6 w-6 text-red-600" />
              </div>
              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  Riesgo alto
                </p>
                <h3 className="text-xl font-bold text-red-600">
                  {riesgos.alto || 0}
                  <span className="ml-1 text-sm font-medium text-slate-500">
                    ({porcentajeAlto}%)
                  </span>
                </h3>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            <div className="flex h-[400px] flex-col rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="mb-4">
                <h3 className="flex items-center gap-2 text-sm font-bold text-slate-800">
                  <TrendingUp className="h-4 w-4 text-verdeApp" />
                  Evolución mensual por nivel de riesgo
                </h3>
                <p className="mt-1 text-[10px] text-slate-400">
                  Conteo de evaluaciones sincronizadas agrupadas por mes.
                </p>
              </div>

              <div className="min-h-0 w-full flex-1">
                {tendenciaMensual.length === 0 ? (
                  <div className="flex h-full items-center justify-center text-xs text-slate-400">
                    Aún no hay suficientes evaluaciones para graficar.
                  </div>
                ) : (
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={tendenciaMensual} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                      <XAxis dataKey="mes" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} />
                      <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} />
                      <Tooltip
                        contentStyle={{
                          borderRadius: '12px',
                          border: 'none',
                          boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                        }}
                        labelStyle={{ fontWeight: 'bold', color: '#0f172a', marginBottom: '4px' }}
                      />
                      <Legend iconType="circle" wrapperStyle={{ fontSize: '11px', paddingTop: '10px' }} />
                      <Line type="monotone" name="Riesgo bajo" dataKey="bajo" stroke="#4C924F" strokeWidth={3} dot={{ r: 4, strokeWidth: 2 }} activeDot={{ r: 6 }} />
                      <Line type="monotone" name="Riesgo medio" dataKey="medio" stroke="#f59e0b" strokeWidth={3} dot={{ r: 4, strokeWidth: 2 }} activeDot={{ r: 6 }} />
                      <Line type="monotone" name="Riesgo alto" dataKey="alto" stroke="#ef4444" strokeWidth={3} dot={{ r: 4, strokeWidth: 2 }} activeDot={{ r: 6 }} />
                    </LineChart>
                  </ResponsiveContainer>
                )}
              </div>
            </div>

            <div className="flex h-[400px] flex-col rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
              <div className="mb-4">
                <h3 className="flex items-center gap-2 text-sm font-bold text-slate-800">
                  <PieChart className="h-4 w-4 text-verdeApp" />
                  Distribución acumulada de riesgo
                </h3>
                <p className="mt-1 text-[10px] text-slate-400">
                  Proporción de evaluaciones por clase predicha por el modelo.
                </p>
              </div>

              <div className="min-h-0 w-full flex-1">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={distribucionRiesgo} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#475569', fontWeight: 600 }} />
                    <YAxis allowDecimals={false} axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} />
                    <Tooltip
                      cursor={{ fill: '#f8fafc' }}
                      contentStyle={{
                        borderRadius: '12px',
                        border: 'none',
                        boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                      }}
                      formatter={(value, name, props) => {
                        const porcentaje = calcularPorcentaje(value, totalEvaluaciones);
                        return [`${value} evaluación(es) · ${porcentaje}%`, props.payload.name];
                      }}
                    />
                    <Bar dataKey="value" radius={[8, 8, 0, 0]} barSize={60}>
                      {distribucionRiesgo.map((entry) => (
                        <Cell key={entry.key} fill={entry.color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>

              <div className="mt-3 grid grid-cols-3 gap-2 text-center">
                <div className="rounded-xl bg-green-50 p-3">
                  <p className="text-lg font-black text-green-700">{porcentajeBajo}%</p>
                  <p className="text-[10px] font-bold uppercase text-green-700">Bajo</p>
                </div>
                <div className="rounded-xl bg-amber-50 p-3">
                  <p className="text-lg font-black text-amber-700">{porcentajeMedio}%</p>
                  <p className="text-[10px] font-bold uppercase text-amber-700">Medio</p>
                </div>
                <div className="rounded-xl bg-red-50 p-3">
                  <p className="text-lg font-black text-red-700">{porcentajeAlto}%</p>
                  <p className="text-[10px] font-bold uppercase text-red-700">Alto</p>
                </div>
              </div>
            </div>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="mb-5">
              <h3 className="flex items-center gap-2 text-sm font-bold text-slate-800">
                <BarChart2 className="h-4 w-4 text-verdeApp" />
                Factores clínicos frecuentes en evaluaciones sincronizadas
              </h3>
              <p className="mt-1 text-[10px] text-slate-400">
                Frecuencia de signos, antecedentes y variables clínicas presentes en los registros recibidos.
              </p>
            </div>

            <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
              <div className="h-[330px]">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={factores} layout="vertical" margin={{ top: 10, right: 20, left: 40, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#f1f5f9" />
                    <XAxis type="number" allowDecimals={false} hide />
                    <YAxis
                      dataKey="factor"
                      type="category"
                      axisLine={false}
                      tickLine={false}
                      tick={{ fontSize: 10, fill: '#475569', fontWeight: 600 }}
                      width={150}
                    />
                    <Tooltip
                      cursor={{ fill: '#f8fafc' }}
                      contentStyle={{
                        borderRadius: '12px',
                        border: 'none',
                        boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                      }}
                      formatter={(value, name, props) => [
                        `${value} registro(s) · ${props.payload.porcentaje}%`,
                        'Frecuencia',
                      ]}
                    />
                    <Bar dataKey="total" radius={[0, 6, 6, 0]} barSize={22}>
                      {factores.map((entry, index) => (
                        <Cell
                          key={entry.factor}
                          fill={index === 0 ? '#ef4444' : index === 1 ? '#f59e0b' : '#4C924F'}
                        />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>

              <div className="space-y-3">
                {factores.map((item, index) => (
                  <div key={item.factor} className="rounded-xl border border-slate-100 bg-slate-50 p-4">
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <p className="text-xs font-bold text-slate-800">
                          {index + 1}. {item.factor}
                        </p>
                        <p className="mt-1 text-[10px] text-slate-400">
                          Presente en {item.total} evaluación(es) sincronizada(s).
                        </p>
                      </div>

                      <div className="text-right">
                        <p className="text-lg font-black text-verdeOscuro">{item.porcentaje}%</p>
                        <p className="text-[10px] font-bold uppercase text-slate-400">frecuencia</p>
                      </div>
                    </div>

                    <div className="mt-3 h-2 w-full rounded-full bg-white">
                      <div
                        className="h-2 rounded-full bg-verdeApp"
                        style={{ width: `${Math.min(item.porcentaje, 100)}%` }}
                      ></div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="text-center">
            <p className="text-[10px] font-semibold uppercase tracking-widest text-slate-400">
              Modelo predictivo: LightGBM embebido en Flutter · Backend: FastAPI · Datos sincronizados desde app offline-first
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}