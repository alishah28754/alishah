# KTEX Admin Panel (React + Vite)

Web-based admin dashboard for **KTEX** — manages products, categories, banners,
orders, and users on the live app in real time, backed by the same Node.js +
MySQL API the Flutter app uses. No app rebuild needed to change what's shown.

Login is a plain **email + password** form. The backend looks the email up in
the `users` table, checks the password hash, and only issues a session token
if that row also has `is_admin = 1`.

---

## 1. Setup

```bash
cd ktex-admin-panel
npm install
copy .env.example .env      # Windows
```

Edit `.env`:
- `VITE_API_URL` — your Node backend, e.g. `http://localhost:8000/api`

```bash
npm run dev
```
Opens at `http://localhost:5173`.

### Backend contract this panel expects
- `POST /auth/login` — body `{ email, password }`. Verify the password hash
  against the matching `users` row; if found **and** `is_admin = 1`, respond
  with `{ success: true, data: { token, user } }` (any signed session token —
  e.g. a JWT — works, `client.js` just forwards it as `Authorization: Bearer
  <token>` on every later request). If the email isn't found, the password
  doesn't match, or `is_admin` isn't set, respond with `{ success: false,
  message: '...' }`.
- `GET /auth/me` — reads that same token and returns `{ success: true, data:
  user }` so the panel can restore the session on refresh. Respond with an
  error (401) if the token is missing/expired/invalid.

### Make yourself an admin
In phpMyAdmin:
```sql
UPDATE users SET is_admin = 1 WHERE email = 'your@email.com';
```
Then log in with that account's email + password.

### Allow this panel through the backend's CORS
In `ktex-backend/.env`, set:
```
CORS_ORIGIN=http://localhost:5173
```
(comma-separate multiple origins once you deploy, e.g. `http://localhost:5173,https://admin.ktexstore.com`)

---

## 2. What it manages

| Page | What it does |
|---|---|
| **Dashboard** | Revenue, order counts, pending orders, 7-day sales chart |
| **Products** | Full CRUD — price, stock, category, and toggle Premium / Flash Sale / New Arrivals / For You, with image upload |
| **Categories** | Create/edit/delete, with image |
| **Banners** | Manage the app's home-screen hero slides, link to a category |
| **Orders** | View every order + items, update status (Processing -> Confirmed -> Shipped -> Delivered / Cancelled) |
| **Users** | View everyone who's logged into the app, promote/demote admins, delete accounts |

Every change here reflects on the app **immediately** on next fetch — products,
banners, and categories are all read live from the same MySQL database.

---

## 3. Project structure

```
src/
├── api/
│   ├── client.js              # axios instance, attaches stored login token
│   └── resources.js            # one function set per backend resource
├── context/AuthContext.jsx      # tracks login + is_admin
├── components/                   # ProtectedRoute, Modal, ConfirmDialog, ui.jsx, ImageUploadField
├── layouts/AdminLayout.jsx        # sidebar + page frame
└── pages/                          # Dashboard, Products, Categories, Banners, Orders, Users, Login
```

---

## 4. Build & deploy

```bash
npm run build      # outputs to dist/
```
`dist/` is a static site — host it anywhere (Netlify, Vercel, or the same
server as the backend behind Nginx). Just make sure `VITE_API_URL` in the
build points at your deployed backend, and that backend's `CORS_ORIGIN`
includes the admin panel's deployed URL.
