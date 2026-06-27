import { Navigate, Outlet } from 'react-router-dom';

import { existeSesionWeb } from '../services/auth';

export default function ProtectedRoute() {
  if (!existeSesionWeb()) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
}