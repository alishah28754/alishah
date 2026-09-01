// admin/src/layouts/AdminLayout.jsx
import { NavLink, Outlet } from 'react-router-dom';
import {
  LayoutDashboard, Shirt, FolderTree, Image, Package, Users, LogOut,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const NAV = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, end: true },
  { to: '/products', label: 'Products', icon: Shirt },
  { to: '/categories', label: 'Categories', icon: FolderTree },
  { to: '/banners', label: 'Banners', icon: Image },
  { to: '/orders', label: 'Orders', icon: Package },
  { to: '/users', label: 'Users', icon: Users },
];

export default function AdminLayout() {
  const { profile, logout } = useAuth();

  return (
    <div className="flex min-h-screen bg-cream">
      <aside className="flex w-64 shrink-0 flex-col border-r border-line bg-ink text-white">
        <div className="flex items-center gap-2 px-6 py-6">
          <span className="font-display text-2xl tracking-wide text-gold">KTEX</span>
          <span className="text-xs font-medium uppercase tracking-widest text-white/40">Admin</span>
        </div>

        <nav className="flex-1 space-y-1 px-3">
          {NAV.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive ? 'bg-white/10 text-gold' : 'text-white/70 hover:bg-white/5 hover:text-white'
                }`
              }
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-white/10 px-3 py-4">
          <div className="mb-2 px-3">
            <p className="truncate text-sm font-medium text-white">{profile?.name || 'Admin'}</p>
            <p className="truncate text-xs text-white/50">{profile?.email}</p>
          </div>
          <button
            onClick={logout}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-white/70 hover:bg-white/5 hover:text-white"
          >
            <LogOut size={18} />
            Log out
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-y-auto">
        <div className="mx-auto max-w-6xl px-8 py-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}