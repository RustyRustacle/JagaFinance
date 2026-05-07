-- ============================================================
-- VAULTLEDGER DATABASE SCHEMA (Prisma + PostgreSQL + Supabase)
-- ============================================================
-- Multi-tenant SaaS with Row-Level Security (RLS)
-- Supports: Auth, RBAC, Receipts, OCR, Expenses, Budgets, 
--           Reports, API Keys, Webhooks, Audit Logs
-- ============================================================

-- ======================
-- ENUM TYPES
-- ======================

CREATE TYPE "Role" AS ENUM ('ADMIN', 'FINANCE', 'VIEWER');
CREATE TYPE "InviteStatus" AS ENUM ('PENDING', 'ACCEPTED', 'EXPIRED', 'DECLINED');
CREATE TYPE "ReceiptStatus" AS ENUM ('UPLOADED', 'PROCESSING', 'COMPLETED', 'FAILED', 'REJECTED');
CREATE TYPE "ExpenseStatus" AS ENUM ('DRAFT', 'CONFIRMED', 'RECONCILED', 'VOID');
CREATE TYPE "BudgetPeriod" AS ENUM ('MONTHLY', 'QUARTERLY', 'YEARLY');
CREATE TYPE "AlertChannel" AS ENUM ('EMAIL', 'WEBHOOK', 'IN_APP');
CREATE TYPE "WebhookEvent" AS ENUM ('RECEIPT_UPLOADED', 'RECEIPT_PROCESSED', 'BUDGET_EXCEEDED', 'EXPENSE_CREATED');
CREATE TYPE "AuditAction" AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'INVITE_SEND', 'INVITE_ACCEPT', 'EXPORT');

-- ======================
-- CORE TABLES
-- ======================

CREATE TABLE "tenants" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "name" VARCHAR(255) NOT NULL,
  "slug" VARCHAR(50) UNIQUE NOT NULL,
  "industry" VARCHAR(100),
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "fiscal_year_start" VARCHAR(5) NOT NULL DEFAULT '01-01',
  "timezone" VARCHAR(50) NOT NULL DEFAULT 'Asia/Jakarta',
  "language" VARCHAR(5) NOT NULL DEFAULT 'id',
  "plan" VARCHAR(20) NOT NULL DEFAULT 'FREE',
  "settings" JSONB NOT NULL DEFAULT '{}',
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

CREATE TABLE "users" (
  "id" UUID PRIMARY KEY,  -- Matches Supabase Auth UID
  "email" VARCHAR(255) NOT NULL,
  "name" VARCHAR(255),
  "avatar_url" TEXT,
  "phone" VARCHAR(20),
  "locale" VARCHAR(5) NOT NULL DEFAULT 'id',
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

CREATE TABLE "tenant_members" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "role" "Role" NOT NULL DEFAULT 'VIEWER',
  "status" "InviteStatus" NOT NULL DEFAULT 'PENDING',
  "invited_by" UUID REFERENCES "users"("id"),
  "invited_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "accepted_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  UNIQUE("tenant_id", "user_id")
);

CREATE TABLE "invites" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "email" VARCHAR(255) NOT NULL,
  "role" "Role" NOT NULL DEFAULT 'VIEWER',
  "token" VARCHAR(255) UNIQUE NOT NULL,
  "status" "InviteStatus" NOT NULL DEFAULT 'PENDING',
  "expires_at" TIMESTAMP(3) NOT NULL DEFAULT (now() + interval '7 days'),
  "created_by" UUID REFERENCES "users"("id"),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "accepted_at" TIMESTAMP(3)
);

-- ======================
-- RECEIPT & OCR
-- ======================

CREATE TABLE "receipts" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "uploaded_by" UUID NOT NULL REFERENCES "users"("id"),
  "file_url" TEXT NOT NULL,
  "file_name" VARCHAR(500) NOT NULL,
  "file_type" VARCHAR(50) NOT NULL,
  "file_size" INTEGER NOT NULL,
  "status" "ReceiptStatus" NOT NULL DEFAULT 'UPLOADED',
  "ocr_provider" VARCHAR(50) DEFAULT 'google_vision',
  "ocr_confidence" DECIMAL(5,2),
  "ocr_raw_response" JSONB,
  "error_message" TEXT,
  "processed_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

