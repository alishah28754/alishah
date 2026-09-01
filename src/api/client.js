import axios from 'axios';
import { TOKEN_KEY } from '../context/AuthContext';

const baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

const api = axios.create({ baseURL });

// Attach the current admin's login token (issued by our own backend on
// /auth/login) to every request.
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Unwrap the backend's { success, message, data } envelope,
// surface { success: false, message } as a normal thrown Error.
api.interceptors.response.use(
  (res) => res.data?.data,
  (err) => {
    const message = err.response?.data?.message || err.message || 'Request failed.';
    return Promise.reject(new Error(message));
  }
);

export default api;
