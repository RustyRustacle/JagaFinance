# JagaFinance

> **B2B Receipt & Expense Intelligence Platform** — Digitize physical receipts into auditable financial reports in seconds.

JagaFinance is a production-grade monorepo that combines AI-powered OCR, real-time expense tracking, multi-tenant budget management, and export-ready financial reporting — purpose-built for Indonesian B2B workflows with full PPN/PPh tax compliance.

---

## Architecture

```
jagafinance/
├── apps/
│   ├── web/                    # Next.js 14 (App Router, i18n, PWA)
│   └── mobile/                 # Flutter (scaffold)
├── packages/
│   ├── api/                    # Express 4 REST API (OCR, queues, export)
│   └── db/                     # Prisma 5 schema + client (PostgreSQL 16)
├── supabase/
│   └── migrations/             # Auth, RLS, storage buckets
├── credentials/                # GCP service account (gitignored)
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
| **Web** | Next.js 14 (App Router) | SSR, PWA, i18n, dashboard UI |
| **API** | Express 4 | RESTful endpoints, file upload, auth |
| **Language** | TypeScript 5.5 | Strict typing across 100% of codebase |
| **ORM** | Prisma 5 | Type-safe DB access, migrations |
| **Database** | PostgreSQL 16 (Supabase) | Multi-tenant with RLS |
| **Cache & Queues** | Redis 7 + BullMQ | OCR jobs, budget alerts, exports |
| **Auth** | Supabase Auth + JWT | SSR session + Bearer token |
| **OCR** | Tesseract.js + Google Cloud Vision | Local + Cloud OCR pipeline |
| **Email** | Resend | Transactional notifications |
| **Reporting** | PDFKit, ExcelJS | Financial report generation |
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

# 5. (Optional) Seed sample data
pnpm --filter=@jagafinance/db seed

# 6. Start development
pnpm dev
```

### Services

| Service | URL | Description |
|---|---|---|
| Web App | `http://localhost:3000` | Next.js frontend |
| API | `http://localhost:3001` | Express REST API |
| Prisma Studio | `pnpm db:studio` | Database management UI |
| PostgreSQL | `localhost:5432` | Primary database |
| Redis | `localhost:6379` | Queue broker & cache |

---

## Project Structure

### API (`packages/api`)

```
src/
├── routes/          # 10 route handlers (health, auth, tenants, invites,
│                    #   receipts, expenses, categories, budgets, dashboard, exports)
├── middleware/      # auth (JWT + RBAC), validate (Zod), errorHandler
├── services/       # email, OCR, export
├── lib/            # queue (BullMQ), worker, supabase client
└── index.ts        # Express entry point
```

### Web (`apps/web`)

```
src/
├── app/
│   ├── (auth)/     # Login, Register (route group)
│   └── (dashboard)/ # Dashboard, Receipts, Expenses, Budgets, Settings
├── components/     # sidebar, header, receipt-upload, ui/card
├── lib/            # api client, supabase client, utils
└── stores/         # Zustand auth store
```

### Database (`packages/db`)

```
prisma/
└── schema.prisma   # 12 models: Tenant, User, TenantMember, Invite, Receipt,
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

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anonymous key |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Supabase admin key |
| `REDIS_URL` | ✅ | Redis connection for BullMQ |
| `JWT_SECRET` | ✅ | Token signing secret (≥32 chars) |
| `GOOGLE_APPLICATION_CREDENTIALS` | ⚠️ | GCP service account path (OCR) |
| `RESEND_API_KEY` | ⚠️ | Email delivery (invites, alerts) |
| `NEXT_PUBLIC_API_URL` | ✅ | API base URL for frontend |

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
| `pnpm db:push` | Push Prisma schema → database |
| `pnpm db:migrate` | Run Prisma migrations |
| `pnpm db:seed` | Seed development data |
| `pnpm db:studio` | Open Prisma Studio |
| `pnpm docker:up` | Start Postgres + Redis |
| `pnpm docker:down` | Stop containers |
| `pnpm docker:reset` | Wipe volumes + restart |

---

## Key Features

- **AI-Powered OCR** — Dual pipeline: Tesseract.js (local, free) + Google Cloud Vision (cloud, accurate). Automatic merchant, date, amount, and tax extraction.
- **Multi-Tenant RBAC** — Isolated tenant data with role-based access control (Admin, Finance, Viewer). Invite system with email notifications.
- **Real-Time Budget Monitoring** — Configurable budget periods (monthly/quarterly/yearly) with percentage-based alert thresholds and multi-channel notifications.
- **Tax-Compliant Reporting** — PPN/PPh categorization, tax-deductible flagging, and export-ready financial reports in PDF and Excel formats.
- **Audit Trail** — All mutations logged with `AuditLog` including actor, action, entity, changes diff, and IP address.

---

## Related

- [Supabase Setup](./SUPABASE_SETUP.md) — Detailed Supabase project configuration and migration guide
- [Docker Setup](https://docs.docker.com/desktop/) — Install Docker Desktop for local infrastructure

---

<div align="center">
  <sub>Built with TypeScript, Next.js, Express, Prisma, and ❤️</sub>
</div>
