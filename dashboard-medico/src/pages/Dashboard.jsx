import React, { useState } from 'react';
import { AlertTriangle, Search, CheckCircle2 } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { patientsData } from '../utils/mockData';

export default function Dashboard() {
  const [selectedPat, setSelectedPat] = useState(patientsData[0]);

  const getRiskColors = (riskClass) => {
    if (riskClass === 'danger') return { bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200', bar: 'bg-red-500' };
    if (riskClass === 'warn') return { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', bar: 'bg-amber-500' };
    return { bg: 'bg-green-50', text: 'text-green-700', border: 'border-green-200', bar: 'bg-green-500' };
  };

  return (
    <div className="flex flex-col h-full w-full bg-fondoApp">
      
      {/* TOPBAR COMPACTA */}
      <header className="bg-white border-b border-slate-200 px-6 py-3 flex items-center justify-between shrink-0">
        <h2 className="text-sm font-bold text-slate-800">Panel de triaje — Gestantes activas</h2>
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5 bg-green-50 border border-green-200 px-3 py-1 rounded-full text-[11px] font-semibold text-verdeOscuro">
            <span className="w-1.5 h-1.5 rounded-full bg-verdeApp animate-pulse"></span> Sincronizado
          </div>
        </div>
      </header>

      {/* MÉTRICAS PEQUEÑAS (KPIs) */}
      <div className="grid grid-cols-3 bg-white border-b border-slate-200 shrink-0">
        <div className="px-6 py-3 text-center border-r border-slate-100">
          <div className="text-2xl font-bold text-red-500 leading-none">3</div>
          <div className="text-[10px] text-slate-400 uppercase tracking-widest font-semibold mt-1">Riesgo Alto</div>
        </div>
        <div className="px-6 py-3 text-center border-r border-slate-100">
          <div className="text-2xl font-bold text-amber-500 leading-none">5</div>
          <div className="text-[10px] text-slate-400 uppercase tracking-widest font-semibold mt-1">Riesgo Medio</div>
        </div>
        <div className="px-6 py-3 text-center">
          <div className="text-2xl font-bold text-verdeApp leading-none">12</div>
          <div className="text-[10px] text-slate-400 uppercase tracking-widest font-semibold mt-1">Estables</div>
        </div>
      </div>

      {/* ÁREA DE TRABAJO DUAL (Lista a la izquierda, Detalle a la derecha) */}
      <div className="flex-1 flex overflow-hidden">
        
        {/* LISTA DE PACIENTES */}
        <div className="w-72 bg-white border-r border-slate-200 flex flex-col shrink-0">
          <div className="px-3 py-4 border-b border-slate-100">
            <div className="relative">
              <Search size={14} className="absolute left-2.5 top-2.5 text-slate-400" />
              <input type="text" placeholder="Buscar paciente..." className="w-full border border-slate-200 rounded-lg pl-8 pr-3 py-1.5 text-xs outline-none focus:border-verdeApp" />
            </div>
          </div>

          <div className="flex-1 overflow-y-auto">
            {patientsData.map((p) => {
              const colors = getRiskColors(p.riskClass);
              const isActive = selectedPat.id === p.id;
              return (
                <div
                  key={p.id}
                  onClick={() => setSelectedPat(p)}
                  className={`flex items-center gap-3 p-3 cursor-pointer border-b border-slate-50 transition-colors ${isActive ? 'bg-green-50/50 border-r-2 border-r-verdeApp' : 'hover:bg-slate-50'}`}
                >
                  <div className={`w-1 h-10 rounded-full shrink-0 ${colors.bar}`}></div>
                  <div className="flex-1 min-w-0">
                    <p className={`text-xs font-semibold truncate ${isActive ? 'text-verdeOscuro' : 'text-slate-800'}`}>{p.name}</p>
                    <p className="text-[10px] text-slate-400 mt-0.5">{p.meta}</p>
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        {/* DETALLE DEL PACIENTE Y GRÁFICOS */}
        <div className="flex-1 p-6 overflow-y-auto flex flex-col gap-4">
          
          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-green-50 border-2 border-green-200 flex items-center justify-center text-verdeOscuro font-bold">{selectedPat.initials}</div>
              <div>
                <h3 className="text-lg font-bold text-slate-800">{selectedPat.name}</h3>
                <p className="text-xs text-slate-500 mt-1">Nacida: {selectedPat.dob} · {selectedPat.age} años · {selectedPat.weeks} sem. gestación</p>
              </div>
              <div className="ml-auto text-center">
                <div className={`text-3xl font-black ${selectedPat.riskClass === 'danger' ? 'text-red-500' : selectedPat.riskClass === 'warn' ? 'text-amber-500' : 'text-verdeApp'}`}>{selectedPat.prob}%</div>
                <div className="text-[10px] text-slate-400 uppercase font-bold mt-1">Riesgo ML</div>
              </div>
            </div>
            
            <div className={`mt-5 p-3 rounded-lg flex items-center gap-3 border ${getRiskColors(selectedPat.riskClass).bg} ${getRiskColors(selectedPat.riskClass).border}`}>
              <AlertTriangle className={getRiskColors(selectedPat.riskClass).text} size={20} />
              <div>
                <p className={`text-xs font-bold ${getRiskColors(selectedPat.riskClass).text}`}>Riesgo {selectedPat.risk}</p>
                <p className={`text-[10px] mt-0.5 ${getRiskColors(selectedPat.riskClass).text} opacity-90`}>
                  {selectedPat.riskClass === 'danger' ? 'El modelo LightGBM detectó patrón compatible con preeclampsia. Atención prioritaria.' : selectedPat.riskClass === 'warn' ? 'Síntomas moderados. Monitoreo cercano recomendado.' : 'Sin anomalías. Continuar protocolo estándar.'}
                </p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
              <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-4">Última lectura</div>
              <div className="grid grid-cols-2 gap-2">
                <div className="bg-slate-50 p-3 rounded-lg">
                  <p className="text-[10px] text-slate-400 uppercase">Sistólica</p>
                  <p className={`text-2xl font-bold ${selectedPat.riskClass === 'danger' ? 'text-red-500' : 'text-slate-800'}`}>{selectedPat.sys}<span className="text-xs text-slate-400 font-normal ml-1">mmHg</span></p>
                </div>
                <div className="bg-slate-50 p-3 rounded-lg">
                  <p className="text-[10px] text-slate-400 uppercase">Diastólica</p>
                  <p className={`text-2xl font-bold ${selectedPat.riskClass === 'danger' ? 'text-red-500' : 'text-slate-800'}`}>{selectedPat.dia}<span className="text-xs text-slate-400 font-normal ml-1">mmHg</span></p>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
              <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Presión Arterial (7 Días)</div>
              <div className="h-24 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={selectedPat.chartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                    <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{fontSize: 10, fill: '#94a3b8'}} />
                    <YAxis domain={['dataMin - 10', 'dataMax + 10']} hide={true} />
                    <Tooltip contentStyle={{fontSize: '10px', borderRadius: '8px'}} />
                    <Line type="monotone" dataKey="sys" stroke="#ef4444" strokeWidth={2} dot={{r:3}} />
                    <Line type="monotone" dataKey="dia" stroke="#f59e0b" strokeWidth={2} dot={{r:3}} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm">
            <div className="flex justify-between items-start">
              <div>
                <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Síntomas reportados</div>
                <div className="flex flex-wrap gap-2">
                  {selectedPat.symptoms.length > 0 ? (
                    selectedPat.symptoms.map(s => (
                       <span key={s} className="bg-red-50 text-red-700 border border-red-100 text-[11px] font-semibold px-2.5 py-1 rounded-md">{s}</span>
                    ))
                  ) : (
                    <span className="text-xs text-slate-400">Sin síntomas de alarma.</span>
                  )}
                </div>
              </div>
              <div className="text-right">
                <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1">Sincronización Local</div>
                <p className="text-xs font-semibold text-verdeApp flex items-center justify-end gap-1"><CheckCircle2 size={14}/> {selectedPat.sync}</p>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}