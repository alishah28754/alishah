import { useEffect, useState } from 'react';
import { Eye, Trash2 } from 'lucide-react';
import { AdminApi } from '../api/resources';
import { Card, Select, Loader, EmptyState, Badge, Button } from '../components/ui';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';

const STATUSES = ['Processing', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];
const STATUS_TONE = {
  Processing: 'default', Confirmed: 'blue', Shipped: 'gold', Delivered: 'green', Cancelled: 'red',
};

export default function Orders() {
  const [items, setItems] = useState(null);
  const [statusFilter, setStatusFilter] = useState('');
  const [error, setError] = useState('');
  const [selected, setSelected] = useState(null);
  const [updating, setUpdating] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  const load = () =>
    AdminApi.orders(statusFilter ? { status: statusFilter } : {}).then(setItems).catch((e) => setError(e.message));

  useEffect(() => { load(); }, [statusFilter]);

  const updateStatus = async (orderNumber, status) => {
    setUpdating(true);
    setError('');
    try {
      await AdminApi.updateOrderStatus(orderNumber, status);
      await load();
      setSelected((s) => (s ? { ...s, status } : s));
    } catch (e) {
      setError(e.message);
    } finally {
      setUpdating(false);
    }
  };

  const confirmDelete = async () => {
    setDeleting(true);
    setError('');
    try {
      // Admin can delete any Cancelled or Delivered order, regardless of
      // who placed it (guest or logged-in) — the backend's isAdmin check
      // bypasses the normal ownership restriction for admin tokens.
      await AdminApi.deleteOrder(deleteTarget.order_number);
      setDeleteTarget(null);
      setSelected(null);
      await load();
    } catch (e) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl text-ink">Orders</h1>
          <p className="mt-1 text-sm text-muted">Every order placed on the app, in real time.</p>
        </div>
        <Select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="w-44">
          <option value="">All statuses</option>
          {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
        </Select>
      </div>

      {error && <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{error}</p>}

      {!items ? (
        <Loader />
      ) : items.length === 0 ? (
        <Card><EmptyState title="No orders yet" description="Orders placed on the app will show up here." /></Card>
      ) : (
        <Card className="overflow-hidden">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-line bg-cream/50 text-xs uppercase tracking-wide text-muted">
              <tr>
                <th className="px-4 py-3 font-medium">Order</th>
                <th className="px-4 py-3 font-medium">Customer</th>
                <th className="px-4 py-3 font-medium">Total</th>
                <th className="px-4 py-3 font-medium">Payment</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Date</th>
                <th className="px-4 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {items.map((o) => (
                <tr key={o.order_number} className="border-b border-line last:border-0 hover:bg-cream/40">
                  <td className="px-4 py-3 font-medium text-ink">{o.order_number}</td>
                  <td className="px-4 py-3 text-muted">{o.customer_name}</td>
                  <td className="px-4 py-3 font-medium text-ink">Rs {o.total}</td>
                  <td className="px-4 py-3 uppercase text-muted">{o.payment}</td>
                  <td className="px-4 py-3"><Badge tone={STATUS_TONE[o.status]}>{o.status}</Badge></td>
                  <td className="px-4 py-3 text-muted">{new Date(o.date).toLocaleDateString()}</td>
                  <td className="px-4 py-3 text-right">
                    <button onClick={() => setSelected(o)} className="rounded-lg p-1.5 text-muted hover:bg-line hover:text-ink"><Eye size={15} /></button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}

      <Modal open={!!selected} onClose={() => setSelected(null)} title={selected?.order_number} width="max-w-lg">
        {selected && (
          <div className="space-y-5">
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div><p className="text-muted">Customer</p><p className="font-medium text-ink">{selected.customer_name}</p></div>
              <div><p className="text-muted">Phone</p><p className="font-medium text-ink">{selected.phone}</p></div>
              <div><p className="text-muted">Email</p><p className="font-medium text-ink">{selected.email}</p></div>
              <div><p className="text-muted">City</p><p className="font-medium text-ink">{selected.city}</p></div>
              <div className="col-span-2"><p className="text-muted">Address</p><p className="font-medium text-ink">{selected.address}</p></div>
            </div>

            {selected.transaction_screenshot_url && (
              <div>
                <p className="mb-2 text-sm font-medium text-ink">Transaction Screenshot</p>
                <a
                  href={selected.transaction_screenshot_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block overflow-hidden rounded-lg border border-line"
                  title="Click to view full size"
                >
                  <img
                    src={selected.transaction_screenshot_url}
                    alt="Transaction screenshot"
                    className="max-h-72 w-full object-contain bg-cream/30"
                  />
                </a>
              </div>
            )}

            <div>
              <p className="mb-2 text-sm font-medium text-ink">Items</p>
              <div className="space-y-2">
                {selected.orderItems?.map((it, i) => (
                  <div key={i} className="flex items-center gap-3 rounded-lg border border-line p-2">
                    <img src={it.imageUrl} alt="" className="h-10 w-10 rounded-lg object-cover" />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-ink">{it.name}</p>
                      <p className="text-xs text-muted">Qty {it.quantity} × Rs {it.price}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-between rounded-lg bg-cream px-4 py-3">
              <span className="text-sm font-medium text-ink">Total</span>
              <span className="font-display text-lg text-ink">Rs {selected.total}</span>
            </div>

            <div>
              <span className="mb-1.5 block text-sm font-medium text-ink">Update status</span>
              <Select value={selected.status} disabled={updating} onChange={(e) => updateStatus(selected.order_number, e.target.value)}>
                {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
              </Select>
            </div>

            {(selected.status === 'Cancelled' || selected.status === 'Delivered') && (
              <div className="border-t border-line pt-4">
                <Button
                  variant="danger"
                  className="w-full"
                  disabled={deleting}
                  onClick={() => setDeleteTarget(selected)}
                >
                  <Trash2 size={14} /> Delete Order Permanently
                </Button>
              </div>
            )}
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        loading={deleting}
        title="Delete order?"
        description={`"${deleteTarget?.order_number}" will be permanently removed. This cannot be undone.`}
      />
    </div>
  );
}