CREATE TABLE "receipt_data" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "receipt_id" UUID NOT NULL REFERENCES "receipts"("id") ON DELETE CASCADE,
  
  -- Merchant/Vendor info
  "merchant_name" VARCHAR(255),
  "merchant_address" TEXT,
  "merchant_phone" VARCHAR(20),
  "tax_id" VARCHAR(50),  -- NPWP
  
  -- Transaction info
  "receipt_number" VARCHAR(100),
  "transaction_date" TIMESTAMP(3),
  "subtotal" DECIMAL(15,2),
  "tax_amount" DECIMAL(15,2),
  "tax_rate" DECIMAL(5,2),  -- PPN percentage
  "discount_amount" DECIMAL(15,2),
  "total_amount" DECIMAL(15,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "payment_method" VARCHAR(50),  -- cash, card, transfer, etc.
  
  -- Line items
  "line_items" JSONB,  -- Array of {description, quantity, unit_price, amount}
  
  -- Validation
  "is_verified" BOOLEAN NOT NULL DEFAULT false,
  "verified_by" UUID REFERENCES "users"("id"),
  "verification_notes" TEXT,
  
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

-- ======================
-- EXPENSES & CATEGORIES
-- ======================

CREATE TABLE "expense_categories" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "name" VARCHAR(100) NOT NULL,
  "name_en" VARCHAR(100),  -- English translation
  "color" VARCHAR(7) NOT NULL DEFAULT '#6B7280',
  "icon" VARCHAR(50),
  "parent_id" UUID REFERENCES "expense_categories"("id"),  -- For sub-categories
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  UNIQUE("tenant_id", "name")
);

CREATE TABLE "expenses" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "receipt_id" UUID REFERENCES "receipts"("id") ON DELETE SET NULL,
  "category_id" UUID NOT NULL REFERENCES "expense_categories"("id"),
  "created_by" UUID NOT NULL REFERENCES "users"("id"),
  
  "title" VARCHAR(255) NOT NULL,
  "description" TEXT,
  "amount" DECIMAL(15,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "expense_date" TIMESTAMP(3) NOT NULL,
  "payment_method" VARCHAR(50),
  "status" "ExpenseStatus" NOT NULL DEFAULT 'DRAFT',
  
  -- Accounting fields
  "journal_entry_id" VARCHAR(100),  -- For export to accounting software
  "cost_center" VARCHAR(100),
  "project_code" VARCHAR(100),
  "tax_deductible" BOOLEAN NOT NULL DEFAULT false,
  
  "tags" VARCHAR(50)[],
  "metadata" JSONB NOT NULL DEFAULT '{}',
  
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

-- ======================
-- BUDGETS & ALERTS
-- ======================

CREATE TABLE "budgets" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "category_id" UUID NOT NULL REFERENCES "expense_categories"("id"),
  
  "amount" DECIMAL(15,2) NOT NULL,
  "currency" VARCHAR(3) NOT NULL DEFAULT 'IDR',
  "period" "BudgetPeriod" NOT NULL DEFAULT 'MONTHLY',
  "start_date" TIMESTAMP(3) NOT NULL,
  "end_date" TIMESTAMP(3) NOT NULL,
  
  "alert_threshold" DECIMAL(5,2) NOT NULL DEFAULT 80.00,  -- Percentage
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  UNIQUE("tenant_id", "category_id", "start_date", "end_date", "period")
);

CREATE TABLE "budget_alerts" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "budget_id" UUID NOT NULL REFERENCES "budgets"("id") ON DELETE CASCADE,
  
  "triggered_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "current_amount" DECIMAL(15,2) NOT NULL,
  "budget_amount" DECIMAL(15,2) NOT NULL,
  "percentage_used" DECIMAL(5,2) NOT NULL,
  "channel" "AlertChannel" NOT NULL DEFAULT 'EMAIL',
  "recipient_email" VARCHAR(255) NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'SENT',  -- SENT, FAILED, PENDING
  "error_message" TEXT,
  
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

-- ======================
-- API KEYS & WEBHOOKS
-- ======================

CREATE TABLE "api_keys" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "name" VARCHAR(100) NOT NULL,
  "key_hash" VARCHAR(255) NOT NULL,  -- bcrypt hashed
  "key_prefix" VARCHAR(10) NOT NULL,  -- For display: vl_xxx_...
  "permissions" VARCHAR(50)[] NOT NULL DEFAULT '{}',  -- ['receipts:read', 'expenses:write']
  "last_used_at" TIMESTAMP(3),
  "expires_at" TIMESTAMP(3),
  "revoked_at" TIMESTAMP(3),
  "revoked_by" UUID REFERENCES "users"("id"),
  "created_by" UUID NOT NULL REFERENCES "users"("id"),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

