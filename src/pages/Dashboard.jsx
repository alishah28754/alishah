// admin/src/pages/Dashboard.jsx
import { useEffect, useState } from 'react';
import { UsersApi, OrdersApi, ProductsApi } from '../api/resources';
import { Card, Loader } from '../components/ui';
import { 
  ShoppingBag, Users as UsersIcon, 
  Package, CheckCircle, Clock, 
  TrendingUp, Wifi, UserCheck
} from 'lucide-react';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [recentOrders, setRecentOrders] = useState([]);
  const [userStats, setUserStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = async () => {
    setLoading(true);
    setError('');
    try {
      // Fetch all data in parallel
      const [ordersData, productsData, usersData] = await Promise.all([
        OrdersApi.list({ limit: 5 }),
        ProductsApi.list({ limit: 100 }),
        UsersApi.list({ limit: 100 }),
      ]);

      // Handle orders data - could be array or object with data property
      const orders = Array.isArray(ordersData) ? ordersData : ordersData?.data || [];
      const totalOrders = ordersData?.total || orders.length;
      
      setRecentOrders(orders.slice(0, 5));
      
      // Handle products data
      const products = Array.isArray(productsData) ? productsData : productsData?.items || [];
      const totalProducts = productsData?.total || products.length;
      
      // Handle users data
      const users = Array.isArray(usersData) ? usersData : usersData?.data || [];
      const activeUsers = users.filter(u => u.is_active).length;
      
      setStats({
        totalOrders,
        totalProducts,
      });

      setUserStats({
        total_users: users.length,
        active_users: activeUsers,
        new_today: 0, // Would need separate API endpoint for daily new users
      });
    } catch (error) {
      console.error('Error loading dashboard:', error);
      setError(error.message || 'Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
    
    // Refresh data every 30 seconds for real-time updates
    const interval = setInterval(loadData, 30000);
    return () => clearInterval(interval);
  }, []);

  if (loading) return <Loader />;

  if (error) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="font-display text-3xl text-ink">Dashboard</h1>
          <p className="mt-1 text-sm text-muted">Overview of orders and store health.</p>
        </div>
        <Card className="p-6 text-center">
          <p className="text-danger">{error}</p>
          <button 
            onClick={loadData} 
            className="mt-4 rounded-lg bg-gold px-4 py-2 text-sm font-medium text-ink hover:bg-gold-dark hover:text-white"
          >
            Retry
          </button>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl text-ink">Dashboard</h1>
          <p className="mt-1 text-sm text-muted">Overview of orders and store health.</p>
        </div>
        <button 
          onClick={loadData} 
          className="rounded-lg border border-mutedLight px-3 py-1.5 text-sm text-muted hover:bg-line transition-colors"
        >
          Refresh
        </button>
      </div>

      {/* Stats Grid - Only Total Orders and Products */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-2">
        <StatCard
          icon={<ShoppingBag size={20} />}
          label="Total Orders"
          value={stats?.totalOrders || 0}
          color="gold"
        />
        <StatCard
          icon={<Package size={20} />}
          label="Products"
          value={stats?.totalProducts || 0}
          color="blue"
        />
      </div>

      {/* Users Stats */}
      {userStats && (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3">
          <StatCard
            icon={<UsersIcon size={20} />}
            label="Total Users"
            value={userStats.total_users || 0}
            color="purple"
          />
          <StatCard
            icon={<TrendingUp size={20} />}
            label="New Today"
            value={userStats.new_today || 0}
            color="blue"
          />
          <StatCard
            icon={<UserCheck size={20} />}
            label="Active Users"
            value={userStats.active_users || 0}
            color="green"
          />
        </div>
      )}

      {/* Recent Orders - Fixed spacing */}
      <Card className="p-6">
        <h2 className="mb-4 text-lg font-semibold text-ink">Recent Orders</h2>
        {recentOrders.length === 0 ? (
          <p className="text-sm text-muted">No recent orders</p>
        ) : (
          <div className="space-y-4">
            {recentOrders.map((order) => (
              <div key={order.id || order.order_number} className="flex items-center justify-between border-b border-line pb-4 last:border-0 last:pb-0">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-ink truncate">{order.order_number || order.id}</p>
                  <p className="text-xs text-muted truncate">{order.customer_name || order.email || 'Guest'}</p>
                </div>
                <div className="flex items-center gap-4 ml-4 flex-shrink-0">
                  <span className="text-sm font-medium text-ink whitespace-nowrap">PKR {order.total}</span>
                  <Badge tone={getStatusTone(order.status)}>
                    {order.status?.toUpperCase() || 'PENDING'}
                  </Badge>
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* Store Info */}
      <Card className="p-6">
        <h2 className="mb-4 text-lg font-semibold text-ink">Store Info</h2>
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <InfoItem label="Total Products" value={stats?.totalProducts || 0} />
          <InfoItem 
            label="Backend Status" 
            value="Online" 
            icon={<Wifi size={14} className="text-green-500" />}
          />
          <InfoItem label="Order Mode" value="Live Database" />
          <InfoItem label="Total Users" value={userStats?.total_users || 0} />
        </div>
      </Card>
    </div>
  );
}

function StatCard({ icon, label, value, color }) {
  const colors = {
    gold: 'bg-amber-100 text-amber-700',
    orange: 'bg-orange-100 text-orange-700',
    green: 'bg-green-100 text-green-700',
    blue: 'bg-blue-100 text-blue-700',
    purple: 'bg-purple-100 text-purple-700',
  };

  return (
    <Card className="p-4">
      <div className="flex items-center gap-3">
        <div className={`rounded-lg p-2.5 ${colors[color] || colors.gold}`}>
          {icon}
        </div>
        <div>
          <p className="text-2xl font-bold text-ink">{value}</p>
          <p className="text-xs text-muted">{label}</p>
        </div>
      </div>
    </Card>
  );
}

function Badge({ children, tone = 'default' }) {
  const colors = {
    default: 'bg-gray-100 text-gray-700',
    green: 'bg-green-100 text-green-700',
    blue: 'bg-blue-100 text-blue-700',
    red: 'bg-red-100 text-red-700',
    orange: 'bg-orange-100 text-orange-700',
    gold: 'bg-amber-100 text-amber-700',
    purple: 'bg-purple-100 text-purple-700',
  };

  return (
    <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${colors[tone]}`}>
      {children}
    </span>
  );
}

function InfoItem({ label, value, icon }) {
  return (
    <div className="rounded-lg bg-cream/30 p-3">
      <p className="text-xs text-muted">{label}</p>
      <div className="flex items-center gap-1.5">
        {icon}
        <p className="text-sm font-medium text-ink">{value}</p>
      </div>
    </div>
  );
}

// Helper function to determine badge color based on order status
function getStatusTone(status) {
  if (!status) return 'default';
  const lowerStatus = status.toLowerCase();
  if (lowerStatus === 'delivered') return 'green';
  if (lowerStatus === 'processing' || lowerStatus === 'confirmed') return 'blue';
  if (lowerStatus === 'shipped') return 'gold';
  if (lowerStatus === 'cancelled') return 'red';
  return 'default';
}