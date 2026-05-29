import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, Lock, ArrowRight } from 'lucide-react';
import logoTesis from '../assets/logo_tesis.png'; // Asegúrate de que la ruta sea correcta

export default function Login() {
  const navigate = useNavigate();
  const [dni, setDni] = useState('');
  const [pin, setPin] = useState('');

  const manejarLogin = (e) => {
    e.preventDefault();
    // Aquí luego conectaremos con FastAPI para validar si el doctor existe
    navigate('/dashboard');
  };

  return (
    <div className="min-h-screen bg-fondoApp flex flex-col justify-center items-center p-4 font-sans text-slate-800 relative overflow-hidden">
      <div className="w-full max-w-[1000px] bg-white rounded-3xl shadow-xl border border-slate-100 flex flex-col md:flex-row overflow-hidden z-10 min-h-[580px]">
        
        {/* PANEL IZQUIERDO: Branding Institucional */}
        <div className="w-full md:w-1/2 bg-gradient-to-br from-verdeOscuro to-verdeApp p-10 md:p-12 flex flex-col justify-between text-white relative">
          <div>
            <div className="flex items-center gap-3 mb-10">
              <img 
                src={logoTesis} 
                alt="logo_tesis" 
                className="w-12 h-12 object-contain rounded-xl bg-white/10 p-1.5 backdrop-blur-sm border border-white/20 shadow-lg" 
              />
              <span className="text-2xl font-bold tracking-tight">hersite</span>
            </div>
            
            <h1 className="font-serif text-3xl md:text-4xl font-bold leading-tight mb-6">
              Sistema de monitoreo de riesgo materno
            </h1>
            
            <p className="text-white/90 font-medium text-sm leading-relaxed max-w-sm">
              Detección oportuna de <span className="font-bold underline decoration-red-400">preeclampsia</span>, <span className="font-bold">hemorragia</span> y <span className="font-bold">sepsis</span> mediante predicción en la comunidad rural.
            </p>
          </div>

          <div className="mt-12 inline-flex items-center gap-3 bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl px-5 py-3.5 shadow-lg w-max">
            <span className="w-2.5 h-2.5 rounded-full bg-green-400 animate-pulse shadow-[0_0_8px_rgba(74,222,128,0.8)]"></span>
            <span className="text-sm font-semibold tracking-wide text-white">Plataforma de Vigilancia Obstétrica</span>
          </div>
        </div>

        {/* PANEL DERECHO: Formulario de Login Estricto */}
        <div className="w-full md:w-1/2 p-10 md:p-12 flex items-center justify-center bg-white">
          <div className="w-full max-w-sm">
            
            <div className="mb-8">
              <h2 className="text-2xl font-bold text-slate-800 tracking-tight">Acceso Clínico</h2>
              <p className="text-xs text-slate-400 mt-1">Ingrese sus credenciales autorizadas.</p>
            </div>

            <form onSubmit={manejarLogin} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider ml-1">Número de DNI</label>
                <div className="relative group">
                  <User className="absolute left-3 top-3.5 w-4 h-4 text-slate-400 group-focus-within:text-verdeApp transition-colors" />
                  <input 
                    type="text" 
                    maxLength={8}
                    value={dni}
                    onChange={(e) => setDni(e.target.value.replace(/\D/g, ''))}
                    className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-sm text-slate-800 font-medium"
                    placeholder="Ingrese su DNI de 8 dígitos"
                    required
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between items-center ml-1">
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">PIN de acceso</label>
                  <a href="#" className="text-[11px] text-verdeApp font-bold hover:underline">¿Olvidó su PIN?</a>
                </div>
                <div className="relative group">
                  <Lock className="absolute left-3 top-3.5 w-4 h-4 text-slate-400 group-focus-within:text-verdeApp transition-colors" />
                  <input 
                    type="password" 
                    maxLength={6}
                    value={pin}
                    onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
                    className="w-full pl-9 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:ring-2 focus:ring-verdeApp/20 focus:border-verdeApp outline-none transition-all text-lg text-slate-800 tracking-[0.3em] font-bold"
                    placeholder="••••••"
                    required
                  />
                </div>
              </div>

              <button 
                type="submit" 
                className="w-full bg-verdeOscuro hover:bg-verdeApp text-white font-bold py-3.5 rounded-xl shadow-lg shadow-green-900/10 transition-all flex items-center justify-center gap-2 text-sm group mt-4"
              >
                Ingresar al Sistema
                <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </button>
            </form>

            <div className="mt-8 pt-6 border-t border-slate-100">
              <p className="text-center text-[10px] text-slate-400 leading-relaxed">
                Uso exclusivo para personal médico registrado.<br/>
                Para solicitar acceso, comuníquese con el administrador del sistema.
              </p>
            </div>

          </div>
        </div>

      </div>
    </div>
  );
}