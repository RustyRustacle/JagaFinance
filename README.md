# JagaFinance

> **B2B Receipt & Expense Intelligence Platform** — Digitize physical receipts into auditable financial reports in seconds.

JagaFinance is a production-grade monorepo that combines AI-powered OCR, real-time expense tracking, multi-tenant budget management, and export-ready financial reporting — purpose-built for Indonesian B2B workflows with full PPN/PPh tax compliance.

---

## Architecture

```
jagafinance/
├── apps/
│   ├── web/                    # Next.js 14 (company profile + admin dashboard)
│   └── mobile/                 # Flutter (login, register, dashboard, upload)
├── packages/
│   ├── api/                    # Express 4 REST API (OCR, queues, export, admin)
│   └── db/                     # Prisma 5 schema + client (PostgreSQL 16)
├── packages/blockchain/        # Hardhat + Solidity (Sepolia Ethereum)
├── docker-compose.yml          # Local Postgres 16 + Redis 7
└── turbo.json                  # Turborepo pipeline config
```

### Design Principles

- **Monorepo isolation** — pnpm workspaces + Turborepo for coordinated builds, type-checking, and linting across packages.
- **Type-safe end-to-end** — Shared Prisma types via `@jagafinance/db`, Zod validation on all API inputs, strict TypeScript 5.5.
- **Multi-tenant by design** — Every query scoped to `tenantId`; RBAC with Admin, Finance, and Viewer roles.
- **Async by default** — OCR processing, budget alerts, and exports are queued via BullMQ + Redis for non-blocking operations.
- **Defense in depth** — Helmet, rate-limiting, JWT verification, API key auth, and Supabase RLS across all layers.

---

## Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Runtime** | Node.js 20+, pnpm 9 | Package management, monorepo orchestration |
| **Web** | Next.js 14 (App Router) | SSR, PWA, landing page, admin dashboard |
| **Mobile** | Flutter + Provider + Dio | Native Android app, camera/gallery upload |
| **API** | Express 4 | RESTful endpoints, file upload, auth |
| **Language** | TypeScript 5.5 | Strict typing across 100% of codebase |
| **ORM** | Prisma 5 | Type-safe DB access, migrations |
| **Database** | PostgreSQL 16 (Supabase) | Multi-tenant with RLS |
| **Cache & Queues** | Redis 7 + BullMQ | OCR jobs, budget alerts, exports |
| **Auth** | Supabase Auth + JWT | SSR session + Bearer token |
| **OCR** | Tesseract.js + Google Cloud Vision | Local + Cloud OCR pipeline |
| **Email** | Resend | Transactional notifications |
| **Blockchain** | Hardhat + Solidity | Receipt hash verification on Sepolia Ethereum |
| **Styling** | Tailwind CSS + CVA | Utility-first design system |
| **Containerization** | Docker Compose | Local development infrastructure |

---

## Getting Started

### Prerequisites

```bash
node -v          # >= 20
pnpm -v          # 9.x (install: npm install -g pnpm@9)
docker info      # Docker Desktop running
```

### Quick Start

```bash
# 1. Clone & install
git clone https://github.com/RustyRustacle/JagaFinance.git
cd JagaFinance
pnpm install

# 2. Start Postgres + Redis
pnpm docker:up

# 3. Configure environment
cp .env.example .env
cp apps/web/.env.example apps/web/.env
cp packages/api/.env.example packages/api/.env
# Then edit .env files with your Supabase, JWT, and GCP credentials

# 4. Initialize database
pnpm db:generate       # Generate Prisma client
pnpm db:push           # Push schema to PostgreSQL

# 5. Start development
pnpm dev
```

### Services

| Service | URL | Description |
|---|---|---|
| Web App | `http://localhost:3000` | Landing page (company profile) |
| Admin Dashboard | `http://localhost:3000/admin` | Admin panel (login required) |
| API | `http://localhost:3001` | Express REST API |
| Prisma Studio | `pnpm db:studio` | Database management UI |
| PostgreSQL | `localhost:5432` | Primary database |
| Redis | `localhost:6379` | Queue broker & cache |

---

## Project Structure

### API (`packages/api`)

```
src/
├── routes/          # Route handlers (health, auth, tenants, invites,
│                    #   receipts, expenses, categories, budgets, dashboard,
│                    #   exports, admin)
├── middleware/      # auth (JWT + RBAC), validate (Zod), errorHandler
├── services/       # email, OCR, export, blockchain
├── lib/            # queue (BullMQ), worker, supabase client
└── index.ts        # Express entry point
```

### Web (`apps/web`)

```
src/
├── app/
│   ├── page.tsx              # Landing page (company profile + download buttons)
│   └── admin/                # Admin dashboard (login, overview, users, tenants, receipts)
├── components/     # ui/card, api client
├── lib/            # api client, supabase client, utils
└── middleware.ts   # Route protection (only /admin/* guarded)
```

### Mobile (`apps/mobile`)

