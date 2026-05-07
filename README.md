# VaultLedger

**B2B Receipt & Expense Intelligence Platform**

A full-stack monorepo for automated receipt processing, expense tracking, and financial intelligence — purpose-built for B2B workflows.

## Architecture

```
vaultledger/
├── apps/
│   └── web/          # Next.js 14 frontend (App Router, i18n, PWA)
├── packages/
│   ├── api/          # Express REST API (OCR, reporting, queues)
│   └── db/           # Prisma schema & migrations (Postgres)
├── supabase/         # Supabase config & migrations (auth, realtime)
└── docker-compose.yml
```

- **Monorepo** — pnpm workspaces + Turborepo for orchestrated builds, linting, and type-checking across all packages.
- **Frontend** — Next.js 14 with `next-intl` i18n, `zustand` state, `recharts` dashboards, and Tailwind CSS.
- **API** — Express with Helmet, rate-limiting, Multer file uploads, BullMQ job queues (Redis), and Tesseract.js / Google Cloud Vision OCR.
- **Database** — Prisma ORM on Supabase PostgreSQL with full migration pipeline.
- **Auth** — Supabase Auth (SSR) + JWT verification in the API layer.
- **Infrastructure** — Local Postgres 16 & Redis 7 via Docker Compose.

## Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 20+, pnpm 9 |
| Framework (web) | Next.js 14 (App Router) |
| Framework (api) | Express 4 |
| Language | TypeScript 5.5 |
| ORM | Prisma 5 |
| Database | PostgreSQL 16 (Supabase) |
| Cache / Queues | Redis 7 + BullMQ |
| Auth | Supabase Auth (SSR) |
| OCR | Tesseract.js + Google Cloud Vision |
| Email | Resend |
| Reporting | PDFKit, ExcelJS |
| Styling | Tailwind CSS + class-variance-authority |
| i18n | next-intl |
| Containerization | Docker Compose |

## Getting Started

### Prerequisites

- Node.js >= 20
- pnpm 9 (`npm install -g pnpm@9`)
- Docker Desktop (for local Postgres & Redis)

### Setup

```bash
# 1. Install dependencies
pnpm install

# 2. Start infrastructure
pnpm docker:up

# 3. Copy environment files
cp .env.example .env
cp apps/web/.env.example apps/web/.env
cp packages/api/.env.example packages/api/.env

# 4. Generate Prisma client & push schema
pnpm db:generate
pnpm db:push

# (Optional) Seed sample data
pnpm --filter=@vaultledger/db seed

# 5. Start development
pnpm dev
```

- Web: `http://localhost:3000`
- API: `http://localhost:3001`
- Prisma Studio: `pnpm db:studio`

## Scripts

| Command | Description |
|---------|-------------|
| `pnpm dev` | Start all packages in dev mode |
| `pnpm build` | Build all packages |
| `pnpm lint` | Lint all packages |
| `pnpm typecheck` | Type-check all packages |
| `pnpm test` | Run tests across packages |
| `pnpm db:generate` | Regenerate Prisma client |
| `pnpm db:migrate` | Run Prisma migrations |
| `pnpm db:push` | Push schema to database |
| `pnpm db:studio` | Open Prisma Studio |
| `pnpm docker:up` | Start Postgres & Redis |
| `pnpm docker:down` | Stop containers |
| `pnpm docker:reset` | Reset volumes & restart |

## Environment Variables

Key variables (see `.env.example` for the full list):

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | Supabase project credentials |
| `REDIS_URL` | Redis connection for BullMQ |
| `JWT_SECRET` | Token signing secret |
| `GOOGLE_APPLICATION_CREDENTIALS` | GCP service account for Vision API |
| `RESEND_API_KEY` | Email delivery |

## Related

- [Supabase Setup](./SUPABASE_SETUP.md) — detailed Supabase configuration guide
