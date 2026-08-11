# KTEX Backend (Node.js + Express + MySQL)

Complete backend API for the **KTEX** Flutter app (`ktexstore.com`) — built to match
`lib/models/models.dart`, `cart_model.dart`, `favourites_model.dart`, and `order_model.dart`
exactly, so the Flutter app's JSON parsing (`fromJson`) works with zero changes.

**Auth:** two separate logins share the same `users` table.
- **Flutter app (shoppers):** Firebase (Google + email/password) — unchanged. This
  backend verifies the Firebase ID token the app sends and auto-syncs a local
  profile row for orders/cart/favourites/admin-flag.
- **Admin panel:** plain email + password, checked against this table's
  `password_hash` column (bcrypt). `POST /api/auth/login` returns our own JWT;
  see `database/set-admin-password.js` to create/update an admin login.

**Payments:** PayFast (Pakistan) Hosted Checkout — card/account details are entered on
PayFast's own secure page (never touch this server), so there's no PCI-DSS burden on you.

Also exposes `/api/admin/*` endpoints ready for a future **web-based admin panel**
(dashboard stats, order status updates, user management) and `/api/upload` for
uploading product/category/banner images dynamically — no app rebuild needed to
change products, banners, or users.

---

## 1. Setup

### 1.1 Install dependencies
```bash
cd ktex-backend
npm install
```

### 1.2 Configure environment
```bash
copy .env.example .env      # Windows
# or: cp .env.example .env   # Mac/Linux
```
Edit `.env`:

**MySQL (XAMPP defaults):**
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=ktex_db
```

**Firebase Admin** — from Firebase Console → Project Settings → Service Accounts →
"Generate new private key" (downloads a JSON file). Copy 3 values from it into `.env`:
```
FIREBASE_PROJECT_ID=<project_id from the JSON>
FIREBASE_CLIENT_EMAIL=<client_email from the JSON>
FIREBASE_PRIVATE_KEY="<private_key from the JSON, keep the \n as literal \n>"
```
This must be the **same Firebase project** your Flutter app's `firebase_options.dart` uses.

**PayFast** — from your PayFast merchant dashboard (gopayfast.com):
```
PAYFAST_MERCHANT_ID=...
PAYFAST_MERCHANT_NAME=KTEX Store
PAYFAST_SECURED_KEY=...
```
⚠️ Confirm `PAYFAST_TOKEN_URL` and `PAYFAST_CHECKOUT_URL` with PayFast support/dashboard
before going live — sandbox and production URLs differ and PayFast's public docs are
inconsistent about them. Do one full sandbox transaction and check this server's
console logs; if the callback fields don't match, adjust the small block at the top of
`handlePayfastCallback` in `src/controllers/paymentController.js` (all in one place).

### 1.3 Create the database tables

**Fresh setup** (nothing created yet): import `database/schema.sql` in phpMyAdmin, or:
```bash
npm run db:init          # creates all tables
npm run db:init -- --seed   # tables + sample products/categories/banners
```

**Already created `ktex_db` with the old custom-auth schema?** Run
`database/migration_firebase_payfast.sql` in phpMyAdmin instead — it `ALTER`s your
existing tables to add `firebase_uid`, drop the old password requirement, and add
PayFast support, without losing your data.

**Already running with Firebase-only auth and just want admin-panel login added?**
Run `database/migration_admin_login.sql` in phpMyAdmin — it adds `password_hash`
back to `users` (for admin accounts only) without touching Firebase/shopper auth.

### 1.4 Run the server
```bash
npm run dev     # auto-restarts on file changes (nodemon)
# or
npm start
```
Server runs at `http://localhost:8000`. Test it: `GET http://localhost:8000/api/health`

### 1.5 Make your first admin account (for the web admin panel)
```bash
npm run db:set-admin -- you@example.com "YourNewPassword123" "Your Name"
```
This creates the row if it doesn't exist yet (or updates it if it does), sets
`is_admin = 1`, and stores a bcrypt hash of the password — never a plaintext
password, and never in Firebase. Log in to the admin panel with that email +
password. This is completely separate from any Flutter-app / Firebase account.

---

## 2. Connecting the Flutter app

