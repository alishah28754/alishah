// admin/src/pages/Products.jsx
import { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, Search } from 'lucide-react';
import { ProductsApi, CategoriesApi } from '../api/resources';
import { Button, Card, Input, Select, Textarea, Loader, EmptyState, Badge } from '../components/ui';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import ImageUploadField from '../components/ImageUploadField';

// ✅ ONLY Men, Women, Kids in dropdown
const CATEGORY_OPTIONS = [
  { id: 'men', name: 'Men', label: 'Men' },
  { id: 'women', name: 'Women', label: 'Women' },
  { id: 'kids', name: 'Kids', label: 'Kids' },
];

// ✅ Features - New Arrivals, Best Sellers, Premium are here
const FIXED_FEATURES = [
  { key: 'is_new_arrival', label: 'New Arrivals' },
  { key: 'is_best_seller', label: 'Best Sellers' },
  { key: 'is_premium', label: 'Premium' },
  { key: 'is_collection', label: 'Collection' },
  { key: 'is_flash_sale', label: 'Flash Sale' },
  { key: 'is_for_you', label: 'For You' },
];

const emptyForm = {
  name: '',
  original_price: '',
  discount_percent: '',
  sold_label: '',
  is_premium: false,
  category: '',
  subcategory_id: '',
  description: '',
  stock: '',
  // Multiple color variants — each has its own color + its own set of
  // images, plus one OPTIONAL video (file upload or a pasted URL, e.g. a
  // Cloudinary/YouTube/Vimeo/mp4 link). Selecting a color on the app swaps
  // the gallery (and video, if set) to that variant's media. Starts with
  // one blank variant so the form always has somewhere to upload into.
  colorVariants: [{ name: '', hex: '#000000', images: [], video: '' }],
  is_new_arrival: false,
  is_best_seller: false,
  is_collection: false,
  is_flash_sale: false,
  is_for_you: false,
};

// The product's color variants are stored in the existing "colors" column
// as an array: [{ name, hex, images: [...] }, ...] — one entry per color,
// each with its own images. Products may come back from the API with
// colors as an actual array, or as a JSON string (depending on how the
// column is stored) — normalize either, and migrate older products that
// only had a single `image_url` per entry into the `images` array so
// nothing breaks for existing data.
const parseProductColors = (value, fallbackImageUrl) => {
  let arr = [];
  if (Array.isArray(value)) arr = value;
  else if (typeof value === 'string' && value.trim()) {
    try {
      const parsed = JSON.parse(value);
      arr = Array.isArray(parsed) ? parsed : [];
    } catch {
      arr = [];
    }
  }
  const variants = arr.map((entry) => {
    let images = Array.isArray(entry.images) ? entry.images.filter(Boolean) : [];
    // Backward compatibility: old products only had `image_url` per color.
    if (images.length === 0 && entry.image_url) images = [entry.image_url];
    return {
      name: entry.name || '',
      hex: entry.hex || '#000000',
      images,
      // Optional per-color video. Accept either key so older saves that
      // used `video_url` still round-trip correctly.
      video: entry.video || entry.video_url || '',
    };
  });
  if (variants.length > 0) return variants;
  // Very old products had no colors array at all, just a top-level
  // image_url — surface that as a single blank-named variant so it's not
  // lost when opening the product for edit.
  if (fallbackImageUrl) {
    return [{ name: '', hex: '#000000', images: [fallbackImageUrl], video: '' }];
  }
  return [{ name: '', hex: '#000000', images: [], video: '' }];
};

