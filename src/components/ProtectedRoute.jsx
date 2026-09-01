import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Loader } from './ui';

export default function ProtectedRoute({ children }) {
  const { user, loading, isAdmin, logout } = useAuth();

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-cream">
        <Loader label="Checking your session…" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (!isAdmin) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-cream px-4 text-center">
        <h1 className="font-display text-2xl text-ink">Access restricted</h1>
        <p className="max-w-sm text-sm text-muted">
          This account is not an admin. Ask an existing admin to run:
          <br />
          <code className="mt-2 block rounded bg-line px-2 py-1 text-xs">
            UPDATE users SET is_admin = 1 WHERE email = '{user?.email}';
          </code>
        </p>
        <button onClick={logout} className="text-sm font-medium text-ink underline">
          Log out
        </button>
      </div>
    );
  }

  return children;
}
