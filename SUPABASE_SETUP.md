# Supabase Setup Guide

## 1. Create Project

1. Go to [supabase.com](https://supabase.com)
2. Sign in → New Project
3. Project name: `vaultledger`
4. Database password: (save this securely)
5. Region: `Southeast Asia (Singapore)` (closest to Indonesia)
6. Wait for provisioning (~2 minutes)

## 2. Get Credentials

From Project Settings → API:
- `Project URL`: `https://xxxx.supabase.co`
- `anon public key`: `eyJ...`
- `service_role key`: `eyJ...` (keep secret!)

## 3. Run Migrations

```bash
# Option A: Using Supabase CLI
npx supabase link --project-ref your-project-ref
npx supabase db push

# Option B: Using Dashboard
# Go to SQL Editor → paste each migration file content:
#   supabase/migrations/001_core_schema.sql
#   supabase/migrations/002_receipts_expenses_budgets.sql
#   supabase/migrations/003_audit_webhooks_exports.sql
#   supabase/migrations/004_storage_buckets.sql
# Run them in order
```

## 4. Configure Auth

Go to Authentication → Providers:
- Enable **Email** provider
- Disable "Confirm email" for faster testing (or enable for production)
- Set Password requirements: min 8 chars

## 5. Configure Storage

Go to Storage → buckets:
- The `receipts` bucket is created automatically by migration 004
- Verify it has RLS enabled (it should)

## 6. Update Environment Files

### `apps/web/.env.local`
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
NEXT_PUBLIC_API_URL=http://localhost:3001/api/v1
```

### `packages/api/.env`
```
PORT=3001
DATABASE_URL="postgresql://postgres.xxxx:password@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres?schema=public&sslmode=require"
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_SERVICE_ROLE_KEY="eyJhbGci..."
REDIS_URL="redis://localhost:6379"
JWT_SECRET="your-jwt-secret-change-in-production"
GOOGLE_APPLICATION_CREDENTIALS="./gcp-credentials.json"
```

## 7. Push Prisma Schema

```bash
cd packages/db
npx prisma db pull   # Pull existing schema from Supabase
npx prisma generate  # Generate Prisma Client
```

## 8. Seed Database

```bash
# After Supabase is connected:
pnpm db:generate
pnpm db:push         # Push schema (if not using migrations)
```

## Database URL Format

For Supabase:
```
postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres?schema=public&sslmode=require
```

Find this in: Project Settings → Database → Connection string → URI
