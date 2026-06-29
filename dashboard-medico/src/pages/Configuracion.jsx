import { useState, useEffect } from 'react';
import {
  AlertTriangle,
  Building,
  CheckCircle2,
  Eye,
  EyeOff,
  KeyRound,
  Moon,
  Sun,
  Volume2,
} from 'lucide-react';

import { obtenerSesionWeb } from '../services/auth';

export default function Configuracion() {
  const [tema, setTema] = useState(localStorage.getItem('theme') || 'claro');
  const [alertaSonora, setAlertaSonora] = useState(localStorage.getItem('alertaSonora') !== 'false');
  const [polling, setPolling] = useState(localStorage.getItem('polling') || '30');
  
  const [passwords, setPasswords] = useState({ actual: '', nueva: '', repetir: '' });
  const [verPass, setVerPass] = useState(false);
  const [passStatus, setPassStatus] = useState(null);

  const sesionActual = obtenerSesionWeb() || { 
    nombre: 'Dra. Rocio Tordoya', 
    correo: 'rtordoya@minsa.gob.pe', 
    rol: 'medico' 
  };

  const cambiarTema = (nuevoTema) => {
    setTema(nuevoTema);
    localStorage.setItem('theme', nuevoTema);
    
    if (nuevoTema === 'oscuro') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  useEffect(() => {
    localStorage.setItem('alertaSonora', alertaSonora);
  }, [alertaSonora]);

  useEffect(() => {
    localStorage.setItem('polling', polling);
  }, [polling]);

  const handlePasswordSubmit = (e) => {
    e.preventDefault();
    if (!passwords.actual || !passwords.nueva) {
      setPassStatus({ type: 'err', msg: 'Completa todos los campos.' });
      return;
    }
    if (passwords.nueva.length < 6) {
      setPassStatus({ type: 'err', msg: 'Mínimo 6 caracteres.' });
      return;
    }
    if (passwords.nueva !== passwords.repetir) {
      setPassStatus({ type: 'err', msg: 'Las contraseñas no coinciden.' });
      return;
    }

    setPassStatus({ type: 'ok', msg: 'Contraseña actualizada correctamente.' });
    setPasswords({ actual: '', nueva: '', repetir: '' });
    setTimeout(() => setPassStatus(null), 4000);
  };

  // Función segura para obtener iniciales
  const getInitials = (name) => {
    if (!name) return 'U';
    return name.replace('Dra. ', '').replace('Dr. ', '').trim().charAt(0).toUpperCase();
  };

  return (
    <div className="flex h-full w-full flex-col overflow-hidden bg-slate-50 dark:bg-slate-950 animate-fade-in transition-colors duration-300">
      
      {/* HEADER */}
      <header className="shrink-0 border-b border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 px-6 py-6 transition-colors duration-300">
        <div className="max-w-5xl mx-auto">
          <h2 className="font-serif text-2xl font-bold text-slate-800 dark:text-slate-100 tracking-tight">Preferencias de Cuenta</h2>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto p-4 sm:p-6">
        <div className="mx-auto max-w-5xl">
          <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
            
            {/* ========================================================= */}
            {/* COLUMNA IZQ: PERFIL Y APARIENCIA */}
            {/* ========================================================= */}
            <div className="space-y-6 lg:col-span-1">
              
              {/* 1. Tarjeta Perfil */}
              <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300">
                <div className="flex items-center gap-4 pb-5 border-b border-slate-100 dark:border-slate-800/60">
                  {/* LOGO "D" ARREGLADO: Usamos emerald nativo de tailwind con texto explícitamente blanco */}
                  <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-emerald-600 dark:bg-emerald-500 font-serif text-xl font-bold text-white shadow-md">
                    {getInitials(sesionActual.nombre)}
                  </div>
                  <div className="overflow-hidden">
                    <h3 className="truncate text-sm font-bold text-slate-800 dark:text-slate-100">{sesionActual.nombre}</h3>
                    <p className="truncate text-[11px] font-medium text-slate-500 dark:text-slate-400">{sesionActual.correo}</p>
                  </div>
                </div>

                <div className="mt-5 space-y-3.5 text-xs">
                  <div className="flex justify-between items-center">
                    <span className="font-medium text-slate-500 dark:text-slate-400">Rol asignado:</span>
                    <span className="rounded-md bg-emerald-50 dark:bg-emerald-900/20 px-2 py-1 font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                      {sesionActual.rol === 'medico' ? 'OBSTETRA' : sesionActual.rol}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="font-medium text-slate-500 dark:text-slate-400">Establecimiento:</span>
                    <span className="flex items-center gap-1.5 font-semibold text-slate-700 dark:text-slate-300">
                      <Building size={14} className="text-slate-400 dark:text-slate-500"/> Baños del Inca
                    </span>
                  </div>
                </div>
              </div>

              {/* 2. Tarjeta Apariencia */}
              <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300">
                <h3 className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  Tema de Interfaz
                </h3>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={() => cambiarTema('claro')}
                    className={`flex items-center justify-center gap-2 rounded-xl border p-3 text-xs font-bold transition-all ${
                      tema === 'claro' 
                        ? 'border-emerald-200 bg-emerald-50 text-emerald-700 shadow-sm dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-400' 
                        : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-950/50 dark:text-slate-400 dark:hover:bg-slate-800'
                    }`}
                  >
                    <Sun size={16} className={tema === 'claro' ? 'text-emerald-500' : ''} /> Claro
                  </button>

                  <button
                    onClick={() => cambiarTema('oscuro')}
                    className={`flex items-center justify-center gap-2 rounded-xl border p-3 text-xs font-bold transition-all ${
                      tema === 'oscuro' 
                        ? 'border-emerald-500/30 bg-emerald-500/10 text-emerald-400 shadow-sm' 
                        : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-950/50 dark:text-slate-400 dark:hover:bg-slate-800'
                    }`}
                  >
                    <Moon size={16} className={tema === 'oscuro' ? 'text-emerald-400' : ''} /> Oscuro
                  </button>
                </div>
              </div>

              {/* 3. Tarjeta Notificaciones */}
              <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-5 shadow-sm transition-colors duration-300">
                <h3 className="mb-4 text-[10px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                  Alertas y Refresco
                </h3>
                
                <div className="flex items-center justify-between py-1">
                  <div className="flex items-center gap-3 pr-2">
                    <div className="rounded-lg bg-amber-50 dark:bg-amber-900/20 p-2 text-amber-600 dark:text-amber-500">
                      <Volume2 size={16} />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-slate-800 dark:text-slate-200">Alerta crítica</p>
                      <p className="mt-0.5 text-[10px] text-slate-500 dark:text-slate-400">Sonido si hay Riesgo Alto</p>
                    </div>
                  </div>
                  <input 
                    type="checkbox" 
                    checked={alertaSonora} 
                    onChange={(e) => setAlertaSonora(e.target.checked)}
                    className="h-4 w-4 accent-emerald-600 dark:accent-emerald-500 cursor-pointer rounded border-slate-300 dark:border-slate-700"
                  />
                </div>

                <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800/60 flex items-center justify-between">
                  <span className="text-xs font-medium text-slate-600 dark:text-slate-400">Auto-refresco:</span>
                  <select 
                    value={polling} 
                    onChange={(e) => setPolling(e.target.value)}
                    className="rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-950 px-3 py-1.5 text-xs font-bold text-slate-800 dark:text-slate-200 outline-none focus:border-emerald-500 dark:focus:border-emerald-500 cursor-pointer"
                  >
                    <option value="15">Cada 15s</option>
                    <option value="30">Cada 30s</option>
                    <option value="60">Cada 1 min</option>
                  </select>
                </div>
              </div>
            </div>

            {/* ========================================================= */}
            {/* COLUMNA DER: SEGURIDAD (CAMBIO DE CONTRASEÑA) */}
            {/* ========================================================= */}
            <div className="lg:col-span-2">
              <div className="rounded-2xl border border-slate-200 dark:border-slate-800/60 bg-white dark:bg-slate-900 p-6 shadow-sm transition-colors duration-300 h-full">
                
                <div className="flex items-start gap-4 mb-8 border-b border-slate-100 dark:border-slate-800/60 pb-6">
                  <div className="rounded-xl bg-slate-100 dark:bg-slate-800 p-3 text-slate-600 dark:text-slate-300">
                    <KeyRound size={20} />
                  </div>
                  <div className="pt-0.5">
                    <h3 className="text-base font-bold text-slate-800 dark:text-slate-100">Seguridad de la Cuenta</h3>
                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                      Actualiza tu contraseña de acceso institucional al padrón web. Asegúrate de usar una contraseña robusta.
                    </p>
                  </div>
                </div>

                {passStatus && (
                  <div className={`mb-6 rounded-xl p-4 text-xs font-bold flex items-center gap-2.5 shadow-sm ${
                    passStatus.type === 'ok' 
                      ? 'bg-emerald-50 text-emerald-700 border border-emerald-200 dark:bg-emerald-900/20 dark:border-emerald-800/50 dark:text-emerald-400' 
                      : 'bg-red-50 text-red-700 border border-red-200 dark:bg-red-900/20 dark:border-red-800/50 dark:text-red-400'
                  }`}>
                    {passStatus.type === 'ok' ? <CheckCircle2 size={18}/> : <AlertTriangle size={18}/>}
                    {passStatus.msg}
                  </div>
                )}

                <form onSubmit={handlePasswordSubmit} className="space-y-6 max-w-md">
                  
                  {/* Input 1 */}
                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
                      Contraseña Actual
                    </label>
                    <input
                      type={verPass ? 'text' : 'password'}
                      placeholder="••••••••"
                      value={passwords.actual}
                      onChange={(e) => setPasswords({...passwords, actual: e.target.value})}
                      className="w-full rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 px-4 py-3 text-xs font-medium text-slate-800 dark:text-slate-100 outline-none focus:border-emerald-500 dark:focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-950 transition-all duration-300 placeholder:text-slate-400 dark:placeholder:text-slate-600 shadow-sm"
                    />
                  </div>

                  {/* Input 2 */}
                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
                      Nueva Contraseña
                    </label>
                    <input
                      type={verPass ? 'text' : 'password'}
                      placeholder="Mínimo 6 caracteres"
                      value={passwords.nueva}
                      onChange={(e) => setPasswords({...passwords, nueva: e.target.value})}
                      className="w-full rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 px-4 py-3 text-xs font-medium text-slate-800 dark:text-slate-100 outline-none focus:border-emerald-500 dark:focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-950 transition-all duration-300 placeholder:text-slate-400 dark:placeholder:text-slate-600 shadow-sm"
                    />
                  </div>

                  {/* Input 3 */}
                  <div>
                    <label className="block text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
                      Confirmar Nueva Contraseña
                    </label>
                    <input
                      type={verPass ? 'text' : 'password'}
                      placeholder="Repite la nueva contraseña"
                      value={passwords.repetir}
                      onChange={(e) => setPasswords({...passwords, repetir: e.target.value})}
                      className="w-full rounded-xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950 px-4 py-3 text-xs font-medium text-slate-800 dark:text-slate-100 outline-none focus:border-emerald-500 dark:focus:border-emerald-500 focus:bg-white dark:focus:bg-slate-950 transition-all duration-300 placeholder:text-slate-400 dark:placeholder:text-slate-600 shadow-sm"
                    />
                  </div>

                  {/* Acciones */}
                  <div className="flex items-center justify-between pt-4">
                    <button
                      type="button"
                      onClick={() => setVerPass(!verPass)}
                      className="flex items-center gap-1.5 text-xs font-bold text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200 select-none transition-colors"
                    >
                      {verPass ? <EyeOff size={16}/> : <Eye size={16}/>}
                      {verPass ? 'Ocultar caracteres' : 'Mostrar caracteres'}
                    </button>

                    {/* BOTÓN ACTUALIZAR ARREGLADO: Color esmeralda fijo y texto blanco garantizado */}
                    <button
                      type="submit"
                      className="rounded-xl bg-emerald-600 dark:bg-emerald-600 px-6 py-3 text-xs font-bold text-white shadow-md transition-all hover:bg-emerald-700 dark:hover:bg-emerald-500 active:scale-[0.98]"
                    >
                      Actualizar Contraseña
                    </button>
                  </div>
                </form>

              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
  );
}