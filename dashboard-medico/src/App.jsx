import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { useEffect, useState } from 'react';
import { restaurarSesionWeb } from './services/auth';

import ProtectedRoute from './components/ProtectedRoute';
import Layout from './layouts/Layout';

import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Configuracion from './pages/Configuracion';
import Gestantes from './pages/Gestantes';
import Tendencias from './pages/Tendencias';

function App() {
  const [comprobando, setComprobando] = useState(true);
  useEffect(() => {
    let activo = true;
    restaurarSesionWeb().catch(() => {}).finally(() => { if (activo) setComprobando(false); });
    return () => { activo = false; };
  }, []);
  if (comprobando) return <div role="status" className="p-8 text-center text-green-800">Verificando sesión…</div>;
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />

        <Route element={<ProtectedRoute />}>
          <Route element={<Layout />}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/gestantes" element={<Gestantes />} />
            <Route path="/tendencias" element={<Tendencias />} />
            <Route path="/configuracion" element={<Configuracion />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
