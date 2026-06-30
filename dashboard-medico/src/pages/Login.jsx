import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, AlertTriangle, Lock, User, ShieldCheck } from 'lucide-react';

import logoTesis from '../assets/logo_tesis.png';
import { existeSesionWeb, iniciarSesionWeb } from '../services/auth';

export default function Login() {
  const navigate = useNavigate();

  const [dni, setDni] = useState('');
  const [pin, setPin] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (existeSesionWeb()) {
      navigate('/dashboard', { replace: true });
    }
  }, [navigate]);
  
  const manejarLogin = async (e) => {
    e.preventDefault();
    setError('');

    if (dni.length !== 8) {
      setError('Ingrese un DNI válido de 8 dígitos.');
      return;
    }

    if (pin.length !== 6) {
      setError('Ingrese un PIN válido de 6 dígitos.');
      return;
    }

    setIsLoading(true);

    try {
      await iniciarSesionWeb({ dni, pin });
      navigate('/dashboard', { replace: true });
    } catch (err) {
      setError(err.message || 'No se pudo iniciar sesión.');
      setIsLoading(false);
    }
  };

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-slate-50 p-4 sm:p-8 font-sans text-slate-800 selection:bg-[#679366] selection:text-white">
      
      {/* Contenedor Principal */}
      <div className="z-10 flex w-full max-w-[1000px] flex-col overflow-hidden rounded-[2rem] border border-slate-200/60 bg-white shadow-2xl shadow-slate-200/50 md:flex-row md:min-h-[600px]">
        
        {/* ========================================================= */}
        {/* MITAD IZQUIERDA: BRANDING (VERDE SALVIA PERSONALIZADO) */}
        {/* ========================================================= */}
        {/* bg-[#679366] es ligeramente más claro que tu #588157 */}
        <div className="relative flex w-full flex-col justify-between bg-[#679366] p-10 text-white md:w-5/12 lg:w-1/2 md:p-12 overflow-hidden">
          
          {/* Luces/Sombras de fondo para romper lo plano */}
          <div className="absolute -top-24 -left-24 h-96 w-96 rounded-full bg-[#82b380]/50 blur-3xl"></div>
          <div className="absolute -bottom-24 -right-24 h-96 w-96 rounded-full bg-[#405c3f]/50 blur-3xl"></div>

          <div className="relative z-10 flex flex-col h-full justify-center">
            
            {/* LOGO (Fondo blanco) Y TEXTO ALINEADOS HORIZONTALMENTE */}
            <div className="mb-10 flex items-center gap-4">
              <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-white shadow-lg">
                <img
                  src={logoTesis}
                  alt="logo_tesis"
                  className="h-10 w-10 object-contain"
                />
              </div>
              <span className="text-4xl font-black tracking-tight text-white drop-shadow-sm">hersite</span>
            </div>

            <h1 className="mb-6 font-serif text-3xl font-bold leading-tight md:text-4xl text-white">
              Sistema de Monitoreo <br/> de Riesgo Materno
            </h1>

            <p className="max-w-sm text-base font-medium leading-relaxed text-[#eaf2ea]">
              Plataforma para el seguimiento clínico en tiempo real de evaluaciones móviles en zonas con conectividad limitada.
            </p>
          </div>

          <div className="relative z-10 mt-12 inline-flex w-max items-center gap-2.5 rounded-full border border-white/20 bg-white/10 px-4 py-2 shadow-lg backdrop-blur-md">
            <ShieldCheck size={16} className="text-[#b4d6b3]" />
            <span className="text-[11px] font-bold tracking-widest uppercase text-white">Acceso Seguro</span>
          </div>
        </div>

        {/* ========================================================= */}
        {/* MITAD DERECHA: FORMULARIO */}
        {/* ========================================================= */}
        <div className="flex w-full items-center justify-center bg-white p-10 md:w-7/12 lg:w-1/2 md:p-12 lg:p-16">
          <div className="w-full max-w-sm">
            
            <div className="mb-10 text-center md:text-left">
              <h2 className="text-2xl font-black tracking-tight text-slate-800">Acceso Clínico</h2>
              <p className="mt-2 text-xs font-medium text-slate-500">
                Ingrese sus credenciales institucionales para acceder al panel de monitoreo médico.
              </p>
            </div>

            <form onSubmit={manejarLogin} className="space-y-6">
              
              {/* Input DNI */}
              <div className="space-y-1.5">
                <label className="ml-1 text-[10px] font-bold uppercase tracking-wider text-slate-500">
                  Número de DNI
                </label>
                <div className="group relative">
                  {/* El icono cambia a tu color original #588157 al hacer click */}
                  <User className="absolute left-4 top-1/2 -translate-y-1/2 h-[18px] w-[18px] text-slate-400 transition-colors group-focus-within:text-[#588157]" />
                  <input
                    type="text"
                    maxLength={8}
                    value={dni}
                    onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))}
                    className="w-full rounded-2xl border border-slate-200 bg-slate-50/50 py-3.5 pl-11 pr-4 text-sm font-bold text-slate-800 outline-none transition-all placeholder:font-medium placeholder:text-slate-400 focus:border-[#679366] focus:bg-white focus:ring-4 focus:ring-[#679366]/15"
                    placeholder="Ingrese los 8 dígitos"
                    required
                    disabled={isLoading}
                  />
                </div>
              </div>

              {/* Input PIN */}
              <div className="space-y-1.5">
                <label className="ml-1 text-[10px] font-bold uppercase tracking-wider text-slate-500">
                  PIN de Seguridad
                </label>
                <div className="group relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 h-[18px] w-[18px] text-slate-400 transition-colors group-focus-within:text-[#588157]" />
                  <input
                    type="password"
                    maxLength={6}
                    value={pin}
                    onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
                    className="w-full rounded-2xl border border-slate-200 bg-slate-50/50 py-3.5 pl-11 pr-4 text-lg font-black tracking-[0.3em] text-slate-800 outline-none transition-all placeholder:font-medium placeholder:tracking-normal placeholder:text-slate-400 focus:border-[#679366] focus:bg-white focus:ring-4 focus:ring-[#679366]/15"
                    placeholder="••••••"
                    required
                    disabled={isLoading}
                  />
                </div>
              </div>

              {error && (
                <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-xs font-bold text-red-700 animate-fade-in">
                  <AlertTriangle size={16} className="shrink-0" />
                  <p>{error}</p>
                </div>
              )}

              {/* El Hover activa tu color #588157 exacto */}
              <button
                type="submit"
                disabled={isLoading}
                className="group mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-[#679366] py-4 text-sm font-bold text-white shadow-lg shadow-[#588157]/30 transition-all hover:bg-[#588157] active:scale-[0.98] disabled:opacity-70 disabled:cursor-not-allowed"
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <span className="h-4 w-4 rounded-full border-2 border-white/30 border-t-white animate-spin"></span>
                    Autenticando...
                  </span>
                ) : (
                  <>
                    Ingresar al Sistema
                    <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                  </>
                )}
              </button>
            </form>

            <div className="mt-10 border-t border-slate-100 pt-8 text-center md:text-left">
              <p className="text-[10px] leading-relaxed text-slate-400">
                Módulo web exclusivo para personal de salud autorizado. <br className="hidden md:block"/>
                <span className="font-semibold text-slate-500">Credenciales verificadas por el servidor.</span>
              </p>
            </div>
            
          </div>
        </div>
      </div>

    </div>
  );
}