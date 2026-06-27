import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import ProtectedRoute from './components/ProtectedRoute';
import Layout from './layouts/Layout';

import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Configuracion from './pages/Configuracion';
import Gestantes from './pages/Gestantes';
import Tendencias from './pages/Tendencias';

function App() {
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