CREATE TABLE "webhooks" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "url" TEXT NOT NULL,
  "secret" VARCHAR(255) NOT NULL,  -- For HMAC signature
  "events" "WebhookEvent"[] NOT NULL DEFAULT '{}',
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "created_by" UUID NOT NULL REFERENCES "users"("id"),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

CREATE TABLE "webhook_deliveries" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "webhook_id" UUID NOT NULL REFERENCES "webhooks"("id") ON DELETE CASCADE,
  "event_type" "WebhookEvent" NOT NULL,
  "payload" JSONB NOT NULL,
  "status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, SUCCESS, FAILED
  "response_code" INTEGER,
  "response_body" TEXT,
  "attempt" INTEGER NOT NULL DEFAULT 1,
  "max_attempts" INTEGER NOT NULL DEFAULT 3,
  "next_retry_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

-- ======================
-- AUDIT LOGS
-- ======================

CREATE TABLE "audit_logs" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "user_id" UUID REFERENCES "users"("id"),
  "action" "AuditAction" NOT NULL,
  "entity_type" VARCHAR(50) NOT NULL,  -- 'receipt', 'expense', 'user', etc.
  "entity_id" UUID,
  "changes" JSONB,  -- {before: {}, after: {}}
  "ip_address" VARCHAR(45),
  "user_agent" TEXT,
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now()
);

-- ======================
-- EXPORT LOGS
-- ======================

CREATE TABLE "export_jobs" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id" UUID NOT NULL REFERENCES "tenants"("id") ON DELETE CASCADE,
  "requested_by" UUID NOT NULL REFERENCES "users"("id"),
  "format" VARCHAR(10) NOT NULL,  -- 'CSV', 'XLSX', 'PDF'
  "export_type" VARCHAR(50) NOT NULL,  -- 'expenses', 'receipts', 'budget_report'
  "filters" JSONB NOT NULL DEFAULT '{}',
  "file_url" TEXT,
  "status" VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- PENDING, PROCESSING, COMPLETED, FAILED
  "error_message" TEXT,
  "expires_at" TIMESTAMP(3),
  "created_at" TIMESTAMP(3) NOT NULL DEFAULT now(),
  "completed_at" TIMESTAMP(3)
);

-- ======================
-- INDEXES
-- ======================

CREATE INDEX idx_tenant_members_tenant_id ON "tenant_members"("tenant_id");
CREATE INDEX idx_tenant_members_user_id ON "tenant_members"("user_id");
CREATE INDEX idx_tenant_members_role ON "tenant_members"("tenant_id", "role");
CREATE INDEX idx_receipts_tenant_id ON "receipts"("tenant_id");
CREATE INDEX idx_receipts_status ON "receipts"("tenant_id", "status");
CREATE INDEX idx_receipts_created_at ON "receipts"("tenant_id", "created_at" DESC);
CREATE INDEX idx_receipt_data_receipt_id ON "receipt_data"("receipt_id");
CREATE INDEX idx_expenses_tenant_id ON "expenses"("tenant_id");
CREATE INDEX idx_expenses_category ON "expenses"("tenant_id", "category_id");
CREATE INDEX idx_expenses_date ON "expenses"("tenant_id", "expense_date" DESC);
CREATE INDEX idx_expenses_status ON "expenses"("tenant_id", "status");
CREATE INDEX idx_expenses_created_by ON "expenses"("tenant_id", "created_by");
CREATE INDEX idx_budgets_tenant_id ON "budgets"("tenant_id");
CREATE INDEX idx_budgets_category ON "budgets"("tenant_id", "category_id");
CREATE INDEX idx_budget_alerts_budget ON "budget_alerts"("budget_id");
CREATE INDEX idx_audit_logs_tenant_id ON "audit_logs"("tenant_id");
CREATE INDEX idx_audit_logs_created_at ON "audit_logs"("tenant_id", "created_at" DESC);
CREATE INDEX idx_export_jobs_tenant_id ON "export_jobs"("tenant_id");
CREATE INDEX idx_webhooks_tenant_id ON "webhooks"("tenant_id");
CREATE INDEX idx_api_keys_tenant_id ON "api_keys"("tenant_id");

