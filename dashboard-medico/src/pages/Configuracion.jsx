import React from 'react';
import { User, Phone, ShieldCheck, Save, Activity, Server, Database } from 'lucide-react';

export default function Configuracion() {
  return (
    <>
      <header className="bg-white border-b border-slate-200 px-6 py-4 shrink-0">
        <h2 className="text-lg font-bold text-slate-800">Configuración del Perfil</h2>
        <p className="text-xs text-slate-500">Gestione sus datos personales y credenciales de acceso local.</p>
      </header>

      <div className="flex-1 overflow-y-auto p-6 bg-slate-50">
        <div className="max-w-3xl mx-auto space-y-6">
          
          {/* 1. Tarjeta de Perfil */}
          <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
            <h3 className="text-sm font-bold text-slate-800 mb-5 flex items-center gap-2">
              <User className="text-verdeApp w-5 h-5" /> Información Personal
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">Nombre Completo</label>
                <input type="text" defaultValue="Dra. María Quispe" className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-sm text-slate-800 font-medium" />
              </div>
              
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">DNI (No editable)</label>
                <input type="text" defaultValue="45879632" disabled className="w-full px-4 py-2.5 bg-slate-100 border border-slate-200 rounded-xl text-sm text-slate-400 font-medium cursor-not-allowed" />
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">Código CMP</label>
                <input type="text" defaultValue="084512" className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-sm text-slate-800 font-medium" />
              </div>

              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">Teléfono de Contacto</label>
                <div className="relative">
                  <Phone className="absolute left-3.5 top-3 w-4 h-4 text-slate-400" />
                  <input type="tel" defaultValue="987654321" className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-sm text-slate-800 font-medium" />
                </div>
              </div>
            </div>
          </div>

          {/* 2. Tarjeta de Seguridad */}
          <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
            <h3 className="text-sm font-bold text-slate-800 mb-5 flex items-center gap-2">
              <ShieldCheck className="text-verdeApp w-5 h-5" /> Seguridad y Acceso
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">Nuevo PIN de Acceso (6 dígitos)</label>
                <input type="password" placeholder="••••••" maxLength={6} className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-sm tracking-widest text-slate-800 font-bold" />
              </div>
              
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">Confirmar Nuevo PIN</label>
                <input type="password" placeholder="••••••" maxLength={6} className="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-sm tracking-widest text-slate-800 font-bold" />
              </div>
            </div>
          </div>

          {/* 3. Tarjeta de Estado del Sistema (Reducida a 2 columnas) */}
          <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
            <h3 className="text-sm font-bold text-slate-800 mb-5 flex items-center gap-2">
              <Activity className="text-verdeApp w-5 h-5" /> Estado del Servidor
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              
              {/* API Central */}
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-4 flex flex-col justify-between">
                <div className="flex justify-between items-start mb-4">
                  <div className="bg-white p-2 rounded-lg shadow-sm border border-slate-100">
                    <Server className="w-5 h-5 text-slate-600" />
                  </div>
                  <span className="flex items-center gap-1.5 bg-green-100 border border-green-200 text-green-700 px-2 py-1 rounded-full text-[10px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span> En línea
                  </span>
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-800">API Central</p>
                  <p className="text-[10px] text-slate-500">Servidor FastAPI activo</p>
                </div>
              </div>

              {/* Base de Datos */}
              <div className="bg-slate-50 border border-slate-100 rounded-xl p-4 flex flex-col justify-between">
                <div className="flex justify-between items-start mb-4">
                  <div className="bg-white p-2 rounded-lg shadow-sm border border-slate-100">
                    <Database className="w-5 h-5 text-slate-600" />
                  </div>
                  <span className="flex items-center gap-1.5 bg-green-100 border border-green-200 text-green-700 px-2 py-1 rounded-full text-[10px] font-bold">
                    <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span> Conectada
                  </span>
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-800">Base de Datos</p>
                  <p className="text-[10px] text-slate-500">PostgreSQL Cloud</p>
                </div>
              </div>

            </div>
          </div>

          {/* Botón de Guardado */}
          <div className="flex justify-end pt-2 pb-6">
            <button className="bg-verdeApp hover:bg-verdeOscuro text-white font-bold py-3 px-6 rounded-xl shadow-md shadow-green-900/10 transition-all flex items-center gap-2 text-sm">
              <Save size={18} /> Guardar Cambios
            </button>
          </div>

        </div>
      </div>
    </>
  );
}