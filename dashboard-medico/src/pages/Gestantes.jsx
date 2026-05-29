import React, { useState } from 'react';
import { Search, WifiOff, ArrowLeft, Activity, Clock, ChevronRight, ShieldAlert } from 'lucide-react';

// Datos optimizados para el tercer trimestre (EG: 28 a 40 semanas) y simplificado a Sepsis
const inicialGestantes = [
  { 
    dni: "74589632", nombre: "Rosa M. Huamán", edad: 21, semanas: 34, riesgo: "ALTO", riesgoClass: "danger", ultimaSync: "Hace 2 horas", horasDesdeSync: 2, ubicacion: "Chota",
    probabilidades: { preeclampsia: 87, hemorragia: 12, sepsis: 5 },
    historial: [
      { semana: 34, fecha: "29/05/2026", riesgo: "ALTO", detalle: "PA 158/102 mmHg. Reporta cefalea intensa y visión borrosa." },
      { semana: 32, fecha: "15/05/2026", riesgo: "MEDIO", detalle: "PA 135/85 mmHg. Inicio de edemas leves en extremidades inferiores." },
      { semana: 28, fecha: "17/04/2026", riesgo: "ESTABLE", detalle: "Ingreso al tercer trimestre. Parámetros estables. PA 115/75 mmHg." }
    ]
  },
  { 
    dni: "41258963", nombre: "Carmen L. Díaz", edad: 25, semanas: 36, riesgo: "ALTO", riesgoClass: "danger", ultimaSync: "Hace 5 horas", horasDesdeSync: 5, ubicacion: "Cutervo",
    probabilidades: { preeclampsia: 15, hemorragia: 79, sepsis: 8 },
    historial: [
      { semana: 36, fecha: "29/05/2026", riesgo: "ALTO", detalle: "Pérdida hemática transvaginal activa. Requiere evaluación obstétrica inmediata." },
      { semana: 32, fecha: "02/05/2026", riesgo: "ESTABLE", detalle: "Dinámica uterina negativa. Controles normales." }
    ]
  },
  { 
    dni: "70251489", nombre: "María Quispe P.", edad: 19, semanas: 31, riesgo: "ALTO", riesgoClass: "danger", ultimaSync: "Hace 52 horas", horasDesdeSync: 52, ubicacion: "Bambamarca",
    probabilidades: { preeclampsia: 45, hemorragia: 10, sepsis: 74 },
    historial: [
      { semana: 31, fecha: "27/05/2026", riesgo: "ALTO", detalle: "Fiebre persistente de 39.2°C, taquicardia materna. Sospecha de foco infeccioso." },
      { semana: 28, fecha: "06/05/2026", riesgo: "ESTABLE", detalle: "Control de rutina sin signos de alarma." }
    ]
  },
  { 
    dni: "48563214", nombre: "Natividad C. Torres", edad: 24, semanas: 33, riesgo: "MEDIO", riesgoClass: "warn", ultimaSync: "Hace 1 hora", horasDesdeSync: 1, ubicacion: "Chota",
    probabilidades: { preeclampsia: 52, hemorragia: 14, sepsis: 2 },
    historial: [
      { semana: 33, fecha: "29/05/2026", riesgo: "MEDIO", detalle: "PA 128/82 mmHg. Reporta fatiga extrema y acúfenos esporádicos." }
    ]
  },
  { 
    dni: "42159687", nombre: "Esperanza R. Vega", edad: 26, semanas: 30, riesgo: "MEDIO", riesgoClass: "warn", ultimaSync: "Hace 72 hours", horasDesdeSync: 72, ubicacion: "San Marcos",
    probabilidades: { preeclampsia: 20, hemorragia: 44, sepsis: 10 },
    historial: [
      { semana: 30, fecha: "26/05/2026", riesgo: "MEDIO", detalle: "Contracciones aisladas previas al término. Dolor pélvico leve." }
    ]
  },
  { 
    dni: "73214589", nombre: "Ana G. Saldaña", edad: 28, semanas: 29, riesgo: "ESTABLE", riesgoClass: "ok", ultimaSync: "Hace 20 min", horasDesdeSync: 0, ubicacion: "Cutervo",
    probabilidades: { preeclampsia: 11, hemorragia: 5, sepsis: 2 },
    historial: [
      { semana: 29, fecha: "29/05/2026", riesgo: "ESTABLE", detalle: "Control óptimo. PA 112/70 mmHg. Movimientos fetales activos." }
    ]
  }
];