In `lib/config/environment.dart` (or your `.env`), point `API_URL` to this server:
- **Android emulator:** `http://10.0.2.2:8000/api`
- **Physical device (same WiFi):** `http://<your-pc-local-ip>:8000/api`
- **iOS simulator:** `http://localhost:8000/api`

On every API call, send the Firebase ID token:
```dart
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
// Authorization: Bearer <token>
```

**PayFast checkout from the app:** call `POST /api/payments/payfast/initiate` with
`{ "order_number": "..." }`, then open the returned `checkout_url` in a WebView
(`webview_flutter` package). Watch for navigation to a URL starting with
`.../api/payments/payfast/success` or `.../failure` to know when to close the WebView
and refresh the order status.

---

## 3. Project structure

```
ktex-backend/
├── server.js
├── database/
│   ├── schema.sql                       # fresh install
│   ├── migration_firebase_payfast.sql    # run instead if ktex_db already existed
│   ├── migration_admin_login.sql          # run to add admin email+password login
│   ├── set-admin-password.js               # creates/updates an admin login
│   ├── seed.sql
│   └── init.js
├── src/
│   ├── app.js
│   ├── config/
│   │   ├── db.js                          # MySQL pool
│   │   └── firebase.js                     # Firebase Admin SDK init
│   ├── middleware/
│   │   ├── auth.js                          # verifies our admin JWT OR a Firebase ID token
│   │   ├── admin.js
│   │   ├── upload.js
│   │   └── errorHandler.js
│   ├── controllers/
│   ├── routes/
│   └── utils/
│       └── payfast.js                        # token + signature helpers
└── uploads/
```

---

## 4. API Reference

All responses: `{ "success": true/false, "message": "...", "data": ... }`
Protected routes need header: `Authorization: Bearer <token>` — either our own
admin JWT (from `POST /api/auth/login`) or a Firebase ID token, whichever the
caller has.

### Auth
| Method | Endpoint | Auth | Notes |
|---|---|---|---|
| POST | `/api/auth/login` | ❌ public | Admin panel only — body `{ email, password }`, returns `{ token, user }` |
| GET | `/api/auth/me` | ✅ | |
| PUT | `/api/auth/profile` | ✅ | body `{ name?, phone? }` |

### Categories / Products / Banners
Same as before — see inline route files in `src/routes/`. All public GETs, admin-only writes.

### Cart / Favourites (persisted per user)
Protected, keyed to the Firebase-synced user.

### Orders
| Method | Endpoint | Auth |
|---|---|---|
| POST | `/api/orders` | optional — guest checkout allowed |
| GET | `/api/orders` | ✅ |
| GET | `/api/orders/track/:orderNumber` | – public tracking |
| PUT | `/api/orders/:orderNumber/cancel` | ✅ |

`payment_method` accepts: `cod`, `payfast`, `easypaisa`, `jazzcash`, `bank`.

### Payments (PayFast)
| Method | Endpoint | Notes |
|---|---|---|
| POST | `/api/payments/payfast/initiate` | body `{ order_number }` → returns `checkout_url` |
| GET | `/api/payments/payfast/checkout-form/:orderNumber` | open in WebView |
| GET | `/api/payments/payfast/success` \| `/failure` | PayFast redirects here |
| POST/GET | `/api/payments/payfast/callback` | PayFast's server-to-server notification |

### Admin (dashboard / web admin panel)
Unchanged — `/api/admin/stats`, `/api/admin/orders`, `/api/admin/users`, all require `is_admin`.

### Upload
`POST /api/upload?type=products|categories|banners` — admin only, multipart field `image`.

---

## 5. Why this design supports your web admin panel later

- The web admin panel logs in with its own email + password (`POST
  /api/auth/login`, checked against `password_hash`) — `requireAuth` +
  `requireAdmin` gate every admin/product/category/banner/upload route the
  same way regardless of which of the two login methods was used.
- Every product/category/banner field is editable via the admin endpoints, and
  `/api/upload` lets the panel push new images instantly — no app rebuild.
- `/api/admin/stats` returns chart-ready data (7-day sales trend) for a dashboard.
- PayFast confirmation flows through one callback handler, so switching between
  sandbox/live or adjusting field names later touches one file.

