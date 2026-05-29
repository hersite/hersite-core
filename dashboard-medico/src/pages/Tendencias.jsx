import React from 'react';
import { TrendingUp, Activity, BarChart2, AlertCircle } from 'lucide-react';
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend,
  BarChart, Bar, Cell
} from 'recharts';

// 1. Datos Mockeados: Curva Epidemiológica (Mes a Mes)
const datosMensuales = [
  { mes: 'Ene', preeclampsia: 4, hemorragia: 2, sepsis: 0 },
  { mes: 'Feb', preeclampsia: 6, hemorragia: 1, sepsis: 1 },
  { mes: 'Mar', preeclampsia: 5, hemorragia: 3, sepsis: 0 },
  { mes: 'Abr', preeclampsia: 9, hemorragia: 2, sepsis: 2 },
  { mes: 'May', preeclampsia: 14, hemorragia: 4, sepsis: 1 }, // Pico actual
];

// 2. Datos Mockeados: Impacto SHAP (Factores de riesgo predominantes)
const datosShap = [
  { factor: 'Presión Sistólica', impacto: 0.85 },
  { factor: 'Edad Materna', impacto: 0.62 },
  { factor: 'Nivel Hemoglobina', impacto: 0.58 },
  { factor: 'Semanas Gestación', impacto: 0.45 },
  { factor: 'Presión Diastólica', impacto: 0.41 },
  { factor: 'Historial Cesáreas', impacto: 0.25 },
];

export default function Tendencias() {
  return (
    <div className="flex flex-col h-full w-full bg-fondoApp animate-fade-in overflow-hidden">
      
      {/* TOPBAR */}
      <header className="bg-white border-b border-slate-200 px-6 py-4 shrink-0">
        <h2 className="font-serif text-2xl font-bold text-slate-800">Análisis Poblacional y Tendencias</h2>
        <p className="text-xs text-slate-500 mt-0.5">Monitoreo epidemiológico e interpretabilidad del modelo predictivo (SHAP).</p>
      </header>

      <div className="flex-1 p-6 overflow-y-auto">
        <div className="max-w-6xl mx-auto space-y-6">

          {/* TARJETAS DE RESUMEN (KPIs Poblacionales) */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
              <div className="bg-red-50 p-3 rounded-xl"><TrendingUp className="text-red-600 w-6 h-6" /></div>
              <div>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Mayor incidencia mensual</p>
                <h3 className="text-xl font-bold text-slate-800">Preeclampsia <span className="text-sm font-medium text-slate-500">(14 casos)</span></h3>
              </div>
            </div>
            
            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
              <div className="bg-amber-50 p-3 rounded-xl"><AlertCircle className="text-amber-600 w-6 h-6" /></div>
              <div>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Factor crítico global</p>
                <h3 className="text-xl font-bold text-slate-800">Hipertensión <span className="text-sm font-medium text-slate-500">(SHAP 0.85)</span></h3>
              </div>
            </div>

            <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
              <div className="bg-green-50 p-3 rounded-xl"><Activity className="text-verdeApp w-6 h-6" /></div>
              <div>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Tasa de Confiabilidad ML</p>
                <h3 className="text-xl font-bold text-verdeOscuro">94.2% <span className="text-sm font-medium text-slate-500">(AUC-ROC)</span></h3>
              </div>
            </div>
          </div>

          {/* GRÁFICOS */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            
            {/* GRÁFICO 1: Curva Poblacional de Complicaciones */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm flex flex-col h-[400px]">
              <div className="mb-4">
                <h3 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                  <TrendingUp className="text-verdeApp w-4 h-4" /> Curva de Complicaciones (Detectadas por ML)
                </h3>
                <p className="text-[10px] text-slate-400 mt-1">Evolución de alertas críticas en la comunidad rural a lo largo del año.</p>
              </div>
              
              <div className="flex-1 w-full min-h-0">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={datosMensuales} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                    <XAxis dataKey="mes" axisLine={false} tickLine={false} tick={{fontSize: 11, fill: '#94a3b8'}} />
                    <YAxis axisLine={false} tickLine={false} tick={{fontSize: 11, fill: '#94a3b8'}} />
                    <Tooltip 
                      contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}
                      labelStyle={{fontWeight: 'bold', color: '#0f172a', marginBottom: '4px'}}
                    />
                    <Legend iconType="circle" wrapperStyle={{fontSize: '11px', paddingTop: '10px'}} />
                    <Line type="monotone" name="Preeclampsia" dataKey="preeclampsia" stroke="#ef4444" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
                    <Line type="monotone" name="Hemorragia" dataKey="hemorragia" stroke="#f59e0b" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
                    <Line type="monotone" name="Sepsis" dataKey="sepsis" stroke="#8b5cf6" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* GRÁFICO 2: Interpretabilidad SHAP (La joya de la tesis) */}
            <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm flex flex-col h-[400px]">
              <div className="mb-4">
                <h3 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                  <BarChart2 className="text-verdeApp w-4 h-4" /> Importancia de Variables (Valores SHAP)
                </h3>
                <p className="text-[10px] text-slate-400 mt-1">Factores que más contribuyen a las predicciones de riesgo del modelo LightGBM.</p>
              </div>
              
              <div className="flex-1 w-full min-h-0">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={datosShap} layout="vertical" margin={{ top: 10, right: 10, left: 30, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" horizontal={false} stroke="#f1f5f9" />
                    <XAxis type="number" hide />
                    <YAxis dataKey="factor" type="category" axisLine={false} tickLine={false} tick={{fontSize: 10, fill: '#475569', fontWeight: 600}} width={120} />
                    <Tooltip 
                      cursor={{fill: '#f8fafc'}}
                      contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'}}
                      formatter={(value) => [`${value} SHAP`, 'Impacto']}
                    />
                    <Bar dataKey="impacto" radius={[0, 6, 6, 0]} barSize={24}>
                      {
                        datosShap.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={index === 0 ? '#ef4444' : index === 1 ? '#f59e0b' : '#4C924F'} />
                        ))
                      }
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

          </div>
          
          <div className="text-center mt-4">
            <p className="text-[10px] text-slate-400 uppercase tracking-widest font-semibold">
              Modelo Predictivo: LightGBM • Método de Explicabilidad: SHAP (Shapley Additive Explanations)
            </p>
          </div>

        </div>
      </div>
    </div>
  );
}