export default function Products() {
  const [items, setItems] = useState(null);
  const [search, setSearch] = useState('');
  const [error, setError] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  // Draft text for the "paste a video URL" input per variant — kept
  // separate from form.colorVariants so typing doesn't commit a
  // half-typed URL as the variant's video on every keystroke. Committed
  // via the "Add" button or Enter.
  const [videoUrlDrafts, setVideoUrlDrafts] = useState({});

  // ✅ Subcategories (Men/Women/Kids > Polo, Round Neck, etc.), managed inline here
  const [categories, setCategories] = useState([]);
  const [newSubName, setNewSubName] = useState('');
  const [addingSub, setAddingSub] = useState(false);

  const loadCategories = () =>
    CategoriesApi.list()
      .then(setCategories)
      .catch(() => {}); // non-fatal — subcategory picker just stays empty

  const load = (params = {}) =>
    ProductsApi.list({ limit: 100, ...params })
      .then((res) => setItems(res.items))
      .catch((e) => setError(e.message));

  useEffect(() => { load(); loadCategories(); }, []);

  useEffect(() => {
    const t = setTimeout(() => load(search ? { search } : {}), 350);
    return () => clearTimeout(t);
  }, [search]);

  // The parent category row for whatever's selected in the form (e.g. "Men")
  const selectedParent = categories.find(
    (c) => !c.parent_id && c.name === form.category
  );

  // Subcategories that belong to the selected parent category
  const subcategoryOptions = selectedParent
    ? categories.filter((c) => String(c.parent_id) === String(selectedParent.id))
    : [];

  // Looks up a subcategory's display name from its id, for the product
  // table below — `categories` already holds every subcategory (loaded via
  // loadCategories()), so no extra fetch is needed per row.
  const getSubcategoryName = (subcategoryId) => {
    if (!subcategoryId) return null;
    const sub = categories.find((c) => String(c.id) === String(subcategoryId));
    return sub ? sub.name : null;
  };

  const addSubcategory = async () => {
    const name = newSubName.trim();
    if (!name || !selectedParent) return;
    setAddingSub(true);
    setError('');
    try {
      const created = await CategoriesApi.create({ name, parent_id: selectedParent.id });
      setCategories((prev) => [...prev, created]);
      setForm((prev) => ({ ...prev, subcategory_id: created.id }));
      setNewSubName('');
    } catch (e) {
      setError(e.message || 'Failed to create subcategory');
    } finally {
      setAddingSub(false);
    }
  };

  const calculatePrice = (originalPrice, discountPercent) => {
    if (!originalPrice || originalPrice <= 0) return '';
    if (!discountPercent || discountPercent <= 0) return originalPrice;
    const discount = (originalPrice * discountPercent) / 100;
    return Math.round(originalPrice - discount);
  };

  const handleFormChange = (key, value) => {
    setForm((prev) => {
      const updated = { ...prev, [key]: value };

      if (key === 'original_price' || key === 'discount_percent') {
        const orig = Number(updated.original_price) || 0;
        const disc = Number(updated.discount_percent) || 0;
        if (orig > 0 && disc > 0) {
          updated.price = calculatePrice(orig, disc);
        } else if (orig > 0) {
          updated.price = orig;
        } else {
          updated.price = '';
        }
      }

      if (key === 'category') {
        updated.subcategory_id = '';
      }

      return updated;
    });
  };

  // Add a new blank color variant — the admin fills in its color + images.
  const addColorVariant = () => {
    setForm((prev) => ({
      ...prev,
      colorVariants: [...prev.colorVariants, { name: '', hex: '#000000', images: [], video: '' }],
    }));
  };

  // Remove a color variant entirely (keeps at least one so the form
  // always has somewhere to upload into).
  const removeColorVariant = (variantIndex) => {
    setForm((prev) => {
      if (prev.colorVariants.length <= 1) return prev;
      return {
        ...prev,
        colorVariants: prev.colorVariants.filter((_, i) => i !== variantIndex),
      };
    });
  };

  // Update the name or hex of a single color variant.
  const updateVariantField = (variantIndex, key, value) => {
    setForm((prev) => ({
      ...prev,
      colorVariants: prev.colorVariants.map((v, i) =>
        i === variantIndex ? { ...v, [key]: value } : v
      ),
    }));
  };

  // Append a newly uploaded image to one variant's image list.
  const addVariantImage = (variantIndex, url) => {
    if (!url) return;
    setForm((prev) => ({
      ...prev,
      colorVariants: prev.colorVariants.map((v, i) =>
        i === variantIndex ? { ...v, images: [...v.images, url] } : v
      ),
    }));
  };

  // Remove one image from a variant's image list.
  const removeVariantImage = (variantIndex, imgIndex) => {
    setForm((prev) => ({
      ...prev,
      colorVariants: prev.colorVariants.map((v, i) =>
        i === variantIndex
          ? { ...v, images: v.images.filter((_, ii) => ii !== imgIndex) }
          : v
      ),
    }));
  };

  // Move an image to the front of its variant's list — the first image of
  // the first variant is used as the cover image (product thumbnail).
  const makeVariantImageCover = (variantIndex, imgIndex) => {
    setForm((prev) => ({
      ...prev,
      colorVariants: prev.colorVariants.map((v, i) => {
        if (i !== variantIndex) return v;
        const images = [...v.images];
        const [chosen] = images.splice(imgIndex, 1);
        return { ...v, images: [chosen, ...images] };
      }),
    }));
  };

  // Clear a variant's video (it's optional, so this just blanks it out —
  // no confirmation needed).
  const removeVariantVideo = (variantIndex) => {
    setForm((prev) => ({
      ...prev,
      colorVariants: prev.colorVariants.map((v, i) =>
        i === variantIndex ? { ...v, video: '' } : v
      ),
    }));
    setVideoUrlDrafts((prev) => ({ ...prev, [variantIndex]: '' }));
  };

  // Commits whatever's typed in the "paste a video URL" draft for one
  // variant into its actual video field.
  const commitVideoUrlDraft = (variantIndex) => {
    const url = (videoUrlDrafts[variantIndex] || '').trim();
    if (!url) return;
    updateVariantField(variantIndex, 'video', url);
    setVideoUrlDrafts((prev) => ({ ...prev, [variantIndex]: '' }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm(emptyForm);
    setNewSubName('');
    setError('');
    setModalOpen(true);
  };

  const openEdit = (p) => {
    setEditing(p);
    const colorVariants = parseProductColors(p.colors, p.image_url);
    setForm({
      name: p.name,
      original_price: p.original_price || '',
      discount_percent: p.discount_percent || '',
      price: p.price || '',
      sold_label: p.sold_label || '',
      is_premium: !!p.is_premium,
      category: p.category || '',
      subcategory_id: p.subcategory_id || '',
      description: p.description || '',
      stock: p.stock ?? '',
      colorVariants,
      is_new_arrival: !!p.is_new_arrival,
      is_best_seller: !!p.is_best_seller,
      is_collection: !!p.is_collection,
      is_flash_sale: !!p.is_flash_sale,
      is_for_you: !!p.is_for_you,
    });
    setNewSubName('');
    setError('');
    setModalOpen(true);
  };

  const save = async (e) => {
    e.preventDefault();
    setError('');

    if (!form.category) {
      setError('Please select a category (Men / Women / Kids) before saving.');
      return;
    }
    if (!form.subcategory_id) {
      setError('Please select or create a subcategory — products without one won\'t appear anywhere on the app.');
      return;
    }

    // Every variant with a name, at least one image, or a video gets
    // saved, into the existing "colors" column — now one entry per color
    // instead of one entry total. `video` is optional and simply omitted
    // (empty string) when the admin didn't add one.
    const colorsPayload = form.colorVariants
      .filter((v) => v.name.trim() || v.images.length > 0 || v.video.trim())
      .map((v) => ({ name: v.name.trim(), hex: v.hex, images: v.images, video: v.video.trim() }));

    // The listing/card thumbnail still needs a single image_url — video is
    // optional and can't stand in for it, so pull the first image from
    // whichever variant actually has one (not just colorsPayload[0], which
    // may be a video-only variant with no images of its own).
    const coverImage = colorsPayload.find((v) => v.images.length > 0)?.images[0] || '';
    if (!coverImage) {
      setError('Please add at least one image to a color variant — video alone isn\'t enough for the product thumbnail.');
      return;
    }

    setSaving(true);

    const orig = Number(form.original_price) || 0;
    const disc = Number(form.discount_percent) || 0;
    const finalPrice = calculatePrice(orig, disc);

    const payload = {
      name: form.name,
      // Card/listing thumbnail across the app still reads a single
      // image_url — the first image found across all color variants.
      image_url: coverImage,
      price: Number(finalPrice) || orig,
      original_price: orig || null,
      discount_percent: disc || null,
      sold_label: form.sold_label || null,
      is_premium: form.is_premium ? 1 : 0,
      category: form.category,
      subcategory_id: form.subcategory_id,
      description: form.description || null,
      stock: form.stock ? Number(form.stock) : 0,
      // Single entry: { name, hex, images: [...] } — stored in the
      // existing "colors" column.
      colors: colorsPayload,
      is_new_arrival: form.is_new_arrival ? 1 : 0,
      is_best_seller: form.is_best_seller ? 1 : 0,
      is_collection: form.is_collection ? 1 : 0,
      is_flash_sale: form.is_flash_sale ? 1 : 0,
      is_for_you: form.is_for_you ? 1 : 0,
    };

    try {
      if (editing) {
        await ProductsApi.update(editing.id, payload);
      } else {
        await ProductsApi.create(payload);
      }
      setModalOpen(false);
      await load(search ? { search } : {});
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  const confirmDelete = async () => {
    setDeleting(true);
    try {
      await ProductsApi.remove(deleteTarget.id);
      setDeleteTarget(null);
      await load(search ? { search } : {});
    } catch (e) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  const getFeatureTags = (p) => {
    const tags = [];
    if (p.is_premium) tags.push({ label: 'Premium', tone: 'gold' });
    if (p.is_new_arrival) tags.push({ label: 'New', tone: 'blue' });
    if (p.is_best_seller) tags.push({ label: 'Best Seller', tone: 'gold' });
    if (p.is_collection) tags.push({ label: 'Collection', tone: 'purple' });
    if (p.is_flash_sale) tags.push({ label: 'Flash', tone: 'red' });
    if (p.is_for_you) tags.push({ label: 'For You', tone: 'default' });
    return tags;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl text-ink">Products</h1>
          <p className="mt-1 text-sm text-muted">
            Select a gender category below, then use <strong>Features</strong> to tag products for New Arrivals, Best Sellers, or Premium.
          </p>
        </div>
        <Button variant="gold" onClick={openCreate}>
          <Plus size={16} /> Add product
        </Button>
      </div>

      <div className="relative max-w-sm">
        <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
        <input
          className="w-full rounded-lg border border-mutedLight bg-white py-2 pl-9 pr-3 text-sm focus:border-ink focus:outline-none"
          placeholder="Search products…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {error && <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{error}</p>}

      {!items ? (
        <Loader />
      ) : items.length === 0 ? (
        <Card>
          <EmptyState
            title="No products found"
            description="Try a different search, or add your first product."
          />
        </Card>
      ) : (
        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-line bg-cream/50 text-xs uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3 font-medium">Product</th>
                  <th className="px-4 py-3 font-medium">Category</th>
                  <th className="px-4 py-3 font-medium">Price</th>
                  <th className="px-4 py-3 font-medium">Stock</th>
                  <th className="px-4 py-3 font-medium">Features</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {items.map((p) => (
                  <tr key={p.id} className="border-b border-line last:border-0 hover:bg-cream/40">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <img
                          src={p.image_url || '/placeholder.png'}
                          alt={p.name}
                          className="h-10 w-10 shrink-0 rounded-lg object-cover"
                          onError={(e) => (e.target.src = '/placeholder.png')}
                        />
                        <span className="font-medium text-ink">{p.name}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex flex-col items-start gap-1">
                        <Badge tone="gold">{p.category || '—'}</Badge>
                        {getSubcategoryName(p.subcategory_id) ? (
                          <span className="text-xs text-muted">
                            {getSubcategoryName(p.subcategory_id)}
                          </span>
                        ) : (
                          <span className="text-xs text-muted/60 italic">No subcategory</span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <span className="font-medium text-ink">Rs {p.price}</span>
                      {p.original_price && p.discount_percent > 0 && (
                        <>
                          <span className="ml-1.5 text-xs text-muted line-through">
                            Rs {p.original_price}
                          </span>
                          <Badge tone="red" className="ml-1 text-xs">
                            -{p.discount_percent}%
                          </Badge>
                        </>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted">{p.stock ?? '—'}</td>
                    <td className="px-4 py-3">
                      <div className="flex flex-wrap gap-1">
                        {getFeatureTags(p).map((tag, i) => (
                          <Badge key={i} tone={tag.tone}>
                            {tag.label}
                          </Badge>
                        ))}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <div className="flex justify-end gap-1">
                        <button
                          onClick={() => openEdit(p)}
                          className="rounded-lg p-1.5 text-muted hover:bg-line hover:text-ink"
                        >
                          <Pencil size={15} />
                        </button>
                        <button
                          onClick={() => setDeleteTarget(p)}
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

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editing ? 'Edit product' : 'Add product'}
        width="max-w-2xl"
      >
        <form onSubmit={save} className="space-y-4">
          {error && (
            <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{error}</p>
          )}

          <Input
            label="Name"
            required
            value={form.name}
            onChange={(e) => handleFormChange('name', e.target.value)}
            placeholder="e.g. Premium Cotton Shirt"
          />

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input
              label="Original Price (Rs)"
              type="number"
              required
              value={form.original_price}
              onChange={(e) => handleFormChange('original_price', e.target.value)}
              placeholder="e.g. 999"
            />
            <Input
              label="Discount %"
              type="number"
              value={form.discount_percent}
              onChange={(e) => handleFormChange('discount_percent', e.target.value)}
              placeholder="e.g. 10"
            />
          </div>

          <div className="rounded-lg border border-mutedLight bg-cream/50 p-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted">Final Price (after discount):</span>
              <span className="text-xl font-bold text-ink">
                Rs {calculatePrice(Number(form.original_price), Number(form.discount_percent)) || form.original_price || '—'}
              </span>
            </div>
          </div>

          {/* ✅ Category Dropdown - Only Men, Women, Kids */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Select
              label="Category"
              required
              value={form.category}
              onChange={(e) => handleFormChange('category', e.target.value)}
            >
              <option value="">Select category</option>
              {CATEGORY_OPTIONS.map((cat) => (
                <option key={cat.id} value={cat.name}>
                  {cat.label}
                </option>
              ))}
            </Select>

            <Input
              label="Stock"
              type="number"
              value={form.stock}
              onChange={(e) => handleFormChange('stock', e.target.value)}
              placeholder="e.g. 50"
            />
          </div>

          {/* ✅ Subcategory - required. Shown once a Category is picked, since
              a subcategory always belongs to a parent (Men/Women/Kids).
              Shoppers browse as "Men > Polo Shirts" on the app, so a product
              without a subcategory would never show up anywhere. */}
          {form.category ? (
            <div>
              <Select
                label="Subcategory"
                required
                value={form.subcategory_id}
                onChange={(e) => handleFormChange('subcategory_id', e.target.value)}
              >
                <option value="">Select subcategory</option>
                {subcategoryOptions.map((sub) => (
                  <option key={sub.id} value={sub.id}>
                    {sub.name}
                  </option>
                ))}
              </Select>

              <div className="mt-2 flex items-end gap-2">
                <div className="flex-1">
                  <Input
                    label="New subcategory"
                    value={newSubName}
                    onChange={(e) => setNewSubName(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault();
                        addSubcategory();
                      }
                    }}
                    placeholder="e.g. Polo Shirts, Round Neck..."
                  />
                </div>
                <Button
                  type="button"
                  variant="outline"
                  onClick={addSubcategory}
                  disabled={addingSub || !newSubName.trim()}
                >
                  <Plus size={14} /> {addingSub ? 'Adding…' : 'Add'}
                </Button>
              </div>
              <p className="mt-1 text-xs text-muted">
                Adds a new subcategory under {form.category} — it'll be selected automatically.
              </p>
            </div>
          ) : (
            <p className="rounded-lg border border-mutedLight bg-cream/50 px-3 py-2 text-xs text-muted">
              Select a category above to choose or create a subcategory.
            </p>
          )}

          <Input
            label="Sold label"
            value={form.sold_label}
            onChange={(e) => handleFormChange('sold_label', e.target.value)}
            placeholder="e.g. 120 sold"
          />

          {/* ✅ Product Colors - one or more color variants. Each variant has
              its own color + its own set of images. On the app, tapping a
              color swaps the gallery to that variant's images (White ->
              white photos, Black -> black photos). */}
          <div>
            <span className="mb-1 block text-sm font-medium text-ink">Product Colors</span>
            <p className="mb-3 text-xs text-muted">
              Add a variant for each color you sell this in. Selecting a
              color on the app shows that variant's own images.
            </p>

            <div className="space-y-4">
              {form.colorVariants.map((variant, variantIdx) => (
                <div
                  key={variantIdx}
                  className="rounded-xl border border-mutedLight p-3"
                >
                  <div className="mb-3 flex items-center justify-between gap-2">
                    <span className="text-xs font-medium uppercase tracking-wide text-muted">
                      Variant {variantIdx + 1}
                    </span>
                    {form.colorVariants.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeColorVariant(variantIdx)}
                        className="flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-danger hover:bg-red-50"
                      >
                        <Trash2 size={12} /> Remove color
                      </button>
                    )}
                  </div>

                  <div className="flex flex-wrap items-end gap-2">
                    <input
                      type="color"
                      value={variant.hex}
                      onChange={(e) => updateVariantField(variantIdx, 'hex', e.target.value)}
                      className="h-10 w-12 shrink-0 cursor-pointer rounded-lg border border-mutedLight p-1"
                      aria-label={`Variant ${variantIdx + 1} color swatch`}
                    />
                    <div className="min-w-[140px] flex-1">
                      <Input
                        label="Color name"
                        value={variant.name}
                        onChange={(e) => updateVariantField(variantIdx, 'name', e.target.value)}
                        placeholder="e.g. White"
                      />
                    </div>
                  </div>

                  <div className="mt-3">
                    <span className="mb-1 block text-xs font-medium text-ink">
                      Images for this color
                    </span>
                    <p className="mb-2 text-xs text-muted">
                      The first image is the cover — click "Make cover" to
                      move one to the front. Shoppers swipe or use arrows to
                      switch between them.
                    </p>

                    {variant.images.length > 0 && (
                      <div className="mb-3 grid grid-cols-3 gap-2 sm:grid-cols-4">
                        {variant.images.map((img, imgIdx) => (
                          <div
                            key={imgIdx}
                            className="group relative aspect-square overflow-hidden rounded-lg border border-mutedLight"
                          >
                            <img
                              src={img}
                              alt={`${variant.name || 'Variant'} image ${imgIdx + 1}`}
                              className="h-full w-full object-cover"
                            />
                            {imgIdx === 0 && (
                              <span className="absolute left-1 top-1 rounded bg-ink/80 px-1.5 py-0.5 text-[10px] font-medium text-white">
                                Cover
                              </span>
                            )}
                            <div className="absolute inset-0 flex items-end justify-between gap-1 bg-gradient-to-t from-black/60 via-transparent to-transparent p-1 opacity-0 transition-opacity group-hover:opacity-100">
                              {imgIdx !== 0 && (
                                <button
                                  type="button"
                                  onClick={() => makeVariantImageCover(variantIdx, imgIdx)}
                                  className="rounded bg-white/90 px-1.5 py-0.5 text-[10px] font-medium text-ink hover:bg-white"
                                >
                                  Make cover
                                </button>
                              )}
                              <button
                                type="button"
                                onClick={() => removeVariantImage(variantIdx, imgIdx)}
                                className="ml-auto rounded bg-white/90 p-1 text-danger hover:bg-white"
                                aria-label={`Remove image ${imgIdx + 1}`}
                              >
                                <Trash2 size={12} />
                              </button>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {/* Uploading a new file appends it to this variant's
                        image list rather than replacing a single value. */}
                    <ImageUploadField
                      key={variant.images.length}
                      label="Add image"
                      type="products"
                      value=""
                      onChange={(url) => addVariantImage(variantIdx, url)}
                    />
                  </div>

                  {/* ✅ Optional video for this color — either upload a file
                      or paste a link (YouTube/Vimeo/direct .mp4). Neither
                      is required; leave both empty to skip. Shown on the
                      app's product detail page alongside this color's
                      images when present. */}
                  <div className="mt-3 border-t border-mutedLight pt-3">
                    <span className="mb-1 block text-xs font-medium text-ink">
                      Video for this color (optional)
                    </span>
                    <p className="mb-2 text-xs text-muted">
                      Upload a video file or paste a video URL — either
                      works, and both are optional.
                    </p>

                    {variant.video ? (
                      <div className="mb-2 flex items-center gap-2 rounded-lg border border-mutedLight bg-cream/50 px-3 py-2">
                        <video
                          src={variant.video}
                          className="h-12 w-16 shrink-0 rounded object-cover"
                          muted
                        />
                        <span className="min-w-0 flex-1 truncate text-xs text-muted">
                          {variant.video}
                        </span>
                        <button
                          type="button"
                          onClick={() => removeVariantVideo(variantIdx)}
                          className="shrink-0 rounded-lg p-1 text-danger hover:bg-red-50"
                          aria-label="Remove video"
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    ) : (
                      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                        {/* File upload — reuses the same uploader as
                            product images. If your ImageUploadField's
                            underlying <input> is hardcoded to
                            accept="image/*", widen it (or add accept="video/*"
                            when type="videos") so video files aren't
                            rejected client-side. */}
                        <ImageUploadField
                          key={`video-${variantIdx}`}
                          label="Upload video file"
                          type="videos"
                          accept="video/*"
                          value=""
                          onChange={(url) => updateVariantField(variantIdx, 'video', url)}
                        />
                        <div className="flex items-end gap-2">
                          <div className="flex-1">
                            <Input
                              label="…or paste a video URL"
                              value={videoUrlDrafts[variantIdx] || ''}
                              onChange={(e) =>
                                setVideoUrlDrafts((prev) => ({ ...prev, [variantIdx]: e.target.value }))
                              }
                              onKeyDown={(e) => {
                                if (e.key === 'Enter') {
                                  e.preventDefault();
                                  commitVideoUrlDraft(variantIdx);
                                }
                              }}
                              placeholder="https://…mp4 or YouTube/Vimeo link"
                            />
                          </div>
                          <Button
                            type="button"
                            variant="outline"
                            onClick={() => commitVideoUrlDraft(variantIdx)}
                            disabled={!(videoUrlDrafts[variantIdx] || '').trim()}
                          >
                            Add
                          </Button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            <Button
              type="button"
              variant="outline"
              className="mt-3"
              onClick={addColorVariant}
            >
              <Plus size={14} /> Add another color
            </Button>
          </div>

          <Textarea
            label="Description"
            rows={3}
            value={form.description}
            onChange={(e) => handleFormChange('description', e.target.value)}
            placeholder="Describe your product..."
          />

          {/* ✅ Features Section - New Arrivals, Best Sellers, Premium are here */}
          <div>
            <span className="mb-2 block text-sm font-medium text-ink">
              Feature this product in...
            </span>
            <p className="text-xs text-muted mb-2">
              Check the boxes below to make this product appear in the Featured sections.
            </p>
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {FIXED_FEATURES.map(({ key, label }) => (
                <label
                  key={key}
                  className="flex items-center gap-2 rounded-lg border border-mutedLight px-3 py-2 text-sm has-[:checked]:border-ink has-[:checked]:bg-cream"
                >
                  <input
                    type="checkbox"
                    checked={form[key]}
                    onChange={(e) => handleFormChange(key, e.target.checked)}
                    className="accent-ink"
                  />
                  {label}
                </label>
              ))}
            </div>
          </div>

          <div className="sticky bottom-0 -mx-6 flex justify-end gap-2 border-t border-mutedLight bg-white px-6 pt-3 pb-1">
            <Button type="button" variant="ghost" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="gold" disabled={saving}>
              {saving ? 'Saving…' : editing ? 'Update product' : 'Save product'}
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        loading={deleting}
        title="Delete product?"
        description={`"${deleteTarget?.name}" will be permanently removed.`}
      />
    </div>
  );
}