export function Button({ variant = 'primary', className = '', children, ...props }) {
  const base = 'inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed';
  const variants = {
    primary: 'bg-ink text-white hover:bg-black',
    gold: 'bg-gold text-ink hover:bg-gold-dark hover:text-white',
    ghost: 'bg-transparent text-ink hover:bg-line',
    danger: 'bg-danger text-white hover:bg-red-600',
    outline: 'border border-mutedLight text-ink hover:bg-line',
  };
  return (
    <button className={`${base} ${variants[variant]} ${className}`} {...props}>
      {children}
    </button>
  );
}

export function Input({ label, className = '', ...props }) {
  return (
    <label className="block text-sm">
      {label && <span className="mb-1.5 block font-medium text-ink">{label}</span>}
      <input
        className={`w-full rounded-lg border border-mutedLight bg-white px-3 py-2 text-sm text-ink placeholder:text-muted focus:border-ink focus:outline-none focus:ring-1 focus:ring-ink ${className}`}
        {...props}
      />
    </label>
  );
}

export function Select({ label, className = '', children, ...props }) {
  return (
    <label className="block text-sm">
      {label && <span className="mb-1.5 block font-medium text-ink">{label}</span>}
      <select
        className={`w-full rounded-lg border border-mutedLight bg-white px-3 py-2 text-sm text-ink focus:border-ink focus:outline-none focus:ring-1 focus:ring-ink ${className}`}
        {...props}
      >
        {children}
      </select>
    </label>
  );
}

export function Textarea({ label, className = '', ...props }) {
  return (
    <label className="block text-sm">
      {label && <span className="mb-1.5 block font-medium text-ink">{label}</span>}
      <textarea
        className={`w-full rounded-lg border border-mutedLight bg-white px-3 py-2 text-sm text-ink placeholder:text-muted focus:border-ink focus:outline-none focus:ring-1 focus:ring-ink ${className}`}
        {...props}
      />
    </label>
  );
}

export function Card({ className = '', children }) {
  return <div className={`rounded-2xl border border-line bg-white shadow-card ${className}`}>{children}</div>;
}

export function Badge({ tone = 'default', children }) {
  const tones = {
    default: 'bg-line text-ink',
    gold: 'bg-gold-soft text-gold-dark',
    green: 'bg-emerald-100 text-emerald-700',
    red: 'bg-red-100 text-red-700',
    blue: 'bg-blue-100 text-blue-700',
  };
  return (
    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-medium ${tones[tone]}`}>
      {children}
    </span>
  );
}

export function Loader({ label = 'Loading…' }) {
  return (
    <div className="flex items-center justify-center gap-2 py-16 text-muted">
      <span className="h-4 w-4 animate-spin rounded-full border-2 border-mutedLight border-t-ink" />
      <span className="text-sm">{label}</span>
    </div>
  );
}

export function EmptyState({ title, description, action }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      <div className="text-lg font-medium text-ink">{title}</div>
      {description && <div className="max-w-sm text-sm text-muted">{description}</div>}
      {action}
    </div>
  );
}
