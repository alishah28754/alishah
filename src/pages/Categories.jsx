// admin/src/pages/Categories.jsx
import { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { CategoriesApi } from '../api/resources';
import { Button, Card, Input, Select, Loader, Badge } from '../components/ui';
import Modal from '../components/Modal';
import ConfirmDialog from '../components/ConfirmDialog';
import ImageUploadField from '../components/ImageUploadField';

// ============================================================
// FIXED MAIN CATEGORIES - ALL TOP-LEVEL
// ============================================================
const FIXED_CATEGORIES = [
  { id: 'men', name: 'Men', label: 'Men' },
  { id: 'women', name: 'Women', label: 'Women' },
  { id: 'kids', name: 'Kids', label: 'Kids' },
];

const emptySubcategory = { name: '', image_url: '', parent_id: '' };
const emptyNewSub = { name: '', image_url: '' };

export default function Categories() {
  const [items, setItems] = useState(null);
  const [error, setError] = useState('');

  // Edit subcategory modal
  const [subModalOpen, setSubModalOpen] = useState(false);
  const [editingSub, setEditingSub] = useState(null);
  const [subForm, setSubForm] = useState(emptySubcategory);
  const [savingSub, setSavingSub] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleting, setDeleting] = useState(false);

  // Add Sub Category modal
  const [addSubModalOpen, setAddSubModalOpen] = useState(false);
  const [addSubParent, setAddSubParent] = useState(null);
  const [addSubForm, setAddSubForm] = useState(emptyNewSub);
  const [savingNewSub, setSavingNewSub] = useState(false);
  const [addSubError, setAddSubError] = useState('');

  const load = () => CategoriesApi.list().then(setItems).catch((e) => setError(e.message));
  useEffect(() => { load(); }, []);

  // Get main categories from FIXED list
  const mainCategories = FIXED_CATEGORIES;

  // Get subcategories for each main category (only Men, Women, Kids have subcategories)
  const getSubcategories = (parentName) => {
    const subcategoryParents = ['Men', 'Women', 'Kids'];
    if (!subcategoryParents.includes(parentName)) return [];
    return items?.filter(c => c.parent_name === parentName) || [];
  };

  // ============================================================
  // ADD SUB CATEGORY
  // ============================================================
  const openAddSub = (parentCategory) => {
    setAddSubParent(parentCategory);
    setAddSubForm(emptyNewSub);
    setAddSubError('');
    setAddSubModalOpen(true);
  };

  const saveNewSub = async (e) => {
    e.preventDefault();
    const name = addSubForm.name.trim();
    if (!name || !addSubParent) return;

    setSavingNewSub(true);
    setAddSubError('');
    try {
      // FIXED_CATEGORIES uses slug-style ids ('men'/'women'/'kids') that only
      // exist on the frontend — the database needs the REAL top-level
      // category row's numeric id for parent_id. Look it up by name; if the
      // top-level row doesn't exist in the DB yet, create it first.
      let parentId = (items || []).find(
        (c) => !c.parent_id && c.name === addSubParent.name
      )?.id;

      if (!parentId) {
        const createdParent = await CategoriesApi.create({
          name: addSubParent.name,
          parent_id: null,
        });
        parentId = createdParent.id;
      }

      await CategoriesApi.create({
        name,
        parent_id: parentId,
        image_url: addSubForm.image_url || null,
      });
      setAddSubModalOpen(false);
      await load();
    } catch (e) {
      setAddSubError(e.message || 'Failed to create sub category');
    } finally {
      setSavingNewSub(false);
    }
  };

  // ============================================================
  // SUBCATEGORY EDIT / DELETE
  // ============================================================
  const openEditSub = (cat) => {
    setEditingSub(cat);
    setSubForm({
      name: cat.name,
      image_url: cat.image_url || '',
      parent_id: cat.parent_id || '',
    });
    setSubModalOpen(true);
  };

  const saveSub = async (e) => {
    e.preventDefault();
    setSavingSub(true);
    setError('');
    try {
      await CategoriesApi.update(editingSub.id, subForm);
      setSubModalOpen(false);
      await load();
    } catch (e) {
      setError(e.message);
    } finally {
      setSavingSub(false);
    }
  };

  const confirmDelete = async () => {
    setDeleting(true);
    try {
      await CategoriesApi.remove(deleteTarget.id);
      setDeleteTarget(null);
      await load();
    } catch (e) {
      setError(e.message);
    } finally {
      setDeleting(false);
    }
  };

  // ============================================================
  // RENDER
  // ============================================================
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-3xl text-ink">Categories</h1>
          <p className="mt-1 text-sm text-muted">
             categories: <strong>Men, Women, Kids</strong>
            <br />
            <span className="text-xs text-muted/70">
              Add sub categories under each one. Products (and their sub category) are managed on the Products page.
            </span>
          </p>
        </div>
      </div>

      {error && <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{error}</p>}

      {!items ? (
        <Loader />
      ) : (
        <div className="space-y-8">
          {mainCategories.map((cat) => {
            const subcategories = getSubcategories(cat.name);

            return (
              <Card key={cat.id} className="overflow-hidden">
                <div className="flex items-center justify-between border-b border-line bg-cream/30 px-4 py-3">
                  <div className="flex items-center gap-4">
                    <h3 className="text-lg font-semibold text-ink">{cat.label}</h3>
                    
                  </div>
                  <Button
                    variant="gold"
                    size="sm"
                    onClick={() => openAddSub(cat)}
                  >
                    <Plus size={14} /> Add Sub Category
                  </Button>
                </div>

                {subcategories.length > 0 ? (
                  <div className="grid grid-cols-2 gap-3 p-4 sm:grid-cols-3 lg:grid-cols-4">
                    {subcategories.map((sub) => (
                      <div
                        key={sub.id}
                        className="flex items-center justify-between rounded-lg border border-line p-3 hover:bg-cream/30"
                      >
                        <div className="flex flex-1 items-center gap-3 text-left">
                          {sub.image_url && (
                            <img
                              src={sub.image_url}
                              alt={sub.name}
                              className="h-8 w-8 rounded object-cover"
                            />
                          )}
                          <span className="text-sm font-medium text-ink">{sub.name}</span>
                        </div>
                        <div className="flex gap-1">
                          <button
                            onClick={() => openEditSub(sub)}
                            className="rounded-lg p-1.5 text-muted hover:bg-line hover:text-ink"
                            title="Rename / change image"
                          >
                            <Pencil size={14} />
                          </button>
                          <button
                            onClick={() => setDeleteTarget(sub)}
                            className="rounded-lg p-1.5 text-muted hover:bg-red-50 hover:text-danger"
                            title="Delete subcategory"
                          >
                            <Trash2 size={14} />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="p-6 text-center text-sm text-muted">
                    No sub categories yet. Click <strong>"Add Sub Category"</strong> to create one.
                  </div>
                )}
              </Card>
            );
          })}
        </div>
      )}

      {/* ============================================================
          ADD SUB CATEGORY MODAL
          ============================================================ */}
      <Modal
        open={addSubModalOpen}
        onClose={() => setAddSubModalOpen(false)}
        title={`Add sub category in ${addSubParent?.label || ''}`}
      >
        <form onSubmit={saveNewSub} className="space-y-4">
          {addSubError && (
            <p className="rounded-lg bg-red-50 px-4 py-3 text-sm text-danger">{addSubError}</p>
          )}

          <Input
            label="Sub category name"
            required
            value={addSubForm.name}
            onChange={(e) => setAddSubForm({ ...addSubForm, name: e.target.value })}
            placeholder="e.g. Polo, T-Shirts, Jeans..."
          />

         
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => setAddSubModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="gold" disabled={savingNewSub || !addSubForm.name.trim()}>
              {savingNewSub ? 'Saving…' : 'Add sub category'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* EDIT SUBCATEGORY MODAL */}
      <Modal
        open={subModalOpen}
        onClose={() => setSubModalOpen(false)}
        title="Edit Sub Category"
      >
        <form onSubmit={saveSub} className="space-y-4">
          <Input
            label="Sub category name"
            required
            value={subForm.name}
            onChange={(e) => setSubForm({ ...subForm, name: e.target.value })}
            placeholder="e.g. Polo, T-Shirts, Jeans..."
          />

          <Select
            label="Parent Category"
            required
            value={subForm.parent_id}
            onChange={(e) => setSubForm({ ...subForm, parent_id: e.target.value })}
          >
            <option value="">Select parent category</option>
            {(items || [])
              .filter((c) => !c.parent_id && FIXED_CATEGORIES.some((f) => f.name === c.name))
              .map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
          </Select>

      

          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => setSubModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="gold" disabled={savingSub}>
              {savingSub ? 'Saving…' : 'Update'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* DELETE CONFIRMATION */}
      <ConfirmDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        loading={deleting}
        title="Delete sub category?"
        description={`"${deleteTarget?.name}" will be removed. Products in this sub category will become uncategorized.`}
      />
    </div>
  );
}
