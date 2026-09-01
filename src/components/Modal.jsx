import { X } from 'lucide-react';

export default function Modal({ open, onClose, title, children, width = 'max-w-lg' }) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-ink/40 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative flex max-h-[90vh] w-full ${width} flex-col rounded-2xl bg-white shadow-xl`}>
        <div className="flex shrink-0 items-center justify-between border-b border-mutedLight px-6 py-4">
          <h2 className="font-display text-xl text-ink">{title}</h2>
          <button onClick={onClose} className="rounded-full p-1.5 text-muted hover:bg-line hover:text-ink">
            <X size={18} />
          </button>
        </div>
        <div className="overflow-y-auto px-6 py-5">
          {children}
        </div>
      </div>
    </div>
  );
}
