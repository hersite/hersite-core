import { useEffect, useMemo, useState } from 'react';
import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  Database,
  Globe2,
  Link as LinkIcon,
  RefreshCw,
  Server,
  Settings,
  ShieldCheck,
  Smartphone,
} from 'lucide-react';

import { api } from '../services/api';

function formatearFecha(fechaIso) {
  if (!fechaIso) return 'Sin fecha';

  try {
    const fecha = new Date(fechaIso);

    if (Number.isNaN(fecha.getTime())) {
      return fechaIso;
    }

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
}

function EstadoBadge({ estado = 'online' }) {
  const activo = estado === 'online' || estado === 'conectado';

  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[10px] font-bold uppercase ${
        activo
          ? 'border border-green-200 bg-green-50 text-green-700'
          : 'border border-red-200 bg-red-50 text-red-700'
      }`}
    >
      <span
        className={`h-1.5 w-1.5 rounded-full ${
          activo ? 'bg-green-500' : 'bg-red-500'
        }`}
      ></span>
      {estado}
    </span>
  );
}

function CardEstado({ icon: Icon, title, subtitle, children }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex items-center gap-3">
        <div className="rounded-xl bg-green-50 p-3">
          <Icon className="h-5 w-5 text-verdeApp" />
        </div>
        <div>
          <h3 className="text-sm font-bold text-slate-800">{title}</h3>
          <p className="mt-0.5 text-[10px] font-medium text-slate-400">{subtitle}</p>
        </div>
      </div>

      {children}
    </div>
  );
}

export default function Configuracion() {
  const [estado, setEstado] = useState(null);
  const [loading, setLoading] = useState(true);
  const [actualizando, setActualizando] = useState(false);
  const [error, setError] = useState(null);

  const cargarEstadoSistema = async () => {
    setActualizando(true);
    setError(null);

    try {
      const response = await api.getSistemaEstado();
      setEstado(response);
    } catch (err) {
      console.error(err);
      setError(err.message || 'No se pudo cargar el estado del sistema.');
    } finally {
      setLoading(false);
      setActualizando(false);
    }
  };

  useEffect(() => {
    let cancelado = false;

    async function cargarInicial() {
      try {
        const response = await api.getSistemaEstado();

        if (cancelado) return;

        setEstado(response);
      } catch (err) {
        console.error(err);

        if (cancelado) return;

        setError(err.message || 'No se pudo cargar el estado del sistema.');
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

  const endpoints = estado?.endpoints || [];
  const resumen = estado?.resumen || {};
  const riesgos = resumen?.riesgos || { bajo: 0, medio: 0, alto: 0 };
  const ultimaEvaluacion = resumen?.ultima_evaluacion;

  const totalPendienteMigracion = useMemo(() => {
    return estado?.database?.migracion_pendiente || 'Sin migración pendiente';
  }, [estado]);

  if (loading) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp">
        <div className="text-center">
          <RefreshCw className="mx-auto mb-3 h-8 w-8 animate-spin text-verdeApp" />
          <p className="text-sm font-bold text-slate-700">Cargando configuración del sistema...</p>
          <p className="mt-1 text-xs text-slate-400">FastAPI /api/sistema/estado</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex h-full w-full items-center justify-center bg-fondoApp p-6">
        <div className="max-w-md rounded-2xl border border-red-200 bg-red-50 p-6 text-center">
          <AlertTriangle className="mx-auto mb-3 h-8 w-8 text-red-600" />
          <h2 className="text-sm font-bold text-red-800">No se pudo cargar la configuración</h2>
          <p className="mt-2 text-xs text-red-700">{error}</p>
          <button
            onClick={cargarEstadoSistema}
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
              Configuración y Estado del Sistema
            </h2>
            <p className="mt-0.5 text-xs text-slate-500">
              Monitoreo técnico de la arquitectura Flutter offline-first, FastAPI y dashboard web.
            </p>
          </div>

          <button
            onClick={cargarEstadoSistema}
            disabled={actualizando}
            className="flex items-center gap-1.5 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <RefreshCw size={14} className={actualizando ? 'animate-spin' : ''} />
            Actualizar
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto p-6">
        <div className="mx-auto max-w-6xl space-y-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-4">
            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">API</p>
                  <h3 className="mt-1 text-xl font-black text-slate-800">FastAPI</h3>
                </div>
                <Server className="h-7 w-7 text-verdeApp" />
              </div>
              <div className="mt-4">
                <EstadoBadge estado={estado?.api?.status} />
              </div>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Gestantes</p>
                  <h3 className="mt-1 text-xl font-black text-slate-800">
                    {resumen.total_gestantes ?? 0}
                  </h3>
                </div>
                <Activity className="h-7 w-7 text-verdeApp" />
              </div>
              <p className="mt-4 text-[10px] font-semibold text-slate-400">
                Registros centrales
              </p>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Evaluaciones</p>
                  <h3 className="mt-1 text-xl font-black text-slate-800">
                    {resumen.total_evaluaciones ?? 0}
                  </h3>
                </div>
                <CheckCircle2 className="h-7 w-7 text-verdeApp" />
              </div>
              <p className="mt-4 text-[10px] font-semibold text-slate-400">
                Sincronizadas desde Flutter
              </p>
            </div>

            <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">Riesgo alto</p>
                  <h3 className="mt-1 text-xl font-black text-red-600">
                    {riesgos.alto ?? 0}
                  </h3>
                </div>
                <AlertTriangle className="h-7 w-7 text-red-500" />
              </div>
              <p className="mt-4 text-[10px] font-semibold text-slate-400">
                Evaluaciones críticas recibidas
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            <CardEstado
              icon={Server}
              title="Backend central"
              subtitle="Servicio API responsable de recibir evaluaciones móviles"
            >
              <div className="space-y-3 text-xs">
                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Servicio</span>
                  <span className="font-bold text-slate-800">{estado?.api?.service}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Versión</span>
                  <span className="font-bold text-slate-800">{estado?.api?.version}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Estado</span>
                  <EstadoBadge estado={estado?.api?.status} />
                </div>

                <div className="flex justify-between">
                  <span className="font-medium text-slate-500">Última consulta</span>
                  <span className="font-bold text-slate-800">
                    {formatearFecha(estado?.api?.timestamp)}
                  </span>
                </div>
              </div>
            </CardEstado>

            <CardEstado
              icon={Database}
              title="Base de datos central"
              subtitle="Persistencia actual usada por FastAPI"
            >
              <div className="space-y-3 text-xs">
                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Motor actual</span>
                  <span className="font-bold text-slate-800">{estado?.database?.motor}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Modo</span>
                  <span className="font-bold text-slate-800">{estado?.database?.modo}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Archivo</span>
                  <span className="font-mono text-[11px] font-bold text-slate-800">
                    {estado?.database?.archivo}
                  </span>
                </div>

                <div className="flex justify-between">
                  <span className="font-medium text-slate-500">Siguiente mejora</span>
                  <span className="font-bold text-amber-600">{totalPendienteMigracion}</span>
                </div>
              </div>
            </CardEstado>

            <CardEstado
              icon={Smartphone}
              title="Aplicación móvil"
              subtitle="Módulo offline-first usado por gestantes"
            >
              <div className="space-y-3 text-xs">
                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Origen</span>
                  <span className="font-bold text-slate-800">{estado?.mobile?.origen}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Modelo</span>
                  <span className="font-bold text-slate-800">{estado?.mobile?.modelo}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Almacenamiento</span>
                  <span className="font-bold text-slate-800">{estado?.mobile?.almacenamiento_local}</span>
                </div>

                <div className="flex justify-between">
                  <span className="font-medium text-slate-500">Sincronización</span>
                  <span className="font-bold text-verdeOscuro">{estado?.mobile?.sincronizacion}</span>
                </div>
              </div>
            </CardEstado>

            <CardEstado
              icon={Globe2}
              title="Dashboard web"
              subtitle="Interfaz de monitoreo para personal de salud"
            >
              <div className="space-y-3 text-xs">
                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Framework</span>
                  <span className="font-bold text-slate-800">{estado?.web?.framework}</span>
                </div>

                <div className="flex justify-between border-b border-slate-100 pb-2">
                  <span className="font-medium text-slate-500">Estado</span>
                  <span className="font-bold text-verdeOscuro">{estado?.web?.estado}</span>
                </div>

                <div className="rounded-xl border border-green-100 bg-green-50 p-3">
                  <p className="flex items-center gap-2 text-xs font-bold text-green-700">
                    <ShieldCheck size={14} />
                    Consumiendo datos reales desde FastAPI
                  </p>
                </div>
              </div>
            </CardEstado>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="mb-5 flex items-center justify-between gap-4">
              <div>
                <h3 className="flex items-center gap-2 text-sm font-bold text-slate-800">
                  <Settings className="h-4 w-4 text-verdeApp" />
                  Resumen de sincronización
                </h3>
                <p className="mt-1 text-[10px] text-slate-400">
                  Última evaluación recibida por el servidor central.
                </p>
              </div>
            </div>

            {ultimaEvaluacion ? (
              <div className="rounded-xl border border-slate-100 bg-slate-50 p-4">
                <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
                  <div>
                    <p className="text-sm font-bold text-slate-800">
                      {ultimaEvaluacion.gestante?.nombre || 'Gestante sin nombre'}
                    </p>
                    <p className="mt-1 text-xs text-slate-500">
                      DNI: {ultimaEvaluacion.gestante?.dni || '--'} · {ultimaEvaluacion.nivel_riesgo_legible}
                    </p>
                    <p className="mt-1 text-[10px] text-slate-400">
                      Fecha de evaluación: {formatearFecha(ultimaEvaluacion.fecha_hora)}
                    </p>
                  </div>

                  <div className="text-left md:text-right">
                    <p className="font-mono text-[10px] font-bold text-slate-500">
                      {ultimaEvaluacion.server_id}
                    </p>
                    <p className="mt-1 inline-flex items-center gap-1 rounded-full border border-green-200 bg-green-50 px-2.5 py-1 text-[10px] font-bold text-green-700">
                      <CheckCircle2 size={13} />
                      {ultimaEvaluacion.estado_servidor}
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="rounded-xl border border-slate-100 bg-slate-50 p-4 text-xs text-slate-500">
                Todavía no hay evaluaciones recibidas por el servidor.
              </div>
            )}
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="mb-5">
              <h3 className="flex items-center gap-2 text-sm font-bold text-slate-800">
                <LinkIcon className="h-4 w-4 text-verdeApp" />
                Endpoints activos
              </h3>
              <p className="mt-1 text-[10px] text-slate-400">
                Rutas expuestas por FastAPI para Flutter y React.
              </p>
            </div>

            <div className="overflow-hidden rounded-xl border border-slate-200">
              <table className="w-full border-collapse text-left">
                <thead className="border-b border-slate-200 bg-slate-50">
                  <tr>
                    <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      Método
                    </th>
                    <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      Ruta
                    </th>
                    <th className="px-4 py-3 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      Descripción
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-100">
                  {endpoints.map((endpoint) => (
                    <tr key={`${endpoint.method}-${endpoint.path}`} className="hover:bg-slate-50">
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-md px-2 py-1 font-mono text-[10px] font-bold ${
                            endpoint.method === 'POST'
                              ? 'bg-amber-50 text-amber-700'
                              : 'bg-green-50 text-green-700'
                          }`}
                        >
                          {endpoint.method}
                        </span>
                      </td>

                      <td className="px-4 py-3 font-mono text-[11px] font-bold text-slate-700">
                        {endpoint.path}
                      </td>

                      <td className="px-4 py-3 text-xs text-slate-500">
                        {endpoint.descripcion}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="text-center">
            <p className="text-[10px] font-semibold uppercase tracking-widest text-slate-400">
              Arquitectura activa: Flutter offline-first · SQLCipher local · FastAPI · SQLite central de desarrollo · React dashboard
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}