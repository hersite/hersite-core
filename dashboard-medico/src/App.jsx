import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Login from './pages/Login';
import Layout from './layouts/Layout';
import Dashboard from './pages/Dashboard';
import Configuracion from './pages/Configuracion';
import Gestantes from './pages/Gestantes';
import Tendencias from './pages/Tendencias'; // <-- 1. IMPORTAR TENDENCIAS

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Login />} />

        <Route element={<Layout />}>
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/configuracion" element={<Configuracion />} />
          <Route path="/gestantes" element={<Gestantes />} />
          <Route path="/tendencias" element={<Tendencias />} /> {/* <-- 2. AÑADIR LA RUTA */}
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;