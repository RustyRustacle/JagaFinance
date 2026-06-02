# Railway Deployment - API Server

Panduan deploy API JagaFinance ke Railway agar semua contributor bisa pakai OCR tanpa perlu Docker/GCP lokal.

## Prasyarat

- Repository sudah terhubung ke GitHub (RustyRustacle/JagaFinance)
- Railway account (https://railway.app)

## Langkah Deployment

### 1. Hubungkan Repository

Buka Railway dashboard:

- Klik **New Project**
- Pilih **Deploy from GitHub repo**
- Pilih `RustyRustacle/JagaFinance`
- Railway auto-detect **Dockerfile** di `packages/api/Dockerfile`
- Klik **Deploy**

### 2. Add PostgreSQL Plugin

Di dashboard project:

- Klik **Add Plugin**
- Pilih **PostgreSQL**
- Railway akan generate `DATABASE_URL` otomatis

### 3. Add Redis Plugin

- Klik **Add Plugin**
- Pilih **Redis**
- Railway akan generate `REDIS_URL` otomatis

### 4. Atur Environment Variables

Di tab **Variables**, tambahkan:

| Variable | Nilai |
|----------|-------|
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Isi penuh file `profound-jet-436504-q9-24b76d8d8ca9.json` (copy paste semua konten) |
| `SUPABASE_URL` | `https://fetuyfzskampvbsdyjlf.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZldHV5Znpza2FtcHZic2R5amxmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDAzMDc5NSwiZXhwIjoyMDk1NjA2Nzk1fQ.RvVR5J-5BszCU0EWh2ODbk9soHa_pNdhn0dFuXCQ2O0` |
| `SUPABASE_ANON_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZldHV5Znpza2FtcHZic2R5amxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwMzA3OTUsImV4cCI6MjA5NTYwNjc5NX0.y5mI1fasqaAwuOquHYRXX8IobVzcEbWaJOcGDAhzzr4` |
| `FRONTEND_URL` | URL web production (isi nanti) |
| `RESEND_API_KEY` | `re_b5CDYWvx_5wLYaP8dFCo7DgesRAUPJy6Z` |
| `BLOCKCHAIN_CONTRACT_ADDRESS` | `0xf5eded7E428FF0b74BDE1E2Af848816CfA15e813` |
| `BLOCKCHAIN_RPC_URL` | `https://ethereum-sepolia.publicnode.com` |
| `BLOCKCHAIN_CHAIN_ID` | `11155111` |

`DATABASE_URL` dan `REDIS_URL` tidak perlu diisi manual, Railway plugin akan mengisinya otomatis.

### 5. Prisma Migration

Database Railway masih kosong, perlu push schema:

**Via Railway Shell (recommended):**

- Dashboard **Project** -> **Shell**
- Ketik perintah:
```bash
npx prisma db push
```

**Via Railway CLI (alternatif):**

```bash
npm i -g @railway/cli
railway login
railway link
railway run "npx prisma db push"
```

### 6. Domain

- Railway memberi domain `.railway.app` otomatis
- Bisa tambah custom domain di tab **Settings** -> **Domains**
- Contoh: `https://jagafinance-api.up.railway.app`

### 7. Update Mobile App

Update `apps/mobile/lib/config/api_config.dart`:

```dart
static const String baseUrl = 'https://NAMA-PROJECT.up.railway.app';
```

## Cara Kerja OCR di Railway

- `GOOGLE_APPLICATION_CREDENTIALS_JSON` berisi raw JSON dari file GCP service account
- Saat API start, `OCRService` constructor membaca env tersebut dan menulis ke file sementara di `/tmp/gcp-credentials.json`
- Google Cloud Vision membaca dari file tersebut
- Fallback Tesseract.js jalan via `os.tmpdir()` (cross-platform)

## Keuntungan

- Semua contributor cukup pointing ke satu URL
- Tidak perlu Docker Desktop local
- Tidak perlu download Google Cloud credentials
- API jalan 24/7 tanpa perlu komputer nyala
