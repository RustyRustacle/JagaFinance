# Setup Database — Supabase SQL Migrations

## Cara Apply Semua Migration

### 1. Buka Supabase Dashboard
https://supabase.com/dashboard/project/fetuyfzskampvbsdyjlf

### 2. Masuk ke SQL Editor
Sidebar kiri → **SQL Editor** → **New Query**

### 3. Jalankan Migration Berurutan

Jalankan satu per satu sesuai urutan:

| Urutan | File | Fungsi |
|--------|------|--------|
| 1 | `supabase/migrations/001_core_schema.sql` | Schema inti: tenant, user, RBAC |
| 2 | `supabase/migrations/002_receipts_expenses_budgets.sql` | Tabel receipt, expense, budget |
| 3 | `supabase/migrations/003_audit_webhooks_exports.sql` | Audit log, webhook, export |
| 4 | `supabase/migrations/004_storage_buckets.sql` | Storage bucket **receipts** + RLS per tenant |
| 5 | `supabase/migrations/005_exports_bucket.sql` | Storage bucket **exports** + RLS per tenant |
| 6 | `supabase/migrations/006_add_finalized_blockchain.sql` | Enum FINALIZED + kolom blockchain |

**Cara:**
- Buka file `.sql` di folder `supabase/migrations/`
- Copy seluruh isi
- Paste ke SQL Editor
- Klik **Run** atau `Ctrl + Enter`
- Tunggu selesai, lanjut file berikutnya

### 4. Verifikasi

Buka **Sidebar → Database → Tables**. Cek tabel sudah muncul:
- `tenants`, `users`, `tenant_members`
- `receipts`, `receipt_data`, `expenses`, `budgets`
- `audit_logs`, `export_jobs`, `webhooks`, `api_keys`

Buka **Sidebar → Storage → receipts** → cek **Policies** tab. Pasti ada 3 policy:
- `receipts_upload_tenant`
- `receipts_view_tenant`
- `receipts_delete_admin`

### Catatan Penting

- Migration **006** mengubah enum `receipt_status` — pastikan migration 001-003 sudah jalan dulu
- Kolom `blockchain_network` default ke `'sepolia'` (Ethereum Sepolia)
- Semua storage bucket **private** — cuma user yang punya akses tenant bisa lihat/upload
- Worker API pake `SERVICE_ROLE_KEY` yang *bypass* RLS, jadi upload/download tetap jalan
