import { useState } from 'react';
import { UploadCloud, Loader2, Film } from 'lucide-react';
import { UploadApi } from '../api/resources';

export default function ImageUploadField({
  label = 'Image',
  value,
  onChange,
  type = 'products',
  accept = 'image/*',
}) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  // Was hardcoded to 'image' before — that's what silently forced the
  // browser's file picker to only show image files even when this field
  // was used for video uploads. Now it's derived from the `accept` prop
  // that's actually passed in (e.g. "video/*" for the video uploader),
  // so it correctly accepts every video format the browser/OS offers
  // (mp4, mov, webm, mkv, avi, etc.) instead of just images.
  const isVideo = accept.startsWith('video/');
  const chooseLabel = isVideo ? 'Choose video' : 'Choose image';
  const urlPlaceholder = isVideo ? 'or paste a video URL' : 'or paste an image URL';

  const handleFile = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setError('');
    setUploading(true);
    try {
      const result = await UploadApi.image(file, type);
      onChange(result.url);
    } catch (err) {
      setError(err.message || 'Upload failed.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="text-sm">
      <span className="mb-1.5 block font-medium text-ink">{label}</span>
      <div className="flex items-center gap-3">
        <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-mutedLight bg-line">
          {value ? (
            isVideo ? (
              <video src={value} className="h-full w-full object-cover" muted />
            ) : (
              <img src={value} alt="" className="h-full w-full object-cover" />
            )
          ) : isVideo ? (
            <Film size={20} className="text-muted" />
          ) : (
            <UploadCloud size={20} className="text-muted" />
          )}
        </div>
        <div className="flex-1">
          <label className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-mutedLight bg-white px-3 py-2 text-xs font-medium text-ink hover:bg-line">
            {uploading ? <Loader2 size={14} className="animate-spin" /> : <UploadCloud size={14} />}
            {uploading ? 'Uploading…' : chooseLabel}
            <input type="file" accept={accept} className="hidden" onChange={handleFile} disabled={uploading} />
          </label>
          <input
            type="text"
            placeholder={urlPlaceholder}
            value={value || ''}
            onChange={(e) => onChange(e.target.value)}
            className="mt-2 w-full rounded-lg border border-mutedLight bg-white px-3 py-1.5 text-xs text-ink placeholder:text-muted focus:border-ink focus:outline-none"
          />
          {error && <p className="mt-1 text-xs text-danger">{error}</p>}
        </div>
      </div>
    </div>
  );
}