-- ======================
-- ROW-LEVEL SECURITY (RLS)
-- ============================
-- Enable RLS on all tenant-scoped tables

ALTER TABLE "tenants" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "tenant_members" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "receipts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "receipt_data" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "expense_categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "expenses" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "budgets" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "budget_alerts" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "api_keys" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "webhooks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "webhook_deliveries" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "audit_logs" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "export_jobs" ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access data from their tenant

-- Tenants: Users can see tenants they are members of
CREATE POLICY "tenant_members_can_view" ON "tenants"
  FOR SELECT USING (
    id IN (SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED')
  );

-- Tenant members: Can view members of their own tenant
CREATE POLICY "view_own_tenant_members" ON "tenant_members"
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED')
  );

CREATE POLICY "admin_manage_tenant_members" ON "tenant_members"
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role = 'ADMIN' AND status = 'ACCEPTED'
    )
  );

-- Receipts: Members of tenant can view, Finance+ can create/edit
CREATE POLICY "view_tenant_receipts" ON "receipts"
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED')
  );

CREATE POLICY "finance_create_receipts" ON "receipts"
  FOR INSERT WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
    )
  );

CREATE POLICY "finance_update_receipts" ON "receipts"
  FOR UPDATE USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
    )
  );

CREATE POLICY "admin_delete_receipts" ON "receipts"
  FOR DELETE USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role = 'ADMIN' AND status = 'ACCEPTED'
    )
  );

-- Receipt data: Same as receipts
CREATE POLICY "view_receipt_data" ON "receipt_data"
  FOR SELECT USING (
    receipt_id IN (
      SELECT r.id FROM "receipts" r
      WHERE r.tenant_id IN (
        SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED'
      )
    )
  );

CREATE POLICY "finance_manage_receipt_data" ON "receipt_data"
  FOR ALL USING (
    receipt_id IN (
      SELECT r.id FROM "receipts" r
      WHERE r.tenant_id IN (
        SELECT tenant_id FROM "tenant_members" 
        WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
      )
    )
  );

-- Expenses: Members view, Finance+ manage
CREATE POLICY "view_tenant_expenses" ON "expenses"
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED')
  );

CREATE POLICY "finance_create_expenses" ON "expenses"
  FOR INSERT WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
    )
  );

CREATE POLICY "finance_update_expenses" ON "expenses"
  FOR UPDATE USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
    )
  );

CREATE POLICY "admin_delete_expenses" ON "expenses"
  FOR DELETE USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role = 'ADMIN' AND status = 'ACCEPTED'
    )
  );

-- Budgets: Finance+ manage, all view
CREATE POLICY "view_tenant_budgets" ON "budgets"
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED')
  );

CREATE POLICY "finance_manage_budgets" ON "budgets"
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
    )
  );

-- Categories: All members view, Finance+ manage
CREATE POLICY "view_categories" ON "expense_categories"
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM "tenant_members" WHERE user_id = auth.uid() AND status = 'ACCEPTED')
  );

CREATE POLICY "finance_manage_categories" ON "expense_categories"
  FOR ALL USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role IN ('ADMIN', 'FINANCE') AND status = 'ACCEPTED'
    )
  );

-- Audit logs: Only Admin can view
CREATE POLICY "admin_view_audit_logs" ON "audit_logs"
  FOR SELECT USING (
    tenant_id IN (
      SELECT tenant_id FROM "tenant_members" 
      WHERE user_id = auth.uid() AND role = 'ADMIN' AND status = 'ACCEPTED'
    )
  );

-- ======================
-- TRIGGERS
-- ======================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON "tenants"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON "users"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenant_members_updated_at BEFORE UPDATE ON "tenant_members"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON "receipts"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_receipt_data_updated_at BEFORE UPDATE ON "receipt_data"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_expenses_updated_at BEFORE UPDATE ON "expenses"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_expense_categories_updated_at BEFORE UPDATE ON "expense_categories"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_budgets_updated_at BEFORE UPDATE ON "budgets"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_api_keys_updated_at BEFORE UPDATE ON "api_keys"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_webhooks_updated_at BEFORE UPDATE ON "webhooks"
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-create user profile when Supabase user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO "users" ("id", "email", "name")
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
