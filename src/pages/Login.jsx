import { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Button, Input } from '../components/ui';

export default function Login() {
  const { login, error: authError, user, isAdmin, loading } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading2, setLoading2] = useState(false);
  const [localError, setLocalError] = useState('');

  if (!loading && user && isAdmin) {
    return <Navigate to="/" replace />;
  }

  const submit = async (e) => {
    e.preventDefault();
    setLocalError('');
    setLoading2(true);
    try {
      await login(email, password);
    } catch (e) {
      // AuthContext already sets a friendly error
    } finally {
      setLoading2(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-ink px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 text-center">
          <span className="font-display text-4xl tracking-wide text-gold">KTEX</span>
          <p className="mt-1 text-sm text-white/50">Admin Panel</p>
        </div>

        <form onSubmit={submit} className="rounded-2xl bg-white p-6 shadow-xl">
          <h1 className="mb-1 font-display text-xl text-ink">Welcome back</h1>
          <p className="mb-6 text-sm text-muted">Sign in with your KTEX admin account.</p>

          <div className="space-y-4">
            <Input
              label="Email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@ktexstore.com"
              autoFocus
            />
            <Input
              label="Password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </div>

          {(authError || localError) && (
            <p className="mt-4 rounded-lg bg-red-50 px-3 py-2 text-sm text-danger">
              {authError || localError}
            </p>
          )}

          <Button type="submit" variant="gold" className="mt-6 w-full" disabled={loading2}>
            {loading2 ? 'Signing in…' : 'Sign in'}
          </Button>

          
        </form>
      </div>
    </div>
  );
}
