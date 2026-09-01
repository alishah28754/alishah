import api from './client';

export const AuthApi = {
  login: (email, password) => api.post('/auth/login', { email, password }),
  me: () => api.get('/auth/me'),
  updateProfile: (data) => api.put('/auth/profile', data),
};

export const ProductsApi = {
  list: (params) => api.get('/products', { params }),
  get: (id) => api.get(`/products/${id}`),
  create: (data) => api.post('/products', data),
  update: (id, data) => api.put(`/products/${id}`, data),
  remove: (id) => api.delete(`/products/${id}`),
};

export const CategoriesApi = {
  list: () => api.get('/categories'),
  create: (data) => api.post('/categories', data),
  update: (id, data) => api.put(`/categories/${id}`, data),
  remove: (id) => api.delete(`/categories/${id}`),
};

export const BannersApi = {
  list: () => api.get('/banners'),
  create: (data) => api.post('/banners', data),
  update: (id, data) => api.put(`/banners/${id}`, data),
  remove: (id) => api.delete(`/banners/${id}`),
};

export const AdminApi = {
  stats: () => api.get('/admin/stats'),
  orders: (params) => api.get('/admin/orders', { params }),
  updateOrderStatus: (orderNumber, status) => api.put(`/admin/orders/${orderNumber}/status`, { status }),
  deleteOrder: (orderNumber) => api.delete(`/admin/orders/${orderNumber}`),
  users: () => api.get('/admin/users'),
  deleteUser: (id) => api.delete(`/admin/users/${id}`),
  toggleAdmin: (id) => api.put(`/admin/users/${id}/toggle-admin`),
  toggleActive: (id) => api.put(`/admin/users/${id}/toggle-active`),
};

export const UploadApi = {
  image: (file, type = 'products') => {
    const formData = new FormData();
    formData.append('image', file);
    return api.post(`/upload?type=${type}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
};

// Backward-compatible alias — some pages (Dashboard.jsx) import OrdersApi
// directly instead of going through AdminApi. Remove this once those
// pages are confirmed to use the exact method names below.
export const OrdersApi = {
  list: (params) => api.get('/admin/orders', { params }),
  updateStatus: (orderNumber, status) => api.put(`/admin/orders/${orderNumber}/status`, { status }),
};

// Backward-compatible alias — Dashboard.jsx imports UsersApi directly.
// Only `list` is safe to assume for a dashboard summary; delete/update
// go through AdminApi (see Users.jsx) since the backend only exposes
// toggle-admin / toggle-active, not a generic update.
export const UsersApi = {
  list: (params) => api.get('/admin/users', { params }),
};