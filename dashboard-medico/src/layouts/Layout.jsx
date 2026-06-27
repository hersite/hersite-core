import { useEffect, useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  AlertTriangle,
  CloudSync,
  LogOut,
  Settings,
  TrendingUp,
  Users,
} from 'lucide-react';

import logoTesis from '../assets/logo_tesis.png';
import { api } from '../services/api';
import { cerrarSesionWeb, obtenerSesionWeb } from '../services/auth';

export default function Layout() {
  const navigate = useNavigate();

  const [estadoSistema, setEstadoSistema] = useState(null);
  const [apiOnline, setApiOnline] = useState(false);

  const session = obtenerSesionWeb();

  const cerrarSesion = () => {
    cerrarSesionWeb();
    navigate('/', { replace: true });
  };

  useEffect(() => {
    let cancelado = false;

    async function cargarEstado() {
      try {
        const response = await api.getSistemaEstado();

        if (cancelado) return;

        setEstadoSistema(response);
        setApiOnline(true);
      } catch (err) {
        console.error(err);

        if (cancelado) return;

        setApiOnline(false);
      }
    }

    cargarEstado();

    const intervalId = window.setInterval(() => {
      cargarEstado();
    }, 30000);

    return () => {
      cancelado = true;
      window.clearInterval(intervalId);
    };
  }, []);

  const totalEvaluaciones = estadoSistema?.resumen?.total_evaluaciones ?? 0;
  const totalGestantes = estadoSistema?.resumen?.total_gestantes ?? 0;
  const totalAlto = estadoSistema?.resumen?.riesgos?.alto ?? 0;

  return (
    <div className="flex h-screen bg-slate-50 font-sans text-slate-800">
      <aside className="z-20 flex w-56 shrink-0 flex-col border-r border-slate-200 bg-white">
        <div className="flex items-center gap-2 border-b border-slate-100 p-4">
          <img
            src={logoTesis}
            alt="logo_tesis"
            className="h-8 w-8 rounded-lg border border-slate-100 object-contain p-0.5"
          />
          <div>
            <h1 className="text-sm font-bold leading-tight text-slate-900">hersite</h1>
            <p className="text-[10px] text-slate-400">Plataforma de Monitoreo</p>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-3">
          <p className="mb-2 ml-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">
            Monitoreo
          </p>

          <NavLink
            to="/dashboard"
            className={({ isActive }) =>
              `mb-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-xs font-semibold transition-colors ${
                isActive ? 'bg-green-50 text-green-800' : 'text-slate-500 hover:bg-slate-100'
              }`
            }
          >
            <AlertTriangle size={16} /> Panel de Triaje
          </NavLink>

          <NavLink
            to="/gestantes"
            className={({ isActive }) =>
              `mb-1 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-xs font-semibold transition-colors ${
                isActive ? 'bg-green-50 text-green-800' : 'text-slate-500 hover:bg-slate-100'
              }`
            }
          >
            <Users size={16} /> Gestantes
          </NavLink>

          <NavLink
            to="/tendencias"
            className={({ isActive }) =>
              `mb-4 flex w-full items-center gap-3 rounded-lg px-3 py-2 text-xs font-semibold transition-colors ${
                isActive ? 'bg-green-50 text-green-800' : 'text-slate-500 hover:bg-slate-100'
              }`
            }
          >
            <TrendingUp size={16} /> Tendencias
          </NavLink>

          <p className="mb-2 ml-2 text-[10px] font-bold uppercase tracking-wider text-slate-400">
            Gestión
          </p>

          <NavLink
            to="/configuracion"
            className={({ isActive }) =>
              `flex w-full items-center gap-3 rounded-lg px-3 py-2 text-xs font-semibold transition-colors ${
                isActive ? 'bg-green-50 text-green-800' : 'text-slate-500 hover:bg-slate-100'
              }`
            }
          >
            <Settings size={16} /> Configuración
          </NavLink>
        </div>

        <div className="mx-3 mb-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5">
          <div className="mb-1.5 flex items-center justify-between">
            <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500">
              Sistema
            </span>
            <CloudSync
              size={14}
              className={apiOnline ? 'text-verdeApp' : 'text-red-500'}
            />
          </div>

          <div className="flex items-center gap-1.5">
            <span
              className={`h-1.5 w-1.5 rounded-full ${
                apiOnline ? 'animate-pulse bg-green-500' : 'bg-red-500'
              }`}
            ></span>
            <span className="text-xs font-bold text-slate-700">
              {apiOnline ? 'Online' : 'Offline'}
            </span>
          </div>

          <div className="mt-2 grid grid-cols-3 gap-1 text-center">
            <div className="rounded-lg bg-white p-1.5">
              <p className="text-[10px] font-black text-slate-800">{totalGestantes}</p>
              <p className="text-[8px] font-bold uppercase text-slate-400">Gest.</p>
            </div>

            <div className="rounded-lg bg-white p-1.5">
              <p className="text-[10px] font-black text-slate-800">{totalEvaluaciones}</p>
              <p className="text-[8px] font-bold uppercase text-slate-400">Eval.</p>
            </div>

            <div className="rounded-lg bg-white p-1.5">
              <p className="text-[10px] font-black text-red-600">{totalAlto}</p>
              <p className="text-[8px] font-bold uppercase text-slate-400">Alto</p>
            </div>
          </div>
        </div>

        <div className="flex flex-col gap-3 border-t border-slate-100 p-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-green-100 text-xs font-bold text-green-800">
              MQ
            </div>

            <div>
              <p className="text-xs font-bold text-slate-700">
                {session?.nombre || 'Personal de salud'}
              </p>
              <p className="text-[10px] text-slate-400">
                {session?.rol || 'Usuario clínico'}
              </p>
            </div>
          </div>

          <button
            onClick={cerrarSesion}
            className="mt-1 flex w-full items-center justify-center gap-2 rounded-lg bg-red-50 px-3 py-2 text-xs font-medium text-red-600 transition-colors hover:bg-red-100"
          >
            <LogOut size={14} /> Cerrar sesión
          </button>
        </div>
      </aside>

      <main className="relative flex min-w-0 flex-1 flex-col overflow-hidden">
        <Outlet />
      </main>
    </div>
  );
}