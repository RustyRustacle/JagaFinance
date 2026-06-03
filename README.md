# JagaFinance

> **B2B Receipt & Expense Intelligence Platform** — Digitize physical receipts into auditable financial reports in seconds.

JagaFinance adalah platform manajemen receipt & expense multi-tenant dengan AI-powered OCR, real-time budget monitoring, dan export-ready financial reporting — khusus untuk workflow B2B Indonesia dengan kepatuhan PPN/PPh.

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
| **Database** | PostgreSQL 16 | Multi-tenant with RLS (Railway) |
| **Cache & Queues** | Redis 7 + BullMQ | OCR jobs, budget alerts, exports |
| **Auth** | Supabase Auth + JWT | SSR session + Bearer token |
| **OCR** | Tesseract.js + Google Cloud Vision | Local + Cloud OCR pipeline |
| **Email** | Resend | Transactional notifications |
| **Blockchain** | Hardhat + Solidity | Receipt hash verification on Sepolia |
| **Styling** | Tailwind CSS + CVA | Utility-first design system |
| **Hosting** | Railway (Docker) | Production API deployment |

---

## Deployments

| Environment | URL | Status |
|---|---|---|
| **Production API** | `https://jagafinance-production.up.railway.app/api/v1` | ✅ Active |
| **Health Check** | `https://jagafinance-production.up.railway.app/api/v1/health` | ✅ Passing |

API dideploy otomatis via Railway (auto-deploy dari `main` branch). Setiap push ke `main` akan trigger build & deploy ulang.

---

## Getting Started

### Prerequisites

```bash
node -v          # >= 20
pnpm -v          # 9.x (install: npm install -g pnpm@9)
docker info      # Docker Desktop running (untuk local dev)
```

### Quick Start (Local Development)

```bash
# 1. Clone & install
git clone https://github.com/RustyRustacle/JagaFinance.git
cd JagaFinance
pnpm install

# 2. Start Postgres + Redis
pnpm docker:up

# 3. Configure environment
cp .env.example .env
cp packages/api/.env.example packages/api/.env
# Edit .env files with your credentials

# 4. Initialize database
pnpm db:generate       # Generate Prisma client
pnpm db:push           # Push schema to PostgreSQL

# 5. Start development
pnpm dev
```

### Mobile App

```bash
cd apps/mobile
flutter run
```

Mobile app sudah otomatis pointing ke production API (`jagafinance-production.up.railway.app`).

---

## API Overview

All endpoints return standard envelope:

```typescript
// Success
{ "success": true, "data": { ... }, "meta": { "page": 1, "limit": 20, "total": 42, "totalPages": 3 } }

// Error
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "...", "details": [...] } }
```

| Route | Auth | Description |
|---|---|---|
| `GET /api/v1/health` | — | Health check |
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

---

## Environment Variables

### Local Development (`.env`)

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anonymous key |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Supabase admin key |
| `REDIS_URL` | ✅ | Redis connection for BullMQ |
| `JWT_SECRET` | ✅ | Token signing secret (>=32 chars) |
| `GOOGLE_APPLICATION_CREDENTIALS` | ⚠️ | GCP service account file path |
| `RESEND_API_KEY` | ⚠️ | Email delivery (invites, alerts) |

### Railway (Production)

Variable `DATABASE_URL` dan `REDIS_URL` diisi otomatis oleh Railway PostgreSQL & Redis plugin. Variable lain diatur via dashboard Railway.

---

## Commands

| Command | Description |
|---|---|
| `pnpm dev` | Start all dev servers (API :3001 + Web :3000) |
| `pnpm build` | Production build all packages |
| `pnpm test` | Run vitest test suites |
| `pnpm db:generate` | Regenerate Prisma client |
| `pnpm db:push` | Push Prisma schema to database |
| `pnpm docker:up` | Start Postgres + Redis |
| `pnpm docker:down` | Stop containers |

---

## Key Features

- **AI-Powered OCR** — Dual pipeline: Tesseract.js (local, free) + Google Cloud Vision (cloud, accurate)
- **Multi-Tenant RBAC** — Isolated tenant data with role-based access control
- **Real-Time Budget Monitoring** — Configurable periods with alert thresholds
- **Tax-Compliant Reporting** — PPN/PPh categorization, PDF/Excel exports
- **Audit Trail** — All mutations logged with actor, action, entity, changes
- **Blockchain Verification** — Optional receipt hash anchoring on Sepolia

---

<div align="center">
  <sub>Built with TypeScript, Next.js, Express, Prisma, Flutter, and ❤️</sub>
</div>
