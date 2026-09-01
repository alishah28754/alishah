import { useEffect, useState } from 'react';
import { Pencil, Plus } from 'lucide-react';
import { BannersApi } from '../api/resources';
import { Button, Card, Select, Loader, EmptyState } from '../components/ui';
import Modal from '../components/Modal';
import ImageUploadField from '../components/ImageUploadField';

// FIXED BANNERS - Only 3 banners, cannot add/delete. Title/subtitle/category are
// locked because the app's Home screen hardcodes navigation based on `category`
// (see lib/pages/home_page.dart -> Shop Now onTap). Only the image can change.
const FIXED_BANNER_COUNT = 3;

const FIXED_BANNER_SLOTS = [
  { category: 'Premium Collection', label: 'Premium Collection', title: 'Premium\nCollection', subtitle: 'Elevate your everyday style.' },
  { category: 'New Arrivals', label: 'New Arrivals', title: 'New \nArrivals', subtitle: 'Curated pieces, just landed.' },
  { category: 'Best Sellers', label: 'Best Seller Collection', title: 'Best Seller\nCollection', subtitle: 'Shop our most loved styles.' },
];

export default function Banners() {
  const [items, setItems] = useState(null);
  const [error, setError] = useState('');

  // Edit (change image) modal for an existing banner row
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({ image_url: '' });
  const [saving, setSaving] = useState(false);

  // Add Banner modal - pick which fixed slot + upload its image
  const [addModalOpen, setAddModalOpen] = useState(false);
  const [addSlotCategory, setAddSlotCategory] = useState(FIXED_BANNER_SLOTS[0].category);
  const [addImageUrl, setAddImageUrl] = useState('');
  const [addSaving, setAddSaving] = useState(false);
  const [addError, setAddError] = useState('');

  const load = () => BannersApi.list().then(setItems).catch((e) => setError(e.message));
  useEffect(() => { load(); }, []);

  const openEdit = (b) => {
    setEditing(b);
    setForm({ image_url: b.image_url });
    setModalOpen(true);
  };

  const save = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      // Only update the image, keep everything else same
      await BannersApi.update(editing.id, { 
        image_url: form.image_url,
        title: editing.title,
        subtitle: editing.subtitle,
        category: editing.category,
      });
      setModalOpen(false);
      await load();
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  // Fixed banner titles that cannot be changed
  const getBannerTitle = (index) => {
    const titles = [
      'Premium Polo Shirts',
      'New Arrivals',
      'Best Seller Collection'
    ];
    return titles[index] || `Banner ${index + 1}`;
  };

  const getBannerSubtitle = (index) => {
    const subtitles = [
      'Elevate your everyday style.',
      'Curated pieces, just landed.',
      'Shop our most loved styles.'
    ];
    return subtitles[index] || '';
  };

  const getBannerCategory = (index) => {
    const categories = [
      'Premium Collection',
      'New Arrivals',
      'Best Sellers'
    ];
    return categories[index] || '';
  };

  // ---- Add Banner: choose a fixed slot, upload its image only ----
  const openAddBanner = () => {
    setAddError('');
    setAddImageUrl('');
    setAddSlotCategory(FIXED_BANNER_SLOTS[0].category);
    setAddModalOpen(true);
  };

  const saveAddBanner = async (e) => {
    e.preventDefault();
    if (!addImageUrl) {
      setAddError('Please upload an image.');
      return;
    }
    setAddSaving(true);
    setAddError('');
    try {
      const slot = FIXED_BANNER_SLOTS.find((s) => s.category === addSlotCategory);
      const existing = items?.find((b) => (b.category || '') === slot.category);

      if (existing) {
        // Row already exists for this slot — only its image changes, title/subtitle/category stay fixed
        await BannersApi.update(existing.id, {
          image_url: addImageUrl,
          title: existing.title || slot.title,
          subtitle: existing.subtitle || slot.subtitle,
          category: slot.category,
        });
      } else {
        // No row yet for this slot — create it with the fixed title/subtitle/category
        // so "Shop Now" keeps linking to the right page in the app.
        await BannersApi.create({
          title: slot.title,
          subtitle: slot.subtitle,
          image_url: addImageUrl,
          category: slot.category,
        });
      }

      setAddModalOpen(false);
      await load();
    } catch (e) {
      setAddError(e.message);
    } finally {
      setAddSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl text-ink">Banners</h1>
          <p className="mt-1 text-sm text-muted">
            Fixed banners on the home screen. You can only change the images.
          </p>
        </div>
        <Button variant="gold" onClick={openAddBanner}>
          <Plus size={16} /> Add Banner
        </Button>
      </div>

      {error && <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{error}</p>}

      {!items ? (
        <Loader />
      ) : items.length === 0 ? (
        <Card>
          <EmptyState 
            title="No banners found" 
            description={'Click "Add Banner" to set an image for Premium Collection, New Arrivals, or Best Seller Collection.'} 
          />
        </Card>
      ) : (
        <div className="space-y-3">
          {items.slice(0, FIXED_BANNER_COUNT).map((b, index) => (
            <Card key={b.id} className="flex items-center gap-4 p-3">
              <div className="h-16 w-28 shrink-0 overflow-hidden rounded-lg bg-line">
                <img src={b.image_url} alt={b.title} className="h-full w-full object-cover" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-ink">
                  {b.title || getBannerTitle(index)}
                </p>
                <p className="truncate text-xs text-muted">
                  {b.subtitle || getBannerSubtitle(index)}
                </p>
                <p className="text-xs text-amber-600">
                  Links to: {b.category || getBannerCategory(index)}
                </p>
              </div>
              <div className="flex shrink-0 gap-1">
                <button onClick={() => openEdit(b)} className="rounded-lg bg-amber-100 px-3 py-1.5 text-sm font-medium text-amber-700 hover:bg-amber-200 flex items-center gap-1">
                  <Pencil size={14} /> Change Image
                </button>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Change image for an existing banner row */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={`Change banner image: ${editing?.title || ''}`}>
        <form onSubmit={save} className="space-y-4">
          <p className="text-sm text-muted">
            Only the image can be changed. The banner title, subtitle, and link remain fixed.
          </p>
          <ImageUploadField 
            label="Banner image" 
            type="banners" 
            value={form.image_url} 
            onChange={(url) => setForm({ ...form, image_url: url })} 
          />
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => setModalOpen(false)}>Cancel</Button>
            <Button type="submit" variant="gold" disabled={saving}>
              {saving ? 'Saving…' : 'Update Image'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* Add Banner: pick which fixed slot, upload its image only */}
      <Modal open={addModalOpen} onClose={() => setAddModalOpen(false)} title="Add Banner">
        <form onSubmit={saveAddBanner} className="space-y-4">
          <p className="text-sm text-muted">
            Choose which home screen banner to set. The title and "Shop Now" link are fixed for each — only the image is added.
          </p>

          {addError && <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{addError}</p>}

          <Select
            label="Banner"
            value={addSlotCategory}
            onChange={(e) => setAddSlotCategory(e.target.value)}
          >
            {FIXED_BANNER_SLOTS.map((slot) => (
              <option key={slot.category} value={slot.category}>{slot.label}</option>
            ))}
          </Select>

          <ImageUploadField
            label="Banner image"
            type="banners"
            value={addImageUrl}
            onChange={(url) => setAddImageUrl(url)}
          />

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => setAddModalOpen(false)}>Cancel</Button>
            <Button type="submit" variant="gold" disabled={addSaving}>
              {addSaving ? 'Saving…' : 'Save Banner'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