export default function Gestantes() {
  const [gestantes] = useState(inicialGestantes);
  const [busqueda, setBusqueda] = useState('');
  const [filtroRiesgo, setFiltroRiesgo] = useState('TODOS');
  const [soloDesactualizadas, setSoloDesactualizadas] = useState(false);
  
  // Control de vista: 'lista' o 'detalle'
  const [vista, setVista] = useState('lista');
  const [seleccionada, setSeleccionada] = useState(null);

  // Filtrado de la tabla principal
  const gestantesFiltradas = gestantes.filter(g => {
    const coincideBusqueda = g.nombre.toLowerCase().includes(busqueda.toLowerCase()) || g.dni.includes(busqueda);
    const coincideRiesgo = filtroRiesgo === 'TODOS' || g.riesgo === filtroRiesgo;
    const coincideConectividad = !soloDesactualizadas || g.horasDesdeSync > 24; // CORREGIDO A 24 HORAS
    
    return coincideBusqueda && coincideRiesgo && coincideConectividad;
  });

  const irADetalle = (gestante) => {
    setSeleccionada(gestante);
    setVista('detalle');
  };

  const irALista = () => {
    setVista('lista');
    setSeleccionada(null);
  };

  return (
    <div className="flex flex-col h-full w-full bg-fondoApp">
      
      {/* ================= VISTA 1: LISTADO GENERAL ================= */}
      {vista === 'lista' && (
        <div className="flex flex-col h-full w-full animate-fade-in">
          <header className="bg-white border-b border-slate-200 px-6 py-4 shrink-0">
            <h2 className="font-serif text-2xl font-bold text-slate-800">Padrón de Gestantes</h2>
            <p className="text-xs text-slate-500 mt-0.5">Tercer Trimestre — Monitoreo de riesgos y sincronización en comunidad rural.</p>
          </header>

          <div className="bg-white border-b border-slate-200 px-6 py-3 flex flex-col sm:flex-row gap-3 items-center justify-between shrink-0">
            <div className="relative w-full sm:w-72">
              <Search size={14} className="absolute left-3 top-3 text-slate-400" />
              <input 
                type="text" 
                placeholder="Buscar por DNI o nombre..." 
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="w-full border border-slate-200 rounded-xl pl-9 pr-4 py-2 text-xs outline-none focus:border-verdeApp bg-slate-50 focus:bg-white transition-all font-medium"
              />
            </div>

            <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto justify-end">
              <div className="flex bg-slate-100 p-1 rounded-xl border border-slate-200/60">
                {['TODOS', 'ALTO', 'MEDIO', 'ESTABLE'].map((r) => (
                  <button
                    key={r}
                    onClick={() => setFiltroRiesgo(r)}
                    className={`px-3 py-1 text-[10px] font-bold rounded-lg transition-all ${
                      filtroRiesgo === r ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'
                    }`}
                  >
                    {r}
                  </button>
                ))}
              </div>

              <button
                onClick={() => setSoloDesactualizadas(!soloDesactualizadas)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all ${
                  soloDesactualizadas ? 'bg-amber-50 border-amber-300 text-amber-700 shadow-sm' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
                }`}
              >
                <WifiOff size={14} className={soloDesactualizadas ? 'text-amber-600' : 'text-slate-400'} />
                Desactualizadas (&gt;24h)
              </button>
            </div>
          </div>

          <div className="flex-1 p-6 overflow-auto">
            <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
              <table className="w-full text-left border-collapse">
                <thead className="bg-slate-50/70 border-b border-slate-200">
                  <tr>
                    <th className="px-6 py-3.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Paciente</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider text-center">Edad / EG</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider font-medium">Comunidad</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Riesgo Predicho</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider">Última Sincronización</th>
                    <th className="px-6 py-3.5 text-[10px] font-bold text-slate-400 uppercase tracking-wider text-right">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {gestantesFiltradas.length > 0 ? (
                    gestantesFiltradas.map((g, i) => (
                      <tr key={i} className="hover:bg-slate-50/70 transition-colors">
                        <td className="px-6 py-4">
                          <span className="font-bold text-slate-700 block text-xs">{g.nombre}</span>
                          <span className="text-[10px] text-slate-400 font-mono mt-0.5 block">DNI: {g.dni}</span>
                        </td>
                        <td className="px-6 py-4 text-xs text-slate-600 font-medium text-center">
                          {g.edad} años <br/> <span className="text-[10px] text-slate-400 font-semibold">{g.semanas} semanas</span>
                        </td>
                        <td className="px-6 py-4 text-xs text-slate-600 font-medium">{g.ubicacion}</td>
                        <td className="px-6 py-4">
                          {g.riesgoClass === 'danger' && <span className="inline-flex items-center gap-1 bg-red-50 border border-red-100 text-red-600 px-2.5 py-1 rounded-full text-[10px] font-bold"><span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"></span>ALTA PRIORIDAD</span>}
                          {g.riesgoClass === 'warn' && <span className="inline-flex items-center gap-1 bg-amber-50 border border-amber-200 text-amber-700 px-2.5 py-1 rounded-full text-[10px] font-bold"><span className="w-1.5 h-1.5 rounded-full bg-amber-500"></span>RIESGO MEDIO</span>}
                          {g.riesgoClass === 'ok' && <span className="inline-flex items-center gap-1 bg-green-50 border border-green-200 text-green-700 px-2.5 py-1 rounded-full text-[10px] font-bold"><span className="w-1.5 h-1.5 rounded-full bg-green-500"></span>ESTABLE</span>}
                        </td>
                        <td className="px-6 py-4">
                          <span className={`text-xs font-semibold flex items-center gap-1.5 ${g.horasDesdeSync > 24 ? 'text-amber-600' : 'text-slate-500'}`}>
                            <span className={`w-1.5 h-1.5 rounded-full ${g.horasDesdeSync > 24 ? 'bg-amber-500' : 'bg-green-500'}`}></span>
                            {g.ultimaSync}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                          <button 
                            onClick={() => irADetalle(g)}
                            className="inline-flex items-center gap-1 px-3 py-1.5 bg-slate-100 hover:bg-verdeApp hover:text-white rounded-xl text-xs font-bold text-slate-700 transition-all group"
                          >
                            Ver Ficha Clinica
                            <ChevronRight size={14} className="group-hover:translate-x-0.5 transition-transform" />
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-xs text-slate-400 font-medium">No se encontraron registros.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ================= VISTA 2: DETALLE PROFUNDO PANTALLA COMPLETA ================= */}
      {vista === 'detalle' && seleccionada && (
        <div className="flex flex-col h-full w-full animate-fade-in bg-slate-50">
          
          {/* TOPBAR DETALLE */}
          <header className="bg-white border-b border-slate-200 px-6 py-4 shrink-0 flex items-center gap-4">
            <button 
              onClick={irALista}
              className="p-2 border border-slate-200 rounded-xl hover:bg-slate-50 text-slate-600 transition-colors"
            >
              <ArrowLeft size={16} />
            </button>
            <div>
              <div className="flex items-center gap-3">
                <h2 className="font-serif text-xl font-bold text-slate-800">{seleccionada.nombre}</h2>
                <span className="text-xs font-mono bg-slate-100 text-slate-600 px-2.5 py-0.5 rounded-md">DNI {seleccionada.dni}</span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">Tercer Trimestre • Comunidad de {seleccionada.ubicacion}</p>
            </div>
          </header>

          {/* CONTENIDO DE HISTORIA CLÍNICA */}
          <div className="flex-1 p-6 overflow-y-auto">
            <div className="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-3 gap-6">
              
              {/* Bloque Izquierdo: Resumen y Probabilidades Predictivas */}
              <div className="md:col-span-1 space-y-6">
                
                {/* Ficha básica */}
                <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm">
                  <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-4">Datos del trimestre</h3>
                  <div className="space-y-3 text-xs">
                    <div className="flex justify-between py-1.5 border-b border-slate-50">
                      <span className="text-slate-500 font-medium">Edad de la Madre</span>
                      <span className="font-bold text-slate-800">{seleccionada.edad} años</span>
                    </div>
                    <div className="flex justify-between py-1.5 border-b border-slate-50">
                      <span className="text-slate-500 font-medium">Edad Gestacional</span>
                      <span className="font-bold text-verdeOscuro">{seleccionada.semanas} semanas</span>
                    </div>
                    <div className="flex justify-between py-1.5">
                      <span className="text-slate-500 font-medium">Sincronización Edge</span>
                      <span className="font-bold text-slate-700">{seleccionada.ultimaSync}</span>
                    </div>
                  </div>
                </div>

                {/* Probabilidades desglosadas */}
                <div className="bg-white border border-slate-200 rounded-2xl p-5 shadow-sm">
                  <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center gap-2">
                    <Activity size={14} className="text-verdeApp"/> Probabilidad de Complicación (ML)
                  </h3>
                  
                  <div className="space-y-4">
                    {/* Preeclampsia */}
                    <div>
                      <div className="flex justify-between text-xs mb-1">
                        <span className="font-semibold text-slate-700">Preeclampsia</span>
                        <span className="font-bold text-red-600">{seleccionada.probabilidades.preeclampsia}%</span>
                      </div>
                      <div className="w-full bg-slate-100 rounded-full h-2">
                        <div className="bg-red-500 h-2 rounded-full transition-all" style={{ width: `${seleccionada.probabilidades.preeclampsia}%` }}></div>
                      </div>
                    </div>

                    {/* Hemorragia */}
                    <div>
                      <div className="flex justify-between text-xs mb-1">
                        <span className="font-semibold text-slate-700">Hemorragia Obstétrica</span>
                        <span className="font-bold text-amber-600">{seleccionada.probabilidades.hemorragia}%</span>
                      </div>
                      <div className="w-full bg-slate-100 rounded-full h-2">
                        <div className="bg-amber-500 h-2 rounded-full transition-all" style={{ width: `${seleccionada.probabilidades.hemorragia}%` }}></div>
                      </div>
                    </div>

                    {/* Sepsis */}
                    <div>
                      <div className="flex justify-between text-xs mb-1">
                        <span className="font-semibold text-slate-700">Sepsis</span>
                        <span className="font-bold text-purple-600">{seleccionada.probabilidades.sepsis}%</span>
                      </div>
                      <div className="w-full bg-slate-100 rounded-full h-2">
                        <div className="bg-purple-500 h-2 rounded-full transition-all" style={{ width: `${seleccionada.probabilidades.sepsis}%` }}></div>
                      </div>
                    </div>
                  </div>
                </div>

              </div>

              {/* Bloque Derecho: Trazabilidad y Cronología Clínica */}
              <div className="md:col-span-2">
                <div className="bg-white border border-slate-200 rounded-2xl p-6 shadow-sm h-full">
                  <h3 className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-6 flex items-center gap-2">
                    <Clock size={14} className="text-verdeApp"/> Trazabilidad y Evolución de Triajes Móviles
                  </h3>

                  <div className="relative border-l-2 border-slate-100 ml-3 space-y-6">
                    {seleccionada.historial.map((item, idx) => (
                      <div key={idx} className="relative pl-6">
                        
                        {/* Punto con código de color institucional para alertas */}
                        <div className={`absolute -left-[5px] top-1 w-2.5 h-2.5 rounded-full border-2 border-white shadow-sm ${
                          item.riesgo === 'ALTO' ? 'bg-red-500' : item.riesgo === 'MEDIO' ? 'bg-amber-500' : 'bg-green-500'
                        }`}></div>

                        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 mb-2">
                          <span className="text-sm font-bold text-slate-800">Semana de Gestación: {item.semana}</span>
                          <span className="text-[11px] font-medium text-slate-400">{item.fecha}</span>
                        </div>

                        <div className="mb-2">
                          {item.riesgo === 'ALTO' ? (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold text-red-600 bg-red-50 border border-red-100 px-2 py-0.5 rounded-md">ALTA PRIORIDAD</span>
                          ) : item.riesgo === 'MEDIO' ? (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-700 bg-amber-50 border border-amber-100 px-2 py-0.5 rounded-md">RIESGO MEDIO</span>
                          ) : (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold text-green-700 bg-green-50 border border-green-100 px-2 py-0.5 rounded-md">ESTABLE</span>
                          )}
                        </div>

                        <div className="text-xs text-slate-600 bg-slate-50 border border-slate-100/70 p-3.5 rounded-xl leading-relaxed">
                          {item.detalle}
                        </div>
                      </div>
                    ))}
                  </div>

                </div>
              </div>

            </div>
          </div>
        </div>
      )}

    </div>
  );
}