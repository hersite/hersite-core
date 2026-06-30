import { useEffect, useState } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  AlertTriangle,
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
  const session = obtenerSesionWeb() || { nombre: 'Usuario Clínico', rol: 'medico' };

  const cerrarSesion = () => {
    cerrarSesionWeb();
    navigate('/', { replace: true });
  };

  const getInitials = (name) => {
    if (!name) return 'U';
    return name.replace('Dra. ', '').replace('Dr. ', '').trim().charAt(0).toUpperCase();
  };

  useEffect(() => {
    let cancelado = false;

    async function cargarEstado() {
      try {
        const response = await api.getSistemaEstado();
        if (cancelado) return;
        setEstadoSistema(response);
      } catch (err) {
        if (cancelado) return;
        console.error("Error al cargar el estado:", err); 
      }
    }

    cargarEstado();
    const intervalId = window.setInterval(cargarEstado, 30000);

    return () => {
      cancelado = true;
      window.clearInterval(intervalId);
    };
  }, []);

  const totalEvaluaciones = estadoSistema?.resumen?.total_evaluaciones ?? 0;
  const totalGestantes = estadoSistema?.resumen?.total_gestantes ?? 0;
  const totalAlto = estadoSistema?.resumen?.riesgos?.alto ?? 0;

  return (
    <div className="flex h-screen bg-fondoApp dark:bg-slate-950 font-sans text-slate-800 dark:text-slate-100 transition-colors duration-300">
      
      {/* SIDEBAR */}
      <aside className="z-20 flex w-60 shrink-0 flex-col border-r border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 transition-colors duration-300 shadow-[2px_0_8px_-4px_rgba(0,0,0,0.05)] dark:shadow-none">
        
        {/* LOGO AREA */}
        <div className="flex h-[72px] shrink-0 items-center gap-3 px-5 border-b border-slate-100 dark:border-slate-800/60">
          <img
            src={logoTesis}
            alt="logo_tesis"
            className="h-8 w-8 rounded-lg border border-slate-200 dark:border-slate-700 bg-white object-contain p-0.5 shadow-sm"
          />
          <div>
            <h1 className="text-sm font-black tracking-tight text-slate-900 dark:text-white">hersite</h1>
            <p className="text-[10px] font-medium text-slate-500 dark:text-slate-400">Triaje Materno</p>
          </div>
        </div>

        {/* NAVEGACIÓN */}
        <div className="flex-1 overflow-y-auto px-3 py-5">
          <p className="mb-2.5 ml-2 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
            Monitoreo
          </p>

          <nav className="space-y-1">
            <NavLink
              to="/dashboard"
              className={({ isActive }) =>
                `group flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-xs font-semibold transition-all ${
                  isActive 
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400' 
                    : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-slate-300'
                }`
              }
            >
              <div className="flex items-center gap-3">
                <AlertTriangle size={16} /> 
                <span>Panel de Triaje</span>
              </div>
              
                <span className={`flex h-5 min-w-[20px] px-1 items-center justify-center rounded-md text-[10px] font-bold transition-colors ${
                totalAlto > 0 
                ? 'bg-red-100 dark:bg-red-500/20 text-red-600 dark:text-red-400' 
                : 'bg-slate-100 dark:bg-slate-800 text-slate-400 dark:text-slate-500'
                }`}>
                {totalAlto}
                </span>
              
            </NavLink>

            <NavLink
              to="/gestantes"
              className={({ isActive }) =>
                `group flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-xs font-semibold transition-all ${
                  isActive 
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400' 
                    : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-slate-300'
                }`
              }
            >
              <div className="flex items-center gap-3">
                <Users size={16} /> 
                <span>Gestantes</span>
              </div>
              <span className="flex h-5 min-w-[22px] items-center justify-center rounded-md bg-slate-200/70 dark:bg-slate-700/80 px-1.5 text-[10px] font-bold text-slate-700 dark:text-slate-200 transition-colors group-hover:bg-slate-200 dark:group-hover:bg-slate-700">
                {totalGestantes}
              </span>
            </NavLink>

            <NavLink
              to="/tendencias"
              className={({ isActive }) =>
                `group mb-6 flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-xs font-semibold transition-all ${
                  isActive 
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400' 
                    : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-slate-300'
                }`
              }
            >
              <div className="flex items-center gap-3">
                <TrendingUp size={16} /> 
                <span>Tendencias</span>
              </div>
            </NavLink>
          </nav>

          <p className="mb-2.5 ml-2 mt-6 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
            Gestión
          </p>

          <nav className="space-y-1">
            <NavLink
              to="/configuracion"
              className={({ isActive }) =>
                `group flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-xs font-semibold transition-all ${
                  isActive 
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-400' 
                    : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-slate-300'
                }`
              }
            >
              <div className="flex items-center gap-3">
                <Settings size={16} /> 
                <span>Configuración</span>
              </div>
            </NavLink>
          </nav>
        </div>

        {/* ÁREA INFERIOR: RESUMEN Y PERFIL */}
        <div className="shrink-0 border-t border-slate-100 dark:border-slate-800/60 p-4">
          <div className="mb-4 rounded-xl border border-slate-200 dark:border-slate-700/50 bg-slate-50 dark:bg-slate-800/40 p-2.5 transition-colors">
            <p className="mb-2.5 px-1 text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Resumen Activo
            </p>
            <div className="grid grid-cols-3 gap-2 text-center">
              <div className="rounded-lg border border-slate-100 dark:border-slate-700/50 bg-white dark:bg-slate-900 p-1.5 shadow-sm transition-colors">
                <p className="text-[11px] font-black text-slate-800 dark:text-slate-100">{totalGestantes}</p>
                <p className="text-[8px] font-bold uppercase text-slate-400 dark:text-slate-500">Gest.</p>
              </div>
              <div className="rounded-lg border border-slate-100 dark:border-slate-700/50 bg-white dark:bg-slate-900 p-1.5 shadow-sm transition-colors">
                <p className="text-[11px] font-black text-slate-800 dark:text-slate-100">{totalEvaluaciones}</p>
                <p className="text-[8px] font-bold uppercase text-slate-400 dark:text-slate-500">Eval.</p>
              </div>
              <div className="rounded-lg border border-red-100 dark:border-red-900/30 bg-white dark:bg-slate-900 p-1.5 shadow-sm transition-colors">
                <p className="text-[11px] font-black text-red-600 dark:text-red-500">{totalAlto}</p>
                <p className="text-[8px] font-bold uppercase text-red-500 dark:text-red-500/70">Alto</p>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-xs font-bold text-emerald-700 dark:text-emerald-400">
                {getInitials(session.nombre)}
              </div>
              <div className="overflow-hidden">
                <p className="truncate text-xs font-bold text-slate-700 dark:text-slate-200">
                  {session.nombre}
                </p>
                <p className="truncate text-[10px] font-medium text-slate-400 dark:text-slate-500 capitalize">
                  {session.rol === 'medico' ? 'Obstetra' : session.rol }
                </p>
              </div>
            </div>

            <button
              onClick={cerrarSesion}
              title="Cerrar Sesión"
              className="flex shrink-0 items-center justify-center rounded-lg p-2 text-slate-400 hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-500/10 dark:hover:text-red-400 transition-colors"
            >
              <LogOut size={16} />
            </button>
          </div>
        </div>
      </aside>

      {/* ÁREA PRINCIPAL */}
      <main className="relative flex min-w-0 flex-1 flex-col overflow-hidden bg-fondoApp dark:bg-slate-950 transition-colors duration-300">
        <Outlet />
      </main>

    </div>
  );
}