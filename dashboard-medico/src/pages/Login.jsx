import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, Lock, User } from 'lucide-react';

import logoTesis from '../assets/logo_tesis.png';
import { existeSesionWeb, iniciarSesionWeb } from '../services/auth';

export default function Login() {
  const navigate = useNavigate();

  const [dni, setDni] = useState('');
  const [pin, setPin] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    if (existeSesionWeb()) {
      navigate('/dashboard', { replace: true });
    }
  }, [navigate]);

  const manejarLogin = (e) => {
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

    iniciarSesionWeb({ dni });

    navigate('/dashboard', { replace: true });
  };

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-fondoApp p-4 font-sans text-slate-800">
      <div className="z-10 flex min-h-[580px] w-full max-w-[1000px] flex-col overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-xl md:flex-row">
        <div className="relative flex w-full flex-col justify-between bg-gradient-to-br from-verdeOscuro to-verdeApp p-10 text-white md:w-1/2 md:p-12">
          <div>
            <div className="mb-10 flex items-center gap-3">
              <img
                src={logoTesis}
                alt="logo_tesis"
                className="h-12 w-12 rounded-xl border border-white/20 bg-white/10 object-contain p-1.5 shadow-lg backdrop-blur-sm"
              />
              <span className="text-2xl font-bold tracking-tight">hersite</span>
            </div>

            <h1 className="mb-6 font-serif text-3xl font-bold leading-tight md:text-4xl">
              Sistema de monitoreo de riesgo materno
            </h1>

            <p className="max-w-sm text-sm font-medium leading-relaxed text-white/90">
              Plataforma para el seguimiento de evaluaciones móviles sincronizadas desde zonas con conectividad limitada.
            </p>

            <div className="mt-6 grid max-w-sm grid-cols-1 gap-3 text-xs">
              <div className="rounded-2xl border border-white/15 bg-white/10 p-3 backdrop-blur-sm">
                <p className="font-bold text-white">App móvil offline-first</p>
                <p className="mt-1 text-white/75">Registro local, modelo ONNX y sincronización automática.</p>
              </div>

              <div className="rounded-2xl border border-white/15 bg-white/10 p-3 backdrop-blur-sm">
                <p className="font-bold text-white">Dashboard clínico</p>
                <p className="mt-1 text-white/75">Visualización de gestantes, triajes y tendencias poblacionales.</p>
              </div>
            </div>
          </div>

          <div className="mt-12 inline-flex w-max items-center gap-3 rounded-2xl border border-white/20 bg-white/10 px-5 py-3.5 shadow-lg backdrop-blur-md">
            <span className="h-2.5 w-2.5 rounded-full bg-green-400 shadow-[0_0_8px_rgba(74,222,128,0.8)] animate-pulse"></span>
            <span className="text-sm font-semibold tracking-wide text-white">Plataforma de Vigilancia Obstétrica</span>
          </div>
        </div>

        <div className="flex w-full items-center justify-center bg-white p-10 md:w-1/2 md:p-12">
          <div className="w-full max-w-sm">
            <div className="mb-8">
              <h2 className="text-2xl font-bold tracking-tight text-slate-800">Acceso Clínico</h2>
              <p className="mt-1 text-xs text-slate-400">
                Ingrese sus credenciales para acceder al panel de monitoreo.
              </p>
            </div>

            <form onSubmit={manejarLogin} className="space-y-4">
              <div className="space-y-1.5">
                <label className="ml-1 text-[10px] font-bold uppercase tracking-wider text-slate-400">
                  Número de DNI
                </label>

                <div className="group relative">
                  <User className="absolute left-3 top-3.5 h-4 w-4 text-slate-400 transition-colors group-focus-within:text-verdeApp" />
                  <input
                    type="text"
                    maxLength={8}
                    value={dni}
                    onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-4 text-sm font-medium text-slate-800 outline-none transition-all focus:border-verdeApp focus:bg-white focus:ring-2 focus:ring-verdeApp/20"
                    placeholder="Ingrese su DNI de 8 dígitos"
                    required
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <div className="ml-1 flex items-center justify-between">
                  <label className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    PIN de acceso
                  </label>
                  <span className="text-[11px] font-bold text-slate-400">
                    Desarrollo
                  </span>
                </div>

                <div className="group relative">
                  <Lock className="absolute left-3 top-3.5 h-4 w-4 text-slate-400 transition-colors group-focus-within:text-verdeApp" />
                  <input
                    type="password"
                    maxLength={6}
                    value={pin}
                    onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
                    className="w-full rounded-xl border border-slate-200 bg-slate-50 py-2.5 pl-9 pr-4 text-lg font-bold tracking-[0.3em] text-slate-800 outline-none transition-all focus:border-verdeApp focus:bg-white focus:ring-2 focus:ring-verdeApp/20"
                    placeholder="••••••"
                    required
                  />
                </div>
              </div>

              {error && (
                <div className="rounded-xl border border-red-100 bg-red-50 px-3 py-2 text-xs font-semibold text-red-700">
                  {error}
                </div>
              )}

              <button
                type="submit"
                className="group mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-verdeOscuro py-3.5 text-sm font-bold text-white shadow-lg shadow-green-900/10 transition-all hover:bg-verdeApp"
              >
                Ingresar al Sistema
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
              </button>
            </form>

            <div className="mt-8 border-t border-slate-100 pt-6">
              <p className="text-center text-[10px] leading-relaxed text-slate-400">
                Módulo web para personal de salud.
                <br />
                Validación de credenciales reales pendiente para despliegue productivo.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}