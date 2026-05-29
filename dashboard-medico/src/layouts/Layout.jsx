import React from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { Users, AlertTriangle, TrendingUp, Settings, LogOut, CloudSync } from 'lucide-react';
import logoTesis from '../assets/logo_tesis.png';

export default function Layout() {
  const navigate = useNavigate();

  const cerrarSesion = () => {
    navigate('/');
  };

  return (
    <div className="flex h-screen bg-slate-50 font-sans text-slate-800">
      
      {/* SIDEBAR COMPACTO */}
      <aside className="w-56 bg-white border-r border-slate-200 flex flex-col shrink-0 z-20">
        <div className="p-4 border-b border-slate-100 flex items-center gap-2">
          <img 
            src={logoTesis} 
            alt="logo_tesis" 
            className="w-8 h-8 object-contain rounded-lg border border-slate-100 p-0.5" 
          />
          <div>
            <h1 className="text-sm font-bold text-slate-900 leading-tight">hersite</h1>
            <p className="text-[10px] text-slate-400">Plataforma de Monitoreo</p>
          </div>
        </div>

        <div className="p-3 flex-1 overflow-y-auto">
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2 ml-2">Monitoreo</p>
          
          <NavLink to="/dashboard" className={({isActive}) => `w-full flex items-center gap-3 px-3 py-2 rounded-lg font-semibold text-xs mb-1 transition-colors ${isActive ? 'bg-green-50 text-green-800' : 'hover:bg-slate-100 text-slate-500'}`}>
            <AlertTriangle size={16}/> Panel de Triaje
          </NavLink>
          
          <NavLink to="/gestantes" className={({isActive}) => `w-full flex items-center gap-3 px-3 py-2 rounded-lg font-semibold text-xs mb-1 transition-colors ${isActive ? 'bg-green-50 text-green-800' : 'hover:bg-slate-100 text-slate-500'}`}>
            <Users size={16}/> Gestantes
          </NavLink>

          <NavLink to="/tendencias" className={({isActive}) => `w-full flex items-center gap-3 px-3 py-2 rounded-lg font-semibold text-xs mb-4 transition-colors ${isActive ? 'bg-green-50 text-green-800' : 'hover:bg-slate-100 text-slate-500'}`}>
            <TrendingUp size={16}/> Tendencias
          </NavLink>

          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2 ml-2">Gestión</p>
          
          <NavLink to="/configuracion" className={({isActive}) => `w-full flex items-center gap-3 px-3 py-2 rounded-lg font-semibold text-xs transition-colors ${isActive ? 'bg-green-50 text-green-800' : 'hover:bg-slate-100 text-slate-500'}`}>
            <Settings size={16}/> Configuración
          </NavLink>
        </div>

        {/* NUEVO WIDGET GLOBAL DE SINCRONIZACIÓN */}
        <div className="mx-3 mb-2 px-3 py-2.5 bg-slate-50 border border-slate-200 rounded-xl">
          <div className="flex items-center justify-between mb-1.5">
            <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">Sincronización</span>
            <CloudSync size={14} className="text-verdeApp" />
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span>
            <span className="text-xs font-bold text-slate-700">0 pendientes</span>
          </div>
        </div>

        {/* FOOTER DEL MENÚ CON BOTÓN DE CERRAR SESIÓN */}
        <div className="p-4 border-t border-slate-100 flex flex-col gap-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-green-100 text-green-800 flex items-center justify-center text-xs font-bold">MQ</div>
            <div>
              <p className="text-xs font-bold text-slate-700">Dra. M. Quispe</p>
              <p className="text-[10px] text-slate-400">Médico encargado</p>
            </div>
          </div>
          
          <button 
            onClick={cerrarSesion}
            className="w-full flex items-center justify-center gap-2 px-3 py-2 bg-red-50 text-red-600 hover:bg-red-100 rounded-lg font-medium text-xs transition-colors mt-1"
          >
            <LogOut size={14} /> Cerrar sesión
          </button>
        </div>
      </aside>

      {/* CONTENEDOR PRINCIPAL */}
      <main className="flex-1 flex flex-col min-w-0 overflow-hidden relative">
        <Outlet /> 
      </main>
      
    </div>
  );
}