```
lib/
├── config/         # API config, theme
├── models/         # User, Receipt, Expense, Budget, Dashboard models
├── services/       # API client (Dio), auth service
├── providers/      # AuthProvider, DashboardProvider (Provider pattern)
├── screens/        # Login, Register, Dashboard, Expenses, Budgets, Upload Receipt
├── widgets/        # LoadingOverlay, ErrorView, EmptyState, StatusBadge
└── main.dart       # App entry with MultiProvider
```

### Database (`packages/db`)

```
prisma/
└── schema.prisma   # 15 models: Tenant, User, TenantMember, Invite, Receipt,
                    #   ReceiptData, ExpenseCategory, Expense, Budget, BudgetAlert,
                    #   ApiKey, Webhook, WebhookDelivery, AuditLog, ExportJob
src/
├── index.ts        # Singleton Prisma client
└── seed.ts         # Development seed data
```

---

## API Overview

All endpoints return a standard envelope:

```typescript
// Success
{ "success": true, "data": { ... }, "meta": { "page": 1, "limit": 20, "total": 42, "totalPages": 3 } }

// Error
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }
```

| Route | Auth | Description |
|---|---|---|
| `GET /api/v1/health` | — | Health check (DB, Redis, storage) |
| `POST /api/v1/auth/register` | — | Register + create tenant |
| `POST /api/v1/auth/login` | — | Login with email/password |
| `GET/POST /api/v1/tenants` | JWT | Tenant management |
| `GET/POST /api/v1/receipts` | JWT | Receipt CRUD + OCR upload |
| `GET/POST /api/v1/expenses` | JWT | Expense CRUD |
| `GET/POST /api/v1/budgets` | JWT+RBAC | Budget management |
| `GET /api/v1/dashboard/overview` | JWT | Aggregated stats |
| `GET/POST /api/v1/exports` | JWT | PDF/Excel export jobs |
| `GET /api/v1/admin/stats` | JWT+Admin | Platform-wide statistics |
| `GET /api/v1/admin/users` | JWT+Admin | All platform users |
| `GET /api/v1/admin/tenants` | JWT+Admin | All platform tenants |
| `GET /api/v1/admin/receipts` | JWT+Admin | All platform receipts |
| `GET /api/v1/admin/users/:id` | JWT+Admin | User detail |
| `GET /api/v1/admin/receipts/:id` | JWT+Admin | Receipt detail |

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anonymous key |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Supabase admin key |
| `REDIS_URL` | ✅ | Redis connection for BullMQ |
| `JWT_SECRET` | ✅ | Token signing secret (>=32 chars) |
| `GOOGLE_APPLICATION_CREDENTIALS` | ⚠️ | GCP service account path (OCR) |
| `RESEND_API_KEY` | ⚠️ | Email delivery (invites, alerts) |
| `NEXT_PUBLIC_API_URL` | ✅ | API base URL for frontend |
| `BLOCKCHAIN_CONTRACT_ADDRESS` | ⚠️ | Smart contract address (optional) |
| `BLOCKCHAIN_RPC_URL` | ⚠️ | Sepolia Ethereum RPC endpoint |

---

## Commands

| Command | Description |
|---|---|
| `pnpm dev` | Start all dev servers (API :3001 + Web :3000) |
| `pnpm build` | Production build all packages |
| `pnpm lint` | ESLint across all packages |
| `pnpm typecheck` | `tsc --noEmit` across all packages |
| `pnpm test` | Run vitest test suites |
| `pnpm db:generate` | Regenerate Prisma client |
| `pnpm db:push` | Push Prisma schema to database |
| `pnpm db:migrate` | Run Prisma migrations |
| `pnpm db:seed` | Seed development data |
| `pnpm db:studio` | Open Prisma Studio |
| `pnpm docker:up` | Start Postgres + Redis |
| `pnpm docker:down` | Stop containers |

---

## Key Features

- **AI-Powered OCR** — Dual pipeline: Tesseract.js (local, free) + Google Cloud Vision (cloud, accurate). Automatic merchant, date, amount, and tax extraction.
- **Multi-Tenant RBAC** — Isolated tenant data with role-based access control (Admin, Finance, Viewer). Invite system with email notifications.
- **Real-Time Budget Monitoring** — Configurable budget periods (monthly/quarterly/yearly) with percentage-based alert thresholds and multi-channel notifications.
- **Tax-Compliant Reporting** — PPN/PPh categorization, tax-deductible flagging, and export-ready financial reports in PDF and Excel formats.
- **Audit Trail** — All mutations logged with `AuditLog` including actor, action, entity, changes diff, and IP address.
- **Admin Dashboard** — Platform-wide overview with user/tenant/receipt management, search and pagination.
- **Blockchain Verification** — Optional receipt hash anchoring on Sepolia Ethereum for tamper-proof audit trail.

---

## Related

- [Admin Guide](./README.md) — Access admin dashboard at `/admin` (requires ADMIN role)

---

<div align="center">
  <sub>Built with TypeScript, Next.js, Express, Prisma, Flutter, and ❤️</sub>
</div>
