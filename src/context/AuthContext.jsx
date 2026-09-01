import { createContext, useContext, useEffect, useState } from 'react';
import { AuthApi } from '../api/resources';

const AuthContext = createContext(null);
export const TOKEN_KEY = 'ktex_admin_token';

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem(TOKEN_KEY));
  const [profile, setProfile] = useState(null); // synced row from MySQL { id, email, is_admin, ... }
  const [loading, setLoading] = useState(true); // checking existing session on load
  const [error, setError] = useState(null);

  // On mount (or whenever the token changes), ask the backend who this
  // token belongs to. This replaces Firebase's onAuthStateChanged.
  useEffect(() => {
    let cancelled = false;

    (async () => {
      if (!token) {
        setProfile(null);
        setLoading(false);
        return;
      }
      try {
        const me = await AuthApi.me();
        if (!cancelled) setProfile(me);
      } catch (e) {
        // token missing/expired/invalid -> drop it
        if (!cancelled) {
          setProfile(null);
          setToken(null);
          localStorage.removeItem(TOKEN_KEY);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [token]);

  const login = async (email, password) => {
    setError(null);
    try {
      // Backend looks the email up in the users/admins table, checks the
      // password hash, and if is_admin = 1 returns { token, user }.
      const { token: newToken, user } = await AuthApi.login(email, password);
      localStorage.setItem(TOKEN_KEY, newToken);
      setToken(newToken);
      setProfile(user);
    } catch (e) {
      setError(e.message || 'Invalid email or password.');
      throw e;
    }
  };

  const logout = () => {
    localStorage.removeItem(TOKEN_KEY);
    setToken(null);
    setProfile(null);
  };

  const value = {
    user: profile,
    profile,
    isAdmin: !!profile?.is_admin,
    loading,
    error,
    login,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
