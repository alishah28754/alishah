// admin/src/pages/Users.jsx
import { useEffect, useMemo, useState } from 'react';
import { Search, UserCheck, UserX, ShieldCheck, Shield, Trash2 } from 'lucide-react';
import { AdminApi } from '../api/resources';
import { Button, Card, Loader, EmptyState, Badge } from '../components/ui';
import ConfirmDialog from '../components/ConfirmDialog';

export default function Users() {
  const [users, setUsers] = useState(null);
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  const load = () => {
    setError('');
    AdminApi.users()
      .then(setUsers)
      .catch((e) => setError(e.message));
  };

  useEffect(() => { load(); }, []);

  const confirmDelete = async () => {
    setDeleting(true);
    try {
      await AdminApi.deleteUser(deleteTarget.id);
      setDeleteTarget(null);
      load();
    } catch (e) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  const toggleUserActive = async (user) => {
    try {
      await AdminApi.toggleActive(user.id);
      load();
    } catch (e) {
      setError(e.message);
    }
  };

  const toggleUserAdmin = async (user) => {
    try {
      await AdminApi.toggleAdmin(user.id);
      load();
    } catch (e) {
      setError(e.message);
    }
  };

  const formatDate = (date) => {
    if (!date) return '—';
    return new Date(date).toLocaleDateString('en-US', {
      year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
    });
  };

  const visibleUsers = useMemo(() => {
    if (!users) return null;
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) => u.name?.toLowerCase().includes(q) || u.email?.toLowerCase().includes(q)
    );
  }, [users, search]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl text-ink">Users</h1>
          <p className="mt-1 text-sm text-muted">
            Everyone who has signed up or logged into the app — {users?.length ?? '…'} total.
          </p>
        </div>
      </div>

      <div className="relative max-w-sm">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          className="w-full rounded-lg border border-mutedLight bg-white py-2 pl-9 pr-3 text-sm focus:border-ink focus:outline-none"
          placeholder="Search users…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {error && <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{error}</p>}

      {!visibleUsers ? (
        <Loader />
      ) : visibleUsers.length === 0 ? (
        <Card>
          <EmptyState
            title="No users yet"
            description="Users will appear here as soon as they sign up or log into the app."
          />
        </Card>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-line bg-cream/50 text-xs uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3 font-medium">User</th>
                  <th className="px-4 py-3 font-medium">Email</th>
                  <th className="px-4 py-3 font-medium">Provider</th>
                  <th className="px-4 py-3 font-medium">Logins</th>
                  <th className="px-4 py-3 font-medium">Last Login</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {visibleUsers.map((user) => (
                  <tr key={user.id} className="border-b border-line last:border-0 hover:bg-cream/40">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        {user.profile_image ? (
                          <img src={user.profile_image} alt={user.name} className="h-10 w-10 rounded-full object-cover" />
                        ) : (
                          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 text-amber-700">
                            {user.name?.charAt(0)?.toUpperCase() || 'U'}
                          </div>
                        )}
                        <div>
                          <p className="font-medium text-ink">{user.name}</p>
                          <p className="text-xs text-muted">ID: {user.id}{user.is_admin ? ' · Admin' : ''}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-muted">{user.email || '—'}</td>
                    <td className="px-4 py-3">
                      <Badge tone={user.provider === 'google' ? 'blue' : 'default'}>
                        {user.provider === 'google' ? 'Google' : 'Email'}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-muted">{user.login_count || 0}</td>
                    <td className="px-4 py-3 text-xs text-muted">{formatDate(user.last_login)}</td>
                    <td className="px-4 py-3">
                      <Badge tone={user.is_active ? 'green' : 'red'}>{user.is_active ? 'Active' : 'Inactive'}</Badge>
                      {user.is_email_verified ? (
                        <Badge tone="blue" className="ml-1">Verified</Badge>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex justify-end gap-1">
                        <button
                          onClick={() => toggleUserAdmin(user)}
                          className="rounded-lg p-1.5 text-muted hover:bg-line hover:text-ink"
                          title={user.is_admin ? 'Remove admin' : 'Make admin'}
                        >
                          {user.is_admin ? <ShieldCheck size={15} /> : <Shield size={15} />}
                        </button>
                        <button
                          onClick={() => toggleUserActive(user)}
                          className="rounded-lg p-1.5 text-muted hover:bg-line hover:text-ink"
                          title={user.is_active ? 'Deactivate' : 'Activate'}
                        >
                          {user.is_active ? <UserX size={15} /> : <UserCheck size={15} />}
                        </button>
                        <button
                          onClick={() => setDeleteTarget(user)}
                          className="rounded-lg p-1.5 text-muted hover:bg-red-50 hover:text-danger"
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        loading={deleting}
        title="Delete user?"
        description={`"${deleteTarget?.name}" will be permanently removed.`}
      />
    </div>
  );